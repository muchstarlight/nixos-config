# 文件结构
```
nixos-config/
├── flake.nix                  # 定义 flakes 输出以及其依赖关系
├── flake.lock                 # 锁定 flakes 输入的具体版本信息
├── README.md                  # 项目说明文档
├── modules/                   # 存放各个功能模块的 nix 文件
│   ├── common/                # 公共的基础配置，适用于所有主机
│   │   ├── packages.nix       # 基础软件包集合
│   │   └── services.nix       # 基础服务配置
│   ├── hardware-specific/     # 针对特定硬件的配置
│   │   ├── laptop/            # 笔记本电脑专用配置
│   │   │   ├── wifi.nix       # 笔记本无线网卡配置
│   │   │   └── touchpad.nix   # 触控板配置
│   │   ├── desktop/           # 台式机专用配置
│   │   │   ├── gpu.nix        # 显卡配置
│   │   │   └── sound.nix      # 声卡配置
│   ├── overlays/              # 自定义包覆盖层
│   │   └── my-overlay.nix     # 包含自定义包定义的地方
└── hosts/                     # 不同主机特定的配置
    ├── desktop.nix            # 桌面机器配置
    ├── server.nix             # 服务器配置
    └── laptop.nix             # 笔记本电脑配置
```
