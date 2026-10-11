#!/usr/bin/env python3
"""Quick test of the adapter layer."""
import sys
sys.path.insert(0, '.')
from adapters.registry import discover_schedulers, discover_services
import json

print('=== Schedulers ===')
for s in discover_schedulers():
    print(f'  source={s["source"]} jobs={len(s["jobs"])}')
    for j in s['jobs'][:3]:
        print(f'    - {j["id"]} | {j["schedule"]} | enabled={j["enabled"]}')
    if len(s['jobs']) > 3:
        print(f'    ... +{len(s["jobs"])-3} more')

print()
print('=== Services (empty config) ===')
svcs = discover_services({'services': {}})
for s in svcs:
    print(f'  source={s["source"]} services={len(s["services"])}')