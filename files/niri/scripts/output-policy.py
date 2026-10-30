#!/usr/bin/env python3
"""外屏可用时关闭内屏，外屏断开后恢复内屏，不改变 DPMS 和休眠策略。"""

import argparse
import json
import os
from pathlib import Path
import socket
import time


def desired_actions(outputs):
    def internal(name):
        return name.lower().startswith(('edp-', 'lvds-', 'dsi-'))

    external_active = any(
        not internal(name) and output.get('current_mode') is not None
        for name, output in outputs.items()
    )
    actions = []
    for name, output in outputs.items():
        if not internal(name):
            continue
        enabled = output.get('current_mode') is not None
        if external_active and enabled:
            actions.append((name, 'Off'))
        elif not external_active and not enabled:
            actions.append((name, 'On'))
    return actions


def socket_path():
    """优先使用会话变量，兼容从没有 NIRI_SOCKET 的终端进行诊断。"""
    configured = os.environ.get('NIRI_SOCKET')
    if configured and Path(configured).exists():
        return configured
    runtime = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}'))
    candidates = list(runtime.glob('niri*.sock'))
    if len(candidates) != 1:
        raise RuntimeError('未找到唯一的 Niri 会话套接字')
    return str(candidates[0])


def request(message):
    """使用 Niri 的行分隔 JSON IPC，不读取窗口标题或其他应用信息。"""
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(3)
        connection.connect(socket_path())
        connection.sendall(json.dumps(message).encode() + b'\n')
        with connection.makefile('rb') as stream:
            reply = json.loads(stream.readline())
    if 'Err' in reply:
        raise RuntimeError(reply['Err'])
    return reply['Ok']


def apply_policy(dry_run=False):
    """状态已经符合要求时不发送改屏命令，避免反复 modeset。"""
    outputs = request('Outputs')['Outputs']
    actions = desired_actions(outputs)
    for name, action in actions:
        if not dry_run:
            request({'Output': {'output': name, 'action': action}})
        print(f'{name}: {action}' + ('（仅预览）' if dry_run else ''), flush=True)
    return actions


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--once', action='store_true', help='只检查并应用一次')
    parser.add_argument('--dry-run', action='store_true', help='只预览，不修改输出')
    options = parser.parse_args()
    if options.once or options.dry_run:
        apply_policy(options.dry_run)
        return
    previous_error = None
    while True:
        try:
            apply_policy()
            previous_error = None
        except (OSError, ValueError, KeyError, RuntimeError) as error:
            if str(error) != previous_error:
                print(f'暂时无法应用显示策略：{error}', flush=True)
                previous_error = str(error)
        # Niri 26.04 的事件流没有完整输出状态事件，使用轻量 IPC 定期核对。
        time.sleep(1)


if __name__ == '__main__':
    main()
