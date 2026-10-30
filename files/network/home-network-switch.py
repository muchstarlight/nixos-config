#!/usr/bin/python3
"""按当前物理网络选择家中直连或 WireGuard，仅管理独立策略表。"""

import argparse
import fcntl
import ipaddress
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time

DN42 = "172.20.0.0/14"
HOME = "192.168.0.0/16"


class NetworkError(RuntimeError):
    """可安全记录、不包含命令原始输出的网络错误。"""


def run(args, check=True, timeout=10):
    """不将可能含有 Peer 标识的命令输出写入日志。"""
    result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    if check and result.returncode:
        raise NetworkError(f"{args[0]} {args[1]} 执行失败，退出码 {result.returncode}")
    return result


def ip_json(*args, optional=False):
    result = run(["ip", "-N", "-j", *args], check=not optional)
    return json.loads(result.stdout) if result.returncode == 0 else []


def choose_default(routes, interfaces):
    candidates = [r for r in routes if r.get("dev") in interfaces
                  and r.get("dst") in {"default", "0.0.0.0/0", "::/0"}
                  and not set(r.get("flags", [])) & {"linkdown", "dead"}]
    return min(candidates, key=lambda r: r.get("metric", 0)) if candidates else None


def is_home(config, route, wifi_uuid, neighbors):
    if not route or route.get("gateway") != config["home_gateway"]:
        return False
    if route["dev"].startswith("wl") and wifi_uuid == config["home_wifi_uuid"]:
        return True
    return any(n.get("dev") == route["dev"]
               and n.get("dst") == config["home_gateway"]
               and n.get("lladdr", "").lower() == config["home_gateway_mac"].lower()
               and not set(n.get("state", [])) & {"FAILED", "INCOMPLETE"}
               for n in neighbors)


def make_plan(config, route, at_home, exceptions):
    return {
        "mode": "home" if at_home else "away",
        "device": route["dev"] if route else None,
        "gateway": route.get("gateway") if route else None,
        "endpoint": config["local_endpoint"] if at_home else config["public_endpoint"],
        "networks": [DN42] if at_home else [DN42, HOME],
        "exceptions": sorted(set(exceptions)),
    }


def snapshot(config, probe_neighbor=False):
    routes4 = ip_json("-4", "route", "show", "table", "main", "default")
    routes6 = ip_json("-6", "route", "show", "table", "main", "default")
    route = choose_default(routes4, config["interfaces"])
    if route is None:
        route = choose_default(routes6, config["interfaces"])
    if route is None:
        return make_plan(config, None, False, [])
    dev = route["dev"]
    uuid = run(["nmcli", "-g", "GENERAL.CON-UUID", "device", "show", dev], check=False).stdout.strip()
    if probe_neighbor and route.get("gateway") == config["home_gateway"]:
        # 首次接入有线时可能还没有邻居记录，探测只用于填充网关邻居缓存。
        run(["ping", "-n", "-c", "1", "-W", "1", "-I", dev, config["home_gateway"]], check=False, timeout=3)
    neighbors = ip_json("-4", "neigh", "show", "dev", dev)
    exceptions = []
    active_devices = {r.get("dev") for r in routes4 + routes6
                      if r.get("dev") in config["interfaces"]}
    for item in routes4:
        if item.get("dev") in active_devices and item.get("gateway"):
            exceptions.append(item["gateway"])
    for device in active_devices:
        dns = run(["nmcli", "-g", "IP4.DNS", "device", "show", device], check=False).stdout
        for line in dns.splitlines():
            try:
                address = ipaddress.ip_address(line.strip())
                if address.version == 4:
                    exceptions.append(str(address))
            except ValueError:
                continue
    return make_plan(config, route, is_home(config, route, uuid, neighbors), exceptions)


def owned_rules(config, family):
    return [rule for rule in ip_json(family, "rule", "show")
            if str(rule.get("protocol")) == str(config["protocol"])
            and config["priority"] <= rule.get("priority", -1) < config["priority"] + 200]


