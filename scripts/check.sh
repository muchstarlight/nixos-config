#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."

build=false
host=laptop
while (($#)); do
  case "$1" in
    --build) build=true; shift ;;
    --host)
      [[ $# -ge 2 && $2 =~ ^[a-zA-Z0-9_-]+$ ]] || { printf '需要有效的 --host 名称。\n' >&2; exit 2; }
      host=$2; shift 2 ;;
    *) printf '用法：%s [--build] [--host 主机名]\n' "$0" >&2; exit 2 ;;
  esac
done

nix_cmd=(nix --extra-experimental-features 'nix-command flakes')
printf '检查 Flake 和全部主机声明（不更新锁文件）……\n'
"${nix_cmd[@]}" flake check --no-build --no-update-lock-file
printf '\n检查主机 %s 的完整系统派生……\n' "$host"
"${nix_cmd[@]}" eval --no-update-lock-file --raw ".#nixosConfigurations.${host}.config.system.build.toplevel.drvPath"
printf '\n'

if "$build"; then
  printf '\n实际构建全部检查，包括维护、布局与主机隔离测试……\n'
  "${nix_cmd[@]}" flake check --no-update-lock-file --max-jobs 2 --cores 4
  printf '\n构建 laptop 专属驱动和网络工具；不激活系统……\n'
  "${nix_cmd[@]}" build --no-update-lock-file --no-link --print-out-paths --max-jobs 2 --cores 4 \
    '.#packages.x86_64-linux.nvidia-open' \
    '.#packages.x86_64-linux.dae' \
    '.#packages.x86_64-linux.network-controller' \
    '.#packages.x86_64-linux.network-bootstrap' \
    '.#packages.x86_64-linux.network-service-units'
fi
