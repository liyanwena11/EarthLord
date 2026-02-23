#!/usr/bin/env python3
"""
修复 LogXXX 调用中的双引号问题
"""

import re
import sys
from pathlib import Path

def fix_file(filepath):
    """修复单个文件中的双引号"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # 修复 LogDebug(""...")  → LogDebug("...")
    # 使用全局标志替换所有匹配项
    content = re.sub(r'Log(Debug|Info|Warning|Error)\(""([^"]+)""\)', r'Log\1("\2")', content, flags=re.MULTILINE)

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ Fixed {filepath.name}")
        return True
    return False

def main():
    total_fixed = 0
    swift_files = Path('/Users/lyanwen/Desktop/EarthLord/EarthLord').rglob('*.swift')

    for filepath in swift_files:
        if fix_file(filepath):
            total_fixed += 1

    print(f"\n✅ Total files fixed: {total_fixed}")

if __name__ == '__main__':
    main()

