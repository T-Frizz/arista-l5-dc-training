# ACE L5 Data Center: exam domains and objectives

This is the shared numbering for the study guide and the lab guide. Both use the same domain (D1–D7) and objective (e.g. 6.2) numbers.

## What "L5 Data Center" is

L5 is **ACE Professional – Data Center (AN-DC-PR)**. You earn it one of two ways:

| Path | Exams | Length |
|------|-------|--------|
| Two Specialist exams | **AN-DC-OP01** Data Center Operations + **AN-DC-EN01** Data Center Engineering | 2–4 h + 4 h |
| One Professional exam | **AN-DC-PR01** (mix of both) | 4 h |

All three are hands-on, open-book, proctored online (Honorlock), and run in the same virtual lab environment as the Arista Academy labs (EOS switches plus CloudVision). Each sitting uses one of several scenarios. Arista does not publish weights, question counts, or pass marks. Retakes need a 14-day wait. Recommended courses: Data Center Operations (DCOPS) and Data Center Engineering (DCENG).

Sources: [Arista exam datasheet – Data Center](https://www.training.arista.com/hubfs/Arista_Academy_Exam_Datasheets/Data%20Center.pdf), [Arista track datasheet – Data Center](https://www.training.arista.com/hubfs/Track%20Datasheets/Arista%20Academy%20Datasheet%20-%20Data%20Center.pdf?hsLang=en), [Fast Lane – AN-DC-PR](https://www.fastlaneus.com/certification/arista-dcpr), [Fast Lane – AN-DC-EN](https://www.fastlanetraining.ca/certification/arista-l3-dceng). Checked 2026-10-25.

Domains D1–D3 are the Operations exam. D4–D7 are the Engineering exam. The Professional exam draws on all seven. The domain names are Arista's seven published topic areas; the objective lines under them come from the exam datasheet's skills list and the DCOPS/DCENG course outlines.

## Operations (AN-DC-OP01)

### D1 – EOS Management
- **1.1** EOS operations: safe change execution, configuration sessions, checkpoints/rollback, config replace.
- **1.2** EOS upgrades: standard upgrade vs Smart System Upgrade (SSU), MLAG ISSU, chassis upgrade/reload, upgrades from CLI and from CloudVision.
- **1.3** EOS extensions and recovery: installing extensions (SWIX), Aboot/recovery procedures, flash and memory health.

### D2 – CloudVision Operations
- **2.1** CloudVision overview and setup: purpose and core concepts, CVP vs CVaaS, clustering, onboarding, upgrades, backup and restore, licensing.
- **2.2** CloudVision provisioning: device registration/onboarding, containers, config sources, designed vs running config, configlets, configlet builders, tasks and change control, reconcile, snapshots, rollback, image bundles, ZTP and ZTR.
- **2.3** CloudVision Studios (operations): workspaces, tags, build/review/submit, change control from Studios, static configuration, management connectivity, authentication, software management, mirroring, Day-2 changes.

### D3 – Monitoring and Troubleshooting
- **3.1** Advanced Event Management: CLI scheduler, event monitor, event manager, operational use cases.
- **3.2** Monitoring with CloudVision: dashboards, events and event groups, compliance views, config sanity checks, endpoint search, topology view.
- **3.3** EOS monitoring tools: SNMP, sFlow, `watch`/`diff`, LANZ, port mirroring, TAP aggregation.
- **3.4** Troubleshooting: system and software health, optics and physical errors, hardware, tcpdump and iperf, CLI and CVP health checks.

## Engineering (AN-DC-EN01)

### D4 – Layer 2 and Layer 3 Designs
- **4.1** Layer 2 leaf-spine (L2LS): VLANs, access/trunk ports, SVIs and subinterfaces, STP and its enhancements, LACP, MLAG, VRRP and VARP.
- **4.2** Layer 3 leaf-spine (L3LS): underlay architecture and routing intent, why a routed underlay, underlay options (OSPF, IS-IS, eBGP), the role of VXLAN and EVPN.
- **4.3** Design and best practice: avoiding common design and operations failures, MTU and jumbo frames, iBGP vs eBGP design, validation habits.

### D5 – Underlay Protocols
- **5.1** eBGP underlay: configuration and validation, ASN and addressing patterns, peer groups.
- **5.2** Load balancing and enhancements: ECMP (`maximum-paths`), BFD, route maps and prefix lists, listen ranges.
- **5.3** BGP with MLAG: the iBGP peering across the MLAG peer link and its deployment variations.
- **5.4** IGP underlay: OSPF and IS-IS configuration and validation in leaf-spine.

### D6 – Overlay Protocols
- **6.1** VXLAN: VTEPs (Vxlan1, loopback source), L2 and L3 VNIs, VLAN-to-VNI and VRF-to-VNI mapping, head-end replication (HER), VXLAN with MLAG (shared VTEP IP), troubleshooting.
- **6.2** EVPN overlay: MP-BGP EVPN, route types 2, 3, and 5, VRFs, VLAN-based vs VLAN-aware bundle services, symmetric vs asymmetric IRB.
- **6.3** EVPN multihoming: all-active ESI, route types 1 and 4, DF election, verification.

### D7 – Automation and Management
- **7.1** CloudVision engineering workflow: deploying L2LS, L3LS, and EVPN services with configlets.
- **7.2** CloudVision Studios (engineering): L3LS/EVPN Studio, EVPN services, host interfaces, external networks.
- **7.3** Arista Validated Designs (AVD) and ANTA: the same fabric as code. Not named on the datasheet, but the L3LS-EVPN Studio uses the AVD data model, and it is how this is done in practice. Treat it as real-world depth.

## Arista Warrior chapter map

Chapter titles are in [book/arista-warrior-index.md](../book/arista-warrior-index.md).

| Domain | Chapters |
|--------|----------|
| D1 | 8 Introduction to EOS, 9 Configuration Management, 10 Upgrading EOS, 14 Aboot, 16 The EOS Extension System |
| D2 | 13 Zero-Touch Provisioning, 15 CloudVision |
| D3 | 22 Email, 23 LANZ, 24 Scheduler, 25 tcpdump and Advanced Mirroring, 26 Tap Aggregation, 27 Event Manager, 28 Event Monitor, 29 Troubleshooting |
| D4 | 2 Network Designs, 11 LLDP, 17 MSTP, 18 MLAG, 19 First-Hop Redundancy |
| D5 | 2 Network Designs, 18 MLAG, 20 FlexRoute |
| D6 | 21 VXLAN |
| D7 | 12 Bash, 15 CloudVision, 30 eAPI, 31 Containers, 32 vEOS |
