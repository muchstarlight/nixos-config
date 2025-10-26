# 介绍
这是一个nixos的系统配置仓库
目前处于摸索阶段，有改进建议欢迎指正

# 文件结构的大致框架
```
nixos-config
├── flake.nix                 # 核心配置入口
├── flake.lock
├── modules/                  # 通用模块（所有设备共享）
│   ├── base/                 # 基础配置
│   │   ├── system.nix        # 时区/语言/基础服务
│   │   ├── users.nix         # 用户账户配置
│   │   └── security.nix      # 防火墙/SSH等
│   ├── home/                 # home-manager 共享配置
│   │   ├── base.nix          # 基础 shell 环境
│   │   ├── apps.nix          # 通用 GUI 应用
│   │   └── cli-tools.nix     # 命令行工具集
│   └── common/      # 跨设备通用配置
│       ├── audio.nix         # 音频服务
│       └── bluetooth.nix     # 蓝牙支持
├── hosts/                    # 按设备划分的专属配置
│   ├── laptop/               # 笔记本配置
│   │   ├── hardware-configuration.nix # 自动生成的硬件配置
│   │   ├── laptop-specific.nix # 触摸板/背光等特有配置
│   │   └── configuration.nix # 主配置文件（导入通用模块+本机特有）
│   ├── desktop/              # 台式机配置（结构同上）
│   └── server/               # 服务器配置（结构同上）
└── overlays/                 # 自定义包覆盖（可选）
    └── custom-packages.nix
```
