#!/usr/bin/env python3
"""离线测试网络切换决策和失败清理，不读取私密配置或改变真实路由。"""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch, mock_open
import json

source = Path(sys.argv.pop(1))
spec = importlib.util.spec_from_file_location('network_switch', source)
switch = importlib.util.module_from_spec(spec)
spec.loader.exec_module(switch)
CONFIG = {
    'interface': 'Home', 'interfaces': ['enp2s0', 'wlp0s20f3'],
    'home_gateway': '192.168.1.1', 'home_gateway_mac': '02:00:00:00:00:01',
    'home_wifi_uuid': '00000000-0000-0000-0000-000000000001',
    'local_endpoint': '192.168.100.1:51820', 'public_endpoint': 'vpn.example.invalid:51820',
    'table': 51821, 'priority': 18000, 'protocol': 186,
    'outer_mark': '0x51820', 'probe_mark': '0x51821',
    'proxy_host': '192.168.1.2', 'proxy_port': 7891,
    'enabled_marker': '/nonexistent/test-only', 'state_file': '/nonexistent/test-state',
    'address': '172.20.0.2/32',
}

class NetworkTests(unittest.TestCase):
    def test_default_route_metric(self):
        routes = [{'dst': 'default', 'dev': 'Home', 'metric': 0},
                  {'dst': 'default', 'dev': 'enp2s0', 'metric': 100},
                  {'dst': 'default', 'dev': 'wlp0s20f3', 'metric': 600}]
        self.assertEqual(switch.choose_default(routes, CONFIG['interfaces'])['dev'], 'enp2s0')

    def test_dead_link_not_selected(self):
        routes = [{'dst': 'default', 'dev': 'enp2s0', 'metric': 100, 'flags': ['linkdown']},
                  {'dst': 'default', 'dev': 'wlp0s20f3', 'metric': 600}]
        self.assertEqual(switch.choose_default(routes, CONFIG['interfaces'])['dev'], 'wlp0s20f3')

    def test_home_wifi_identity(self):
        route = {'dev': 'wlp0s20f3', 'gateway': CONFIG['home_gateway']}
        self.assertTrue(switch.is_home(CONFIG, route, CONFIG['home_wifi_uuid'], []))
        self.assertFalse(switch.is_home(CONFIG, route, 'other-network', []))

    def test_home_wired_identity(self):
        route = {'dev': 'enp2s0', 'gateway': CONFIG['home_gateway']}
        neighbors = [{'dev': 'enp2s0', 'dst': CONFIG['home_gateway'],
                      'lladdr': CONFIG['home_gateway_mac'], 'state': ['REACHABLE']}]
        self.assertTrue(switch.is_home(CONFIG, route, '', neighbors))
        neighbors[0]['state'] = ['FAILED']
        self.assertFalse(switch.is_home(CONFIG, route, '', neighbors))

    def test_home_plan_preserves_local_private_network(self):
        plan = switch.make_plan(CONFIG, {'dev': 'enp2s0'}, True, [])
        self.assertEqual(plan['networks'], [switch.DN42])
        self.assertEqual(plan['endpoint'], CONFIG['local_endpoint'])

    def test_away_plan_preserves_dns_exception(self):
        plan = switch.make_plan(CONFIG, {'dev': 'wlp0s20f3'}, False, ['192.168.1.1'] * 2)
        self.assertEqual(set(plan['networks']), {switch.DN42, switch.HOME})
        self.assertEqual(plan['exceptions'], ['192.168.1.1'])
        self.assertEqual(plan['endpoint'], CONFIG['public_endpoint'])

    def test_disabled_never_runs_commands(self):
        with patch.object(switch, 'run') as run:
            switch.apply(CONFIG)
            run.assert_not_called()

    def test_probe_does_not_commit_private_routes(self):
        plan = switch.make_plan(CONFIG, {'dev': 'wlp0s20f3'}, False, [])
        with patch.object(switch, 'run') as run:
            switch.prepare_policy(CONFIG, plan)
        for call in run.call_args_list:
            args = call.args[0]
            if 'rule' in args:
                self.assertNotIn(switch.HOME, args)
                self.assertNotIn(switch.DN42, args)

    def test_unowned_priority_rejected(self):
        with patch.object(switch, 'ip_json', return_value=[{'priority': 18000, 'protocol': 99}]):
            with self.assertRaises(switch.NetworkError):
                switch.check_reserved(CONFIG)

    def test_apply_failure_cleans_policy(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / 'config.json'
            config.write_text(json.dumps(CONFIG))
            with patch('sys.argv', ['switch', 'apply', '--config', str(config)]), \
                 patch.object(switch.os, 'geteuid', return_value=0), \
                 patch('builtins.open', mock_open()), \
                 patch.object(switch.fcntl, 'flock'), \
                 patch.object(switch, 'apply', side_effect=switch.NetworkError('模拟失败')), \
                 patch.object(switch, 'clear') as clear:
                self.assertEqual(switch.main(), 1)
                clear.assert_called_once_with(CONFIG)

if __name__ == '__main__':
    unittest.main(verbosity=2)
