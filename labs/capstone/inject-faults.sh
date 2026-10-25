#!/usr/bin/env bash
# inject-faults.sh - fault injector for capstone C3 (troubleshooting ticket queue)
#
# Starts from the AVD end state (labs/avd/intended/configs deployed on the
# containerlab fabric "l5dc") and breaks it, one ticket at a time.
#
#   ./inject-faults.sh list          show the tickets (complaints only, no answers)
#   ./inject-faults.sh 3             inject ticket 3
#   ./inject-faults.sh 1 4 7         inject several tickets
#   ./inject-faults.sh all           inject all 10 tickets
#   ./inject-faults.sh random [N]    inject N random tickets (default 3); the numbers are
#                                    saved in .injected so you can grade yourself later
#   ./inject-faults.sh restore       put the six fabric switches back to the AVD intended
#                                    config with "configure replace" (undoes every fault)
#
# Transport (pick one with MODE=...):
#   MODE=docker (default)  docker exec clab-l5dc-<node> Cli -p 15 -c $'configure\n...\nend'
#                          Cli -p 15 starts at privilege 15 (enable), and -c runs each
#                          newline-separated line as one CLI command, in order.
#   MODE=eapi              JSON-RPC runCmds to https://<mgmt-ip>/command-api with curl
#                          (works from any machine that can reach 172.100.100.0/24).
# Other knobs: DOCKER="sudo docker"   LAB=l5dc   EAPI_USER=admin   EAPI_PASS=admin
#
# Faults are made in running-config only. Nothing is saved to startup-config, so
# "show running-config diffs" is a legitimate troubleshooting tool, and a reload of a
# switch also clears its faults.
set -euo pipefail

MODE="${MODE:-docker}"
DOCKER="${DOCKER:-docker}"
LAB="${LAB:-l5dc}"
EAPI_USER="${EAPI_USER:-admin}"
EAPI_PASS="${EAPI_PASS:-admin}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTENDED="${INTENDED:-$HERE/../avd/intended/configs}"

declare -A MGMT=(
  [spine1]=172.100.100.11 [spine2]=172.100.100.12
  [leaf1]=172.100.100.21 [leaf2]=172.100.100.22
  [leaf3]=172.100.100.23 [leaf4]=172.100.100.24
)

# cfg <node> <config lines...>  - apply config lines on one node
cfg() {
  local node="$1"; shift
  local body
  body="$(printf '%s\n' "$@")"
  echo "  -> $node"
  if [[ "$MODE" == "eapi" ]]; then
    local payload out
    payload="$(python3 - "$body" <<'PY'
import json, sys
cmds = ["enable", "configure"] + [l for l in sys.argv[1].splitlines() if l.strip()] + ["end"]
print(json.dumps({"jsonrpc": "2.0", "method": "runCmds", "id": "inject",
                  "params": {"version": 1, "cmds": cmds, "format": "text"}}))
PY
)"
    out="$(curl -sk -u "$EAPI_USER:$EAPI_PASS" -H 'Content-Type: application/json' \
            -d "$payload" "https://${MGMT[$node]}/command-api")"
    if grep -q '"error"' <<<"$out"; then
      echo "     eAPI error on $node: $out" >&2
      return 1
    fi
  else
    # shellcheck disable=SC2086
    $DOCKER exec "clab-${LAB}-${node}" Cli -p 15 -c "$(printf 'configure\n%s\nend' "$body")" >/dev/null
  fi
}

ticket_text() {
  case "$1" in
    1)  echo "T1  Server team: host1 Port-Channel1 shows only one member bundled, and leaf2 monitoring says 'MLAG inactive'." ;;
    2)  echo "T2  NOC: BGP alarm on spine2. One underlay neighbor is not Established. POD_B lost a path." ;;
    3)  echo "T3  DB team: the DB cluster heartbeat between 10.20.20.101 (host1) and 10.20.20.102 (host2) is down, but the app tier in 10.10.10.0/24 can still reach both DB servers." ;;
    4)  echo "T4  Platform team: the L2_STRETCH cluster (VLAN 30) is split. 10.30.30.101 cannot reach 10.30.30.102. Nothing else seems broken." ;;
    5)  echo "T5  App team: host2 can reach host1 inside its own subnet, but nothing off-subnet. Its gateway 10.10.10.1 does not answer from host2. host1 is fine." ;;
    6)  echo "T6  Backup team: nightly backups from host1 to host2 stall. Small pings work. A colleague 'tidied up interface settings' on leaf3 and the spines yesterday." ;;
    7)  echo "T7  Major incident: since last night's change, host1 cannot reach anything on POD_B (10.x.x.102). All BGP and EVPN sessions show Established." ;;
    8)  echo "T8  Compliance audit: leaf3 advertises EVPN type-1 and type-4 routes. POD_B is supposed to be MLAG-only. Remove the drift and explain the risk." ;;
    9)  echo "T9  Monitoring: leaf2 Port-Channel5 / Ethernet5 is err-disabled. host1 is running on one link." ;;
    10) echo "T10 NOC: spine1 and spine2 each lost one underlay BGP neighbor and one EVPN neighbor. Users report no impact yet." ;;
  esac
}