def clear(config):
    """只撤销本方案的规则和路由，不改主路由表或 dae 服务。"""
    for family in ["-4", "-6"]:
        for rule in owned_rules(config, family):
            run(["ip", family, "rule", "del", "pref", str(rule["priority"]),
                 "protocol", str(config["protocol"])])
        run(["ip", family, "route", "flush", "table", str(config["table"]),
             "proto", str(config["protocol"])], check=False)
    Path(config["state_file"]).unlink(missing_ok=True)


def check_reserved(config):
    for family in ["-4", "-6"]:
        for rule in ip_json(family, "rule", "show"):
            if config["priority"] <= rule.get("priority", -1) < config["priority"] + 200:
                if str(rule.get("protocol")) != str(config["protocol"]):
                    raise NetworkError("预留策略优先级已被其他配置占用")
        for route in ip_json(family, "route", "show", "table", str(config["table"]), optional=True):
            if str(route.get("protocol")) != str(config["protocol"]):
                raise NetworkError("预留路由表已被其他配置占用")


def add_rule(config, family, offset, selectors, table):
    run(["ip", family, "rule", "add", "pref", str(config["priority"] + offset),
         *selectors, "lookup", str(table), "protocol", str(config["protocol"])])


def prepare_policy(config, plan):
    """先安装外层直连和探测规则，暂不接管一般私网流量。"""
    for family in ["-4", "-6"]:
        add_rule(config, family, 0, ["fwmark", config["outer_mark"]], "main")
    for address in plan["exceptions"]:
        add_rule(config, "-4", 10, ["to", address + "/32"], "main")
    for network in plan["networks"]:
        run(["ip", "-4", "route", "replace", network, "dev", config["interface"],
             "table", str(config["table"]), "proto", str(config["protocol"])])
    add_rule(config, "-4", 20, ["fwmark", config["probe_mark"]], config["table"])


def commit_policy(config, plan):
    """通过连通性检查后，才让一般目标流量进入隧道。"""
    for index, network in enumerate(plan["networks"]):
        add_rule(config, "-4", 100 + index, ["to", network], config["table"])


def peer_status(interface):
    """Peer 公钥仅在进程内部使用，绝不写入输出和状态文件。"""
    peers = run(["wg", "show", interface, "peers"]).stdout.splitlines()
    if len(peers) != 1:
        raise NetworkError("Home 必须恰好包含一个 Peer")
    peer = peers[0]
    handshakes = run(["wg", "show", interface, "latest-handshakes"]).stdout.splitlines()
    timestamp = next((int(line.split()[1]) for line in handshakes
                      if line.split()[0] == peer), 0)
    endpoints = run(["wg", "show", interface, "endpoints"]).stdout.splitlines()
    endpoint = next((line.split()[1] for line in endpoints if line.split()[0] == peer), "")
    return peer, timestamp, endpoint


def resolve_endpoint(value, current):
    host, port = value.rsplit(":", 1)
    # getent 由子进程运行，避免系统 DNS 不通导致主控制器无限等待。
    result = run(["getent", "ahosts", host.strip("[]")], timeout=8)
    candidates = []
    for line in result.stdout.splitlines():
        address = ipaddress.ip_address(line.split()[0])
        endpoint = f"[{address}]:{port}" if address.version == 6 else f"{address}:{port}"
        if endpoint not in candidates:
            candidates.append(endpoint)
    if not candidates:
        raise NetworkError("未解析到 WireGuard Endpoint")
    if current in candidates:
        return current
    return min(candidates, key=lambda item: item.startswith("["))


def handshake_recent(config):
    _, timestamp, _ = peer_status(config["interface"])
    return timestamp > 0 and 0 <= time.time() - timestamp < 150


def probe_proxy(config):
    """仅做经隧道的 TCP 建连，不发送 SOCKS5 用户名、密码或业务请求。"""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as connection:
        connection.setsockopt(socket.SOL_SOCKET, socket.SO_MARK, int(config["probe_mark"], 0))
        connection.settimeout(6)
        connection.connect((config["proxy_host"], config["proxy_port"]))


