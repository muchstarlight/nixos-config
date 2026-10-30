#!/usr/bin/env python3
"""检查控制器声明的独立 PATH，避免误靠当前系统环境通过测试。"""
from pathlib import Path
import re
import shutil
import subprocess
import sys

wrapper = Path(sys.argv[1]).read_text()
match = re.search(r'^export PATH="(.+):\$PATH"$', wrapper, re.MULTILINE)
if not match:
    raise SystemExit('未找到预期的控制器 PATH 包装。')
for name in ('ip', 'nmcli', 'wg', 'ping', 'getent'):
    executable = shutil.which(name, path=match.group(1))
    if not executable:
        raise SystemExit('控制器缺少运行时命令：' + name)
    if name == 'getent':
        subprocess.run([executable, '--version'], check=True, capture_output=True)
print('控制器五项运行时命令检查通过，不依赖宿主 PATH，未访问私密配置或变更网络。')
