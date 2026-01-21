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
│   │   └── users.nix         # 用户账户配置
│   ├── home/                 # home-manager 共享配置
│   │   └── home.nix          # 用户环境、包管理、shell和工具配置
│   └── common/               # 跨设备通用配置
│       ├── ChineseSoftware.nix  # 中文软件包
│       ├── dae.nix              # 网络代理配置
│       ├── fcitx5.nix           # 中文输入法设置
│       ├── fhs.nix              # 文件系统层次标准支持
│       ├── nvidia.nix           # NVIDIA GPU驱动 (Optimus配置)
│       ├── audio.nix            # 音频服务
│       └── bluetooth.nix        # 蓝牙支持
└── hosts/                    # 按设备划分的专属配置
    └── laptop/               # 笔记本配置
        ├── hardware-configuration.nix # 自动生成的硬件配置
        ├── laptop-specific.nix # 触摸板/背光等特有配置
        └── configuration.nix # 主配置文件（导入通用模块+本机特有）
```
