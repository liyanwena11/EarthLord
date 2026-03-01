#!/usr/bin/env python3
"""
验证 Localizable.xcstrings 翻译完整性
"""
import json

def main():
    with open('Localizable.xcstrings', 'r') as f:
        data = json.load(f)

    strings = data.get('strings', {})

    total_zh = 0
    total_en = 0
    missing_en = []
    translated_en = 0
    needs_review_en = 0

    for key, value in strings.items():
        localizations = value.get('localizations', {})

        # 检查中文
        if 'zh-Hans' in localizations:
            zh_value = localizations['zh-Hans'].get('stringUnit', {}).get('value', '')
            if zh_value:
                total_zh += 1

                # 检查英文
                if 'en' not in localizations:
                    missing_en.append((key, zh_value))
                else:
                    total_en += 1
                    en_state = localizations['en'].get('stringUnit', {}).get('state', '')
                    if en_state == 'translated':
                        translated_en += 1
                    elif en_state == 'needs_review':
                        needs_review_en += 1

    print("=" * 60)
    print("Localizable.xcstrings 翻译统计")
    print("=" * 60)
    print(f"\n📊 总体统计:")
    print(f"  中文条目总数: {total_zh}")
    print(f"  英文条目总数: {total_en}")
    print(f"  缺失英文: {len(missing_en)}")
    print(f"\n📝 英文翻译状态:")
    print(f"  已翻译 (translated): {translated_en}")
    print(f"  需审查 (needs_review): {needs_review_en}")
    print(f"  其他状态: {total_en - translated_en - needs_review_en}")
    print(f"\n✅ 翻译完成度:")
    if total_zh > 0:
        print(f"  按条目计算: {total_en * 100 // total_zh}%")
        print(f"  按translated计算: {translated_en * 100 // total_zh}%")

    if missing_en:
        print(f"\n⚠️  缺失英文翻译的 key (前10个):")
        for key, zh in missing_en[:10]:
            display = zh[:50] + "..." if len(zh) > 50 else zh
            print(f"  - {display}")

    print("\n" + "=" * 60)
    print("💡 提示:")
    print("  如果 Xcode 显示的百分比与上述不符，请尝试:")
    print("  1. 在 Xcode 中: Product > Clean Build Folder (Shift+Cmd+K)")
    print("  2. 重启 Xcode")
    print("  3. 在 Xcode 中打开 Localizable.xcstrings 文件查看")
    print("=" * 60)

if __name__ == '__main__':
    main()