inject() {
  local t="$1"
  echo "Injecting ticket $t"
  case "$t" in
    1)  # MLAG: wrong peer-address on leaf2
        cfg leaf2 "mlag configuration" "peer-address 10.255.252.9" ;;
    2)  # BGP underlay: wrong remote-as for leaf3 on spine2
        cfg spine2 "router bgp 65100" "neighbor 10.255.255.11 remote-as 65103" ;;
    3)  # EVPN: route-target mismatch for VLAN 20 on POD_B
        for n in leaf3 leaf4; do
          cfg "$n" "router bgp 65102" "vlan 20" "no route-target both 10020:10020" "route-target both 10020:12020"
        done ;;
    4)  # VXLAN: VLAN 30 to VNI mapping removed on POD_B
        for n in leaf3 leaf4; do
          cfg "$n" "interface Vxlan1" "no vxlan vlan 30 vni 10030"
        done ;;
    5)  # Anycast gateway: virtual-router MAC removed on POD_B
        for n in leaf3 leaf4; do
          cfg "$n" "no ip virtual-router mac-address 00:1c:73:00:dc:01"
        done ;;
    6)  # MTU drift on the leaf3 uplinks and the spine ports facing leaf3
        cfg leaf3 "interface Ethernet1" "mtu 1400" "interface Ethernet2" "mtu 1400"
        cfg spine1 "interface Ethernet3" "mtu 1400"
        cfg spine2 "interface Ethernet3" "mtu 1400" ;;
    7)  # VTEP loopback (Loopback1 10.255.1.3) no longer advertised by POD_A
        for n in leaf1 leaf2; do
          cfg "$n" "ip prefix-list PL-LOOPBACKS-EVPN-OVERLAY" "no seq 20"
        done ;;
    8)  # ESI configured on an MLAG port-channel (leaf3 only)
        cfg leaf3 "interface Port-Channel5" "evpn ethernet-segment" \
            "identifier 0000:0000:0000:0000:0505" "route-target import 00:00:00:00:05:05" ;;
    9)  # STP: BPDU guard on the host-facing MLAG port-channel of leaf2 (host1 sends BPDUs)
        cfg leaf2 "interface Port-Channel5" "spanning-tree bpduguard enable" ;;
    10) # Interfaces: leaf4 uplinks shut
        cfg leaf4 "interface Ethernet1" "shutdown" "interface Ethernet2" "shutdown" ;;
    *)  echo "Unknown ticket: $t (use 1-10, all, random, list, restore)" >&2; exit 2 ;;
  esac
}

restore() {
  echo "Restoring the six fabric switches to the AVD intended config"
  for n in spine1 spine2 leaf1 leaf2 leaf3 leaf4; do
    local f="$INTENDED/$n.cfg"
    [[ -f "$f" ]] || { echo "missing $f (run python3 labs/avd/build.py)" >&2; exit 1; }
    echo "  -> $n"
    if [[ "$MODE" == "eapi" ]]; then
      local payload
      payload="$(python3 - "$f" <<'PY'
import json, sys
cfg = open(sys.argv[1]).read()
cmds = ["enable", "configure session c3-restore", "rollback clean-config"]
cmds += [l for l in cfg.splitlines() if l.strip() and not l.startswith("!") and l.strip() != "end"]
cmds += ["commit"]
print(json.dumps({"jsonrpc": "2.0", "method": "runCmds", "id": "restore",
                  "params": {"version": 1, "cmds": cmds, "format": "text"}}))
PY
)"
      curl -sk -u "$EAPI_USER:$EAPI_PASS" -H 'Content-Type: application/json' \
           -d "$payload" "https://${MGMT[$n]}/command-api" | grep -q '"error"' \
        && echo "     restore error on $n (check the session with: show configuration sessions)" >&2 || true
    else
      # shellcheck disable=SC2086
      $DOCKER cp "$f" "clab-${LAB}-${n}:/mnt/flash/intended.cfg"
      # shellcheck disable=SC2086
      $DOCKER exec "clab-${LAB}-${n}" Cli -p 15 -c "configure replace flash:intended.cfg" >/dev/null
    fi
  done
  rm -f "$HERE/.injected"
  # Port-Channel5 on leaf2 may still be err-disabled after T9; bounce it.
  cfg leaf2 "interface Port-Channel5" "shutdown" "no shutdown"
  echo "Done. Re-run ANTA to confirm a clean baseline."
}

[[ $# -ge 1 ]] || { sed -n '2,24p' "$0"; exit 1; }

case "$1" in
  list)    for t in $(seq 1 10); do ticket_text "$t"; done ;;
  restore) restore ;;
  all)     for t in $(seq 1 10); do inject "$t"; done; seq 1 10 | tr '\n' ' ' > "$HERE/.injected" ;;
  random)  n="${2:-3}"
           picks="$(seq 1 10 | shuf -n "$n" | sort -n | tr '\n' ' ')"
           for t in $picks; do inject "$t" >/dev/null; done
           echo "$picks" > "$HERE/.injected"
           echo "Injected $n random tickets. The complaints:"
           for t in $picks; do ticket_text "$t"; done
           echo "(Ticket numbers saved in $HERE/.injected; do not peek until you are done.)" ;;
  *)       for t in "$@"; do inject "$t"; ticket_text "$t"; done ;;
esac
