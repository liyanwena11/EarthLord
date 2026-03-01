#!/usr/bin/env python3
"""
预览 .localized 到 String(localized:) 的迁移
显示将要修改的内容，但不实际修改文件
"""
import os
import re

def preview_migration():
    """预览将要迁移的内容"""
    pattern = r'(?<!\.)(?<!\w)"([^"\.\[\]]+)"\.localized'

    changes_by_file = {}

    print("🔍 扫描代码中需要迁移的 .localized 用法...\n")

    for root, dirs, files in os.walk('EarthLord'):
        dirs[:] = [d for d in dirs if d not in ['Build', 'DerivedData', '.git', 'xcuserdata']]

        for file in files:
            if file.endswith('.swift'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()

                    matches = re.finditer(pattern, content)
                    file_changes = []

                    for match in matches:
                        original = match.group(0)
                        chinese_text = match.group(1)

                        if chinese_text.startswith('%'):  # 跳过格式化字符串
                            continue

                        new_text = f'String(localized: "{chinese_text}")'
                        file_changes.append((original, new_text))

                    if file_changes:
                        changes_by_file[filepath] = file_changes

                except Exception as e:
                    print(f"Error reading {filepath}: {e}")

    # 显示结果
    total_changes = sum(len(changes) for changes in changes_by_file.values())
    print(f"📊 统计:")
    print(f"   文件数: {len(changes_by_file)}")
    print(f"   修改数: {total_changes}\n")

    # 显示每个文件的修改预览
    print(f"📝 将要修改的文件 (前10个):\n")
    for i, (filepath, changes) in enumerate(list(changes_by_file.items())[:10]):
        print(f"{i+1}. {filepath.replace('EarthLord/', '')}")
        for original, new in changes[:3]:  # 每个文件显示前3个修改
            print(f"   - {original}")
            print(f"   + {new}")
        if len(changes) > 3:
            print(f"   ... 还有 {len(changes) - 3} 处修改")
        print()

    if len(changes_by_file) > 10:
        print(f"... 还有 {len(changes_by_file) - 10} 个文件需要修改\n")

    return changes_by_file

if __name__ == '__main__':
    changes = preview_migration()
    print("\n" + "="*60)
    print("💡 提示:")
    print("   这是预览模式，没有实际修改文件")
    print("   如果确认要迁移，请运行 migrate_localization.py")
    print("="*60)
