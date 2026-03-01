#!/usr/bin/env python3
"""
扫描项目中实际使用的本地化字符串
"""
import json
import os
import re

def main():
    # 读取翻译文件
    with open('Localizable.xcstrings', 'r') as f:
        data = json.load(f)

    strings = data.get('strings', {})

    # 获取所有中文翻译的 key
    all_keys = set()
    for key, value in strings.items():
        localizations = value.get('localizations', {})
        if 'zh-Hans' in localizations:
            zh_value = localizations['zh-Hans'].get('stringUnit', {}).get('value', '')
            if zh_value:
                all_keys.add(zh_value)

    print(f"Localizable.xcstrings 中共有 {len(all_keys)} 个翻译 key\n")

    # 在源代码中搜索这些 key
    def find_keys_in_source(keys, source_dir):
        """在源代码中查找被使用的 key"""
        found_keys = set()

        for root, dirs, files in os.walk(source_dir):
            # 跳过不需要的目录
            dirs[:] = [d for d in dirs if d not in ['Build', 'DerivedData', '.git', 'xcuserdata']]

            for file in files:
                if file.endswith('.swift'):
                    filepath = os.path.join(root, file)
                    try:
                        with open(filepath, 'r', encoding='utf-8') as f:
                            content = f.read()

                            # 检查每个 key
                            for key in keys:
                                # 转义特殊字符
                                escaped_key = re.escape(key)
                                # 匹配 .localized 方式
                                if re.search(rf'"{escaped_key}"\.localized', content):
                                    found_keys.add(key)
                                # 匹配 String(localized:) 方式
                                elif re.search(rf'String\(localized:\s*"{escaped_key}"\)', content):
                                    found_keys.add(key)
                                # 匹配 LocalizedStringKey 方式
                                elif re.search(rf'LocalizedStringKey\("{escaped_key}"\)', content):
                                    found_keys.add(key)
                                # 匹配 Text() 直接使用
                                elif re.search(rf'Text\("{escaped_key}"\)', content):
                                    found_keys.add(key)
                                # 匹配 NSLocalizedString
                                elif re.search(rf'NSLocalizedString\("{escaped_key}"', content):
                                    found_keys.add(key)
                    except Exception as e:
                        print(f"Error reading {filepath}: {e}")

        return found_keys

    # 在项目中搜索
    print("正在扫描源代码...")
    found = find_keys_in_source(all_keys, 'EarthLord')

    print(f"\n✅ 在源代码中找到 {len(found)} 个被使用的翻译 key")
    print(f"❌ 未被使用的翻译 key: {len(all_keys) - len(found)}")

    # 显示使用统计
    if len(all_keys) > 0:
        usage_percent = len(found) * 100 // len(all_keys)
        print(f"\n📊 使用率: {usage_percent}%")

    # 显示一些被使用的 key
    if found:
        print(f"\n✅ 被使用的翻译示例 (前10个):")
        for key in list(found)[:10]:
            print(f"  ✓ {key}")

    # 显示未被使用的 key
    unused = all_keys - found
    if unused:
        print(f"\n❌ 未被使用的翻译示例 (前20个):")
        for key in list(unused)[:20]:
            print(f"  - {key}")

    return found, unused

if __name__ == '__main__':
    main()
