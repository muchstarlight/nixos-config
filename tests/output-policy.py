#!/usr/bin/env python3
"""验证显示策略的断线恢复行为，不连接真实显示会话。"""

import importlib.util
from pathlib import Path
import sys

script = Path(sys.argv[1])
spec = importlib.util.spec_from_file_location('output_policy', script)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

cases = [
    ({'DP-2': {'current_mode': 1}, 'eDP-1': {'current_mode': 0}}, [('eDP-1', 'Off')]),
    ({'DP-2': {'current_mode': 1}, 'eDP-1': {'current_mode': None}}, []),
    ({'eDP-1': {'current_mode': None}}, [('eDP-1', 'On')]),
    ({'eDP-1': {'current_mode': 0}}, []),
    ({'DP-2': {'current_mode': None}, 'eDP-1': {'current_mode': 0}}, []),
    ({'DP-2': {'current_mode': None}, 'eDP-1': {'current_mode': None}}, [('eDP-1', 'On')]),
    ({}, []),
    ({'HDMI-A-1': {'current_mode': 0}, 'eDP-1': {'current_mode': 0}}, [('eDP-1', 'Off')]),
]
for outputs, expected in cases:
    assert module.desired_actions(outputs) == expected, (outputs, expected)
print(f'显示策略：{len(cases)} 项检查通过')
