# Capstone C3: troubleshooting ticket queue

`inject-faults.sh` breaks the finished lab fabric so you can practice the
"something is wrong, find it and fix it" half of the L5 DC exam. The tickets,
hints and answers are in `labs/lab-guide.html`, section **Capstone C3**.

## Before you start

1. The containerlab fabric is up (`sudo containerlab deploy -t labs/topology/l5dc.clab.yml`).
2. The fabric is at the AVD end state: `python3 labs/avd/build.py`, then deploy
   `labs/avd/intended/configs/*.cfg` (Lab D7, objective 7.3).
3. A clean ANTA run is your baseline:

   ```
   cd labs/avd
   anta nrfu -u admin -p admin -i anta-inventory.yml -c fabric-catalog.yml table --group-by device
   ```

## Usage

```
cd labs/capstone
./inject-faults.sh list          # the ten complaints, no answers
./inject-faults.sh 3             # one ticket
./inject-faults.sh 2 5 9         # several tickets
./inject-faults.sh random 3      # three random tickets (numbers saved in .injected)
./inject-faults.sh all           # everything at once (hard mode)
./inject-faults.sh restore       # configure replace back to the AVD intended config
```

Docker needs root on most hosts: `DOCKER="sudo docker" ./inject-faults.sh 3`.

## How it talks to the switches

Default (`MODE=docker`):

```
docker exec clab-l5dc-leaf2 Cli -p 15 -c $'configure\nmlag configuration\npeer-address 10.255.252.9\nend'
```

`Cli -p 15` opens the EOS CLI at privilege level 15 (already in enable mode), and
`-c` runs each newline-separated line as one command, in order. That is the same
as typing the lines at the `leaf2#` prompt.

Alternative (`MODE=eapi`): the script sends the same lines as a JSON-RPC
`runCmds` call to `https://<mgmt-ip>/command-api` with `curl`, so it works from
any machine that reaches the 172.100.100.0/24 management network, with no
Docker access. This needs `management api http-commands` on the switches, which
the day-0 startup configs and the AVD configs both enable.

Other variables: `LAB` (containerlab lab name, default `l5dc`), `EAPI_USER` /
`EAPI_PASS` (default `admin` / `admin`), `INTENDED` (folder of configs used by
`restore`, default `../avd/intended/configs`).

## Ground rules

- Faults are written to running-config only, never saved. `show running-config diffs`
  is fair game, and so is reloading a switch, but in the exam you would not get that
  shortcut, so try to find each fault from symptoms first.
- Fix each fault on the CLI the way you would in production (or change the AVD data
  model and redeploy, if the fault is a drift from intent). Then prove the fix with the
  verification listed in the lab guide and a clean ANTA run.
- `restore` puts every fabric switch back to the AVD intended config in one step.

## What each ticket touches

The ticket numbers map to the areas below. The exact faults are in the script and in
the collapsed answers in the lab guide; avoid reading either until you have tried.

| Ticket | Area |
|---|---|
| 1 | MLAG |
| 2 | BGP underlay |
| 3 | EVPN route targets |
| 4 | VXLAN VLAN-to-VNI mapping |
| 5 | Anycast gateway |
| 6 | MTU |
| 7 | VTEP loopback advertisement |
| 8 | EVPN ethernet segment (ESI) |
| 9 | Spanning tree |
| 10 | Interface state |
