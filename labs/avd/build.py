#!/usr/bin/env python3
"""Build EOS configs for the lab fabric with pyavd (no Ansible needed).

    pip install pyavd
    python3 build.py

Reads inventory.yml + group_vars/, writes:
  intended/structured_configs/<host>.yml
  intended/configs/<host>.cfg
  intended/test_catalogs/<host>-catalog.yml   (ANTA tests AVD derives from the design)
"""
from pathlib import Path
import yaml
import pyavd

HERE = Path(__file__).parent
inv = yaml.safe_load((HERE / "inventory.yml").read_text())


def collect(group, name, groups, members):
    """Flatten the inventory: groups[name] = child groups, members[name] = hosts."""
    group = group or {}
    groups.setdefault(name, [])
    members.setdefault(name, [])
    members[name] += list((group.get("hosts") or {}).keys())
    for child, sub in (group.get("children") or {}).items():
        groups[name].append(child)
        collect(sub, child, groups, members)


def host_groups(groups, members):
    """Return {host: [group, ...]} ordered outermost group first (Ansible-like)."""
    out = {}

    def visit(name, chain):
        chain = chain + [name]
        for h in members.get(name, []):
            out.setdefault(h, [])
            for g in chain:
                if g not in out[h]:
                    out[h].append(g)
        for child in groups.get(name, []):
            visit(child, chain)

    visit("all", [])
    return out


def deep_merge(a, b):
    for k, v in b.items():
        if isinstance(v, dict) and isinstance(a.get(k), dict):
            deep_merge(a[k], v)
        else:
            a[k] = v
    return a


_groups, _members = {}, {}
collect(inv["all"], "all", _groups, _members)
hosts = host_groups(_groups, _members)
all_inputs = {}
for host, groups in hosts.items():
    data = {}
    for g in groups:
        f = HERE / "group_vars" / f"{g}.yml"
        if f.exists():
            deep_merge(data, yaml.safe_load(f.read_text()) or {})
    data["inventory_hostname"] = host
    all_inputs[host] = data

for host, data in all_inputs.items():
    res = pyavd.validate_inputs(data)
    if res.validation_result.violations:
        raise SystemExit(f"{host}: " + "; ".join(f"{e.path}: {e.message}" for e in res.validation_result.violations))

facts = pyavd.get_avd_facts(all_inputs)
out = HERE / "intended"
for sub in ("structured_configs", "configs", "test_catalogs"):
    (out / sub).mkdir(parents=True, exist_ok=True)

structured = {}
for host, data in all_inputs.items():
    sc = pyavd.get_device_structured_config(host, data, avd_facts=facts)
    sc_dict = sc._as_dict() if hasattr(sc, "_as_dict") else dict(sc)
    structured[host] = sc_dict
    (out / "structured_configs" / f"{host}.yml").write_text(yaml.safe_dump(sc_dict, sort_keys=False))
    (out / "configs" / f"{host}.cfg").write_text(pyavd.get_device_config(sc))
    print("built", host)

try:
    from pyavd.api.anta import AVDFabricData
    fabric_data = AVDFabricData.from_structured_configs(structured)
    for host in all_inputs:
        cat = pyavd.get_device_test_catalog(host, structured[host], fabric_data)
        (out / "test_catalogs" / f"{host}-catalog.yml").write_text(cat.dump().yaml())
except Exception as e:  # catalog API differs across pyavd versions
    print("ANTA catalog step skipped:", repr(e))
