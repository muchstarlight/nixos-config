# 维护约束

- 注释只解释代码无法直接表达的原因、具体兼容性问题或复杂逻辑，不复述代码和常识。
- 使用直接、简短的陈述，不写对话角色、决定来源、操作经过或完成状态。
- 删除失效配置时，同时清理相关引用、参数、测试和说明。
- 同一信息只维护一处，避免在配置、注释和文档中重复解释。
- 新增模块、选项、包装层或目录须有当前具体用途，不为假设需求提前抽象。
- 交接和过程记录单独存放，不写入配置或项目文档。
- 不将历史讨论中的选择推定为当前要求或永久约束。

# NixOS 维护命令

- 以下命令已配置 sudo 免密，路径和参数须精确匹配：
  ```bash
  sudo /run/current-system/sw/bin/nixos-rebuild switch --flake /etc/nixos
  sudo /run/current-system/sw/bin/nixos-rebuild dry-activate --flake /etc/nixos
  ```
- `switch` 会应用配置；`dry-activate` 仅预览激活变更，不切换配置。
