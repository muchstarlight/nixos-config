# nixos-config

个人 NixOS Flake 配置，主机为 `laptop`。

## 环境

- ZEN 内核、Intel + NVIDIA open 混合显卡。
- TTY 登录后运行 `niri-session`，使用 Noctalia 桌面外壳。
- Fcitx5/Rime、PipeWire、NetworkManager、dae、WireGuard。
- Home Manager 管理 Fish、Pi、Node.js、Obsidian、VSCodium 与 Zen 等用户应用。
- GnuPG、GPG Agent 与 Qt 密码输入窗口，集成 Fish 终端环境。
- LocalSend 由 NixOS 管理，同时放行文件接收端口。
- 保留 AppImage binfmt 支持与 FFmpeg 运行库，兼容尚未迁移的应用。

输入版本见 [`flake.nix`](flake.nix) 和 [`flake.lock`](flake.lock)，NVIDIA 驱动版本见 [`modules/hardware/nvidia.nix`](modules/hardware/nvidia.nix)。

## 结构

| 路径 | 用途 |
|---|---|
| `flake.nix` | 输入、主机与输出注册 |
| `lib/` | 主机组装、chroot 激活保护 |
| `hosts/laptop/` | 本机硬件、账户、网络、维护和桌面配置 |
| `modules/` | 系统、桌面和显卡模块 |
| `home/muchstarlight/` | 用户应用与 Shell 配置 |
| `files/` | 桌面资产及运行脚本 |
| `nix/` | 软件包输出和检查集合 |
| `scripts/` | 检查入口、私密网络文件部署工具 |
| `tests/` | 离线测试 |

## 检查与重建

```bash
bash scripts/check.sh
bash scripts/check.sh --build
```

默认只求值；`--build` 构建全部 checks 及 laptop 驱动、网络工具，可能下载缓存并写入 Nix store，不安装或激活系统，也不更新锁文件。

本机 Fish 中使用 `rebuild`，等价于：

```bash
sudo /run/current-system/sw/bin/nixos-rebuild switch --flake /etc/nixos
```

`/etc/nixos` 链接到本仓库。该固定命令配置了免密 sudo，其他命令仍需密码。

## 应用来源与更新

| 输入 | 用途 |
|---|---|
| `nixpkgs` | NixOS 稳定分支，系统基础与默认软件包 |
| `nixpkgs-unstable` | VSCodium、LocalSend、dae、Pi |
| `zen-browser` | `zen-browser-flake` 的 beta 分支，复用 unstable 包集 |

Noctalia 保留自身的上游依赖。单独更新应用来源：

```bash
nix flake update nixpkgs-unstable zen-browser
bash scripts/check.sh --build
```

审阅 `flake.lock` 后再执行 `rebuild`；更新锁文件不会自动切换正在运行的软件。

### 首次从 AppImage 切换

切换后，先备份并移出 `~/.local/share/applications` 中的旧 AppImage 入口：`vscodium.desktop`、`localsend.desktop`、`zen_browser.desktop` 与 `userapp-Zen-*.desktop` 会留下重复项，旧入口仍启动 AppImage。旧默认浏览器关联也需在新 Zen 中重新设置；`Mod+B` 仍打开 Firefox。

保留 `~/AppImages` 和应用配置目录，直到确认新包启动、配置与数据正常。

## 主机边界

- `laptop` 包含真实 Btrfs/EFI UUID，允许更新引导器，不是通用安装模板。
- `laptop-preview` 使用占位根设备、关闭引导安装并阻止激活，仅供构建检查。
- `files/niri` 含本机 PCI render 节点、显示器名称和模式。
- 认证材料、网络连接、密钥和代理节点从目标系统的私密运行时文件加载，不包含在仓库中。

**不要在其他机器直接运行本仓库的 `nixos-install` 或 `switch`。** 新主机需独立审查硬件、账户、私密文件和引导方案；构建成功不代表真机可用。

## 许可

[MIT License](LICENSE)。第三方内容仍遵守其原许可。
