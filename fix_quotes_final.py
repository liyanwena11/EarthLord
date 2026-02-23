#!/usr/bin/env python3
"""
最终修复：移除 LogXXX("") 中的多余双引号
"""

import re
from pathlib import Path

def fix_file(filepath):
    """修复单个文件"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # 匹配 LogXXX(""..."") 并替换为 LogXXX("...")
    # 不关心中间的内容，直接替换开头的 "" 和结尾的 ""
    content = re.sub(r'(LogDebug|LogInfo|LogWarning|LogError)\(""(.+?)""\)', r'\1("\2")', content, flags=re.DOTALL)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

fixed = 0
for f in Path('/Users/lyanwen/Desktop/EarthLord/EarthLord').rglob('*.swift'):
    if fix_file(f):
        fixed += 1

print(f"✅ Fixed {fixed} files")