def assert_wireguard(config):
    # 不自动重启地址异常的接口，也不替用户绕过手动停止操作。
    info = ip_json("-4", "address", "show", "dev", config["interface"], optional=True)
    expected = ipaddress.ip_interface(config["address"])
    if not any(a.get("local") == str(expected.ip) and a.get("prefixlen") == expected.network.prefixlen
               for item in info for a in item.get("addr_info", [])):
        raise NetworkError("Home 地址未正确配置；请先通过受控启动流程启用 wg-quick")
    mark = run(["wg", "show", config["interface"], "fwmark"]).stdout.strip()
    if mark != config["outer_mark"]:
        raise NetworkError("Home 的 FwMark 与本方案不一致")


def write_state(config, plan):
    path = Path(config["state_file"])
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(plan, ensure_ascii=False, indent=2) + "\n")
    os.chmod(temporary, 0o600)
    temporary.replace(path)


def policy_matches(config, plan):
    """同时检查规则数量和实际路由，避免外部删除路由后误判为健康。"""
    expected = len(plan["networks"]) + len(plan["exceptions"]) + 2
    if len(owned_rules(config, "-4")) != expected or len(owned_rules(config, "-6")) != 1:
        return False
    routes = ip_json("-4", "route", "show", "table", str(config["table"]), optional=True)
    actual = {route.get("dst") for route in routes
              if route.get("dev") == config["interface"]
              and str(route.get("protocol")) == str(config["protocol"])}
    return actual == set(plan["networks"])


def apply(config):
    if not Path(config["enabled_marker"]).exists():
        print("自动切换尚未启用；未修改网络。")
        return
    check_reserved(config)
    plan = snapshot(config, probe_neighbor=True)
    if not plan["device"]:
        clear(config)
        print("没有可用物理默认路由；已撤销本方案策略。")
        return
    assert_wireguard(config)
    peer, _, current = peer_status(config["interface"])
    state_path = Path(config["state_file"])
    previous = json.loads(state_path.read_text()) if state_path.exists() else {}
    # 网络变更时先撤销旧私网策略，确保 DDNS 和当前 DNS 不被旧隧道路由困住。
    same_network = all(previous.get(key) == plan[key]
                       for key in ["mode", "device", "gateway", "exceptions"])
    if not same_network:
        clear(config)
    endpoint = resolve_endpoint(plan["endpoint"], current)
    plan["resolved_endpoint"] = endpoint
    if previous == plan and current == endpoint and handshake_recent(config):
        if policy_matches(config, plan):
            print(f"状态正常：{plan['mode']}，物理出口 {plan['device']}。")
            return
    clear(config)
    prepare_policy(config, plan)
    run(["wg", "set", config["interface"], "peer", peer, "endpoint", endpoint,
         "persistent-keepalive", "25"])
    if plan["mode"] == "away":
        # 该探测仅使用专用标记，普通连接仍保持原路由。
        probe_proxy(config)
    else:
        # 保留心跳触发握手；不向未知 DN42 主机发送测试数据。
        deadline = time.monotonic() + 30
        while not handshake_recent(config) and time.monotonic() < deadline:
            time.sleep(1)
    if not handshake_recent(config):
        raise NetworkError("WireGuard 尚未成功握手，未接管私网流量")
    commit_policy(config, plan)
    write_state(config, plan)
    print(f"切换完成：{plan['mode']}，物理出口 {plan['device']}，隧道目标 {', '.join(plan['networks'])}。")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["plan", "apply", "clear"])
    parser.add_argument("--config", default="/etc/home-network-switch/config.json")
    args = parser.parse_args()
    config = json.loads(Path(args.config).read_text())
    if args.action == "plan":
        print(json.dumps(snapshot(config), ensure_ascii=False, indent=2))
        return 0
    if os.geteuid() != 0:
        parser.error("apply 和 clear 需要 root 权限")
    # 避免 dispatcher 和定时器同时操作。
    with open("/run/lock/home-network-switch.lock", "a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("另一次切换正在进行，本次跳过。")
            return 0
        try:
            clear(config) if args.action == "clear" else apply(config)
        except Exception as error:
            try:
                clear(config)
            except Exception:
                print("警告：策略清理未完成，请人工检查专用路由表。", file=sys.stderr)
            # 不打印异常原文，防止第三方命令意外携带敏感字段。
            detail = str(error) if isinstance(error, NetworkError) else type(error).__name__
            print(f"未启用隧道分流，已尝试撤销本方案策略：{detail}", file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
