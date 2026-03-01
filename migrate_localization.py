#!/usr/bin/env python3
"""
将 .localized 迁移到 String(localized:)
这样 Xcode 才能正确识别翻译
"""
import os
import re
import sys

def migrate_file(filepath):
    """迁移单个文件"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"  ⚠️  无法读取 {filepath}: {e}")
        return False

    original_content = content
    changes = []

    # 匹配 "xxx".localized（但不包括 xxx.localizedDescription）
    # 使用负向后查找，确保前面不是 .
    pattern = r'(?<!\.)(?<!\w)"([^"\.\[\]]+)"\.localized'

    for match in re.finditer(pattern, content):
        string_literal = match.group(0)
        chinese_text = match.group(1)

        # 跳过一些特殊情况
        if chinese_text.startswith('%'):  # 跳过格式化字符串
            continue
        if '.' in chinese_text:  # 跳过包含 . 的（如 error.xxx）
            continue

        # 替换
        new_text = f'String(localized: "{chinese_text}")'
        content = content.replace(string_literal, new_text, 1)
        changes.append((string_literal, new_text))

    if content != original_content:
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True, changes
        except Exception as e:
            print(f"  ❌ 无法写入 {filepath}: {e}")
            return False, []
    return False, []

def main():
    print("🔄 开始迁移 .localized 到 String(localized:)...\n")

    total_files = 0
    total_changes = 0
    failed_files = []

    for root, dirs, files in os.walk('EarthLord'):
        dirs[:] = [d for d in dirs if d not in ['Build', 'DerivedData', '.git', 'xcuserdata']]

        for file in files:
            if file.endswith('.swift'):
                filepath = os.path.join(root, file)
                changed, changes = migrate_file(filepath)

                if changed:
                    total_files += 1
                    total_changes += len(changes)
                    relative_path = filepath.replace('EarthLord/', '')
                    print(f"  ✓ {relative_path} ({len(changes)} 处修改)")
                elif changes is False:  # 出错
                    failed_files.append(filepath)

    print(f"\n{'='*60}")
    print(f"✅ 迁移完成！")
    print(f"   修改文件: {total_files}")
    print(f"   修改总数: {total_changes}")

    if failed_files:
        print(f"\n⚠️  失败文件: {len(failed_files)}")
        for f in failed_files:
            print(f"   - {f}")

    print(f"\n{'='*60}")
    print(f"📝 下一步:")
    print(f"   1. 运行: xcodebuild -scheme EarthLord build")
    print(f"   2. 检查编译是否成功")
    print(f"   3. 在 Xcode 中打开 Localizable.xcstrings")
    print(f"   4. 如果有问题，运行: git reset --hard HEAD")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
