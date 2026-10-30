#!/usr/bin/env python3
"""只向明确指定的离线目标根目录部署私密网络文件，不修改当前系统。"""
import argparse
import json
import os
from pathlib import Path
import shutil


def validate_targets(root, files, directories, marker):
    """在任何写入前，检查所有文件、目录和标记的完整祖先链。"""
    for target in [*files, *directories, marker]:
        if not target.is_relative_to(root):
            raise ValueError('目标路径越过挂载根目录。')
        for path in (target, *target.parents):
            if path == root:
                break
            if path.is_symlink():
                raise ValueError('目标或祖先包含符号链接，停止部署。')
            if path != target and path.exists() and not path.is_dir():
                raise ValueError('目标祖先不是目录，停止部署。')
    for target in files:
        if target.exists():
            raise ValueError('目标文件已经存在；请人工检查，不自动覆盖。')
    for directory in directories:
        if directory.exists() and not directory.is_dir():
            raise ValueError('计划创建的目录已被其他文件占用。')
    if marker.exists() and not marker.is_file():
        raise ValueError('启用标记不是普通文件。')


def create_public_directories(directories):
    """只创建缺失的系统父目录，避免私密 umask 将 /etc、/var 变成不可遍历。"""
    for directory in directories:
        if not directory.exists():
            directory.mkdir(mode=0o755)
            directory.chmod(0o755)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', required=True, type=Path, help='root 专用私密备份目录')
    parser.add_argument('--target-root', required=True, type=Path, help='已挂载的未来 NixOS 根目录')
    parser.add_argument('--include-account', action='store_true', help='同时部署已私密备份的现有账户密码散列')
    args = parser.parse_args()
    if os.geteuid() != 0:
        parser.error('需要管理员权限；不要将私密文件改为普通用户可读。')
    root = args.target_root.resolve(strict=True)
    source = args.source.resolve(strict=True)
    if root == Path('/'):
        parser.error('禁止部署到当前系统根目录。')
    if not os.path.ismount(root):
        parser.error('目标必须是单独挂载的文件系统根目录，不允许写入普通临时目录。')
    if source.stat().st_uid != 0 or source.stat().st_mode & 0o077:
        parser.error('私密备份目录必须归 root 所有，且不允许组或其他用户访问。')
    mapping = {
        'config.dae': 'var/lib/nixos-private/dae/config.dae',
        'Home.conf': 'var/lib/nixos-private/wireguard/Home.conf',
        'home-network-switch.json': 'var/lib/nixos-private/home-network-switch.json',
    }
    if args.include_account:
        mapping['accounts/muchstarlight.hash'] = 'var/lib/nixos-private/accounts/muchstarlight.hash'
        account_directory = source / 'accounts'
        if account_directory.is_symlink() or not account_directory.is_dir():
            parser.error('账户备份目录必须是实际目录，不能是符号链接。')
        if account_directory.stat().st_uid != 0 or account_directory.stat().st_mode & 0o077:
            parser.error('账户备份目录必须归 root 所有且不允许组或其他用户访问。')
    for name in mapping:
        path = source / name
        if not path.is_file() or path.is_symlink():
            parser.error('私密备份不完整或包含不允许的符号链接。')
        if path.stat().st_uid != 0 or path.stat().st_mode & 0o077:
            parser.error('私密源文件必须归 root 所有且权限不得宽于 0600。')
    config = json.loads((source / 'home-network-switch.json').read_text())
    if config.get('interface') != 'Home' or config.get('enabled_marker') != '/etc/home-network-switch/enabled':
        parser.error('切换配置与 NixOS 模块不匹配，需要先审核。')
    destinations = [(source / name, root / relative) for name, relative in mapping.items()]
    connections = source / 'system-connections'
    if connections.is_symlink():
        parser.error('私密连接目录不能是符号链接。')
    if connections.is_dir():
        for path in connections.iterdir():
            if path.is_file() and not path.is_symlink():
                destinations.append((path, root / 'etc/NetworkManager/system-connections' / path.name))
    directories = [root / relative for relative in (
        'var/lib/nixos-private', 'var/lib/nixos-private/dae',
        'var/lib/nixos-private/wireguard', 'var/lib/nixos-private/accounts',
        'etc/home-network-switch',
        'etc/NetworkManager/system-connections',
    )]
    public_directories = [root / relative for relative in (
        'etc', 'var', 'var/lib', 'etc/NetworkManager',
    )]
    marker = root / 'etc/home-network-switch/enabled'
    try:
        validate_targets(root, [target for _, target in destinations],
                         [*directories, *public_directories], marker)
    except ValueError as error:
        parser.error(str(error))
    os.umask(0o077)
    create_public_directories(public_directories)
    for original, target in destinations:
        target.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        shutil.copyfile(original, target)
        target.chmod(0o600)
        os.chown(target, 0, 0)
    for directory in directories:
        directory.mkdir(mode=0o700, parents=True, exist_ok=True)
        directory.chmod(0o700)
        os.chown(directory, 0, 0)
    marker.touch(mode=0o600, exist_ok=True)
    print('已部署私密网络文件及现有 NetworkManager 连接；未输出敏感值。')
    print('这只是文件部署，不证明目标系统已经联网，也不会启动任何服务。')


if __name__ == '__main__':
    main()
