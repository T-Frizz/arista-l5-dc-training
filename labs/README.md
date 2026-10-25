# L5 Data Center labs

Open **[lab-guide.html](lab-guide.html)** in a browser. It holds seven domain labs
(D1-D7, numbered like the exam domains in [../docs/exam-objectives.md](../docs/exam-objectives.md))
and five real-world capstones, all on one containerlab fabric.

| Folder | What it is |
|---|---|
| `topology/l5dc.clab.yml` | containerlab topology: spine1-2, leaf1-4 (two MLAG pairs), host1-2, core1 |
| `topology/startup/` | Day-0 configs (management, admin/admin, eAPI, gNMI, LLDP). Hosts and core1 are pre-built |
| `avd/` | AVD inputs for the finished EVPN fabric, `build.py` (pyavd, no Ansible), Ansible playbooks, ANTA inventory |
| `avd/intended/configs/` | Generated end-state configs. Use them to skip ahead or reset |
| `avd/intended/test_catalogs/` | ANTA tests that AVD derives from the design |
| `capstone/` | Fault-injection script for the C3 troubleshooting tickets |

Quick start:

```
sudo containerlab deploy -t labs/topology/l5dc.clab.yml
```

On EVE-NG instead of containerlab, follow "Running this lab on EVE-NG" in the guide's Build the lab section (vEOS or cEOS, same configs; vEOS uses Management1).

```
ssh admin@172.100.100.21          # leaf1, password admin
pip install pyavd anta && python3 labs/avd/build.py
```

Needs Docker, about 12 GB RAM, and a cEOS-lab image imported as `ceos:4.34.2F`
(change the tag in the topology file if you use another release).
Sample outputs in the guide are representative, not captured from a live fabric.
