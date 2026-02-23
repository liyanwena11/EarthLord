#!/usr/bin/env python3
"""
自动清理 Swift 文件中的 print 语句，替换为 Logger 调用
"""

import re
import sys
from pathlib import Path

def extract_emoji_from_print(print_content):
    """从 print 语句中提取 emoji 来判断日志级别"""
    if '❌' in print_content or 'error' in print_content.lower() or '失败' in print_content or '错误' in print_content:
        return 'LogError'
    elif '⚠️' in print_content or 'warning' in print_content.lower() or '警告' in print_content:
        return 'LogWarning'
    elif '✅' in print_content or 'success' in print_content.lower() or '成功' in print_content:
        return 'LogInfo'
    else:
        return 'LogDebug'

def clean_print_content(content):
    """清理 print 内容，移除多余的装饰符号"""
    # 移除常见的日志前缀
    content = re.sub(r'^[─│├└┼]*\s*', '', content)
    content = re.sub(r'^\[.*?\]\s*', '', content)
    content = re.sub(r'^🔍\s*\[调试\]\s*', '', content)
    content = re.sub(r'^📝\s*\[步骤.*?\]\s*', '', content)
    content = re.sub(r'^📊\s*\[.*?\]\s*', '', content)
    content = re.sub(r'^🔵\s*\[.*?\]\s*', '', content)

    # 移除分隔线
    content = re.sub(r'^[━─]+$', '', content)

    return content.strip()

def convert_print_to_logger(match):
    """将 print 语句转换为 Logger 调用"""
    full_match = match.group(0)
    indent = match.group(1)
    content = match.group(2)

    # 清理内容
    cleaned_content = clean_print_content(content)

    # 确定日志级别
    log_func = extract_emoji_from_print(content)

    # 如果内容为空，返回注释
    if not cleaned_content:
        return f'{indent}// {content}'

    # 返回 Logger 调用
    return f'{indent}{log_func}("{cleaned_content}")'

def process_file(filepath):
    """处理单个 Swift 文件"""
    print(f"Processing {filepath}...")

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # 匹配 print 语句（支持多行）
    # Pattern: indent + print( + content + )
    pattern = r'^(\s*)print\((.*?)\)(\s*$|;)'

    def replace_func(match):
        return convert_print_to_logger(match)

    content = re.sub(pattern, replace_func, content, flags=re.MULTILINE | re.DOTALL)

    if content != original_content:
        # 创建备份
        backup_path = filepath.with_suffix('.swift.bak')
        with open(backup_path, 'w', encoding='utf-8') as f:
            f.write(original_content)

        # 写入新内容
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

        # 统计替换数量
        original_count = original_content.count('print(')
        new_count = content.count('print(')
        replaced = original_count - new_count

        print(f"  ✓ Replaced {replaced} print statements")
        return replaced
    else:
        print(f"  - No changes needed")
        return 0

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 cleanup_prints.py <file.swift>...")
        sys.exit(1)

    total_replaced = 0
    for filepath in sys.argv[1:]:
        path = Path(filepath)
        if not path.exists():
            print(f"✗ File not found: {filepath}")
            continue

        if not filepath.endswith('.swift'):
            print(f"✗ Not a Swift file: {filepath}")
            continue

        replaced = process_file(path)
        total_replaced += replaced

    print(f"\n✓ Total: {total_replaced} print statements replaced")

if __name__ == '__main__':
    main()
