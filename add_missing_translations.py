#!/usr/bin/env python3
"""
扫描源代码并添加缺失的翻译到 Localizable.xcstrings
"""
import json
import os
import re

def scan_source_code_for_strings():
    """扫描源代码中使用的所有字符串"""
    found_strings = {}

    # 匹配 String(localized: "xxx")
    pattern1 = re.compile(r'String\(localized:\s*"([^"]+)"\)')
    # 匹配 NSLocalizedString("xxx", comment:)
    pattern2 = re.compile(r'NSLocalizedString\("([^"]+)",\s*comment:')
    # 匹配 Text(LocalizedStringKey("xxx"))
    pattern3 = re.compile(r'LocalizedStringKey\("([^"]+)"\)')

    for root, dirs, files in os.walk('EarthLord'):
        dirs[:] = [d for d in dirs if d not in ['Build', 'DerivedData', '.git', 'xcuserdata']]

        for file in files:
            if file.endswith('.swift'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()

                        for pattern in [pattern1, pattern2, pattern3]:
                            for match in pattern.finditer(content):
                                key = match.group(1)
                                if key not in found_strings:
                                    found_strings[key] = []
                                found_strings[key].append(filepath)
                except:
                    pass

    return found_strings

def main():
    print("🔍 扫描源代码中的本地化字符串...\n")

    # 扫描源代码
    used_strings = scan_source_code_for_strings()
    print(f"✅ 在源代码中找到 {len(used_strings)} 个唯一字符串\n")

    # 读取现有的 Localizable.xcstrings
    with open('Localizable.xcstrings', 'r') as f:
        data = json.load(f)

    existing_strings = data.get('strings', {})

    # 找出在源代码中使用但在 xcstrings 中缺失的
    missing = []
    for key in used_strings.keys():
        if key not in existing_strings:
            missing.append(key)

    print(f"📝 缺失的翻译条目: {len(missing)} 个\n")

    if missing:
        # 添加缺失的条目
        translations = {
            "%1$@  (~%2$@x)": {"zh": "%1$@  (~%2$@x)", "en": "%1$@  (~%2$@x)"},
            "%1$@ · %2$@": {"zh": "%1$@ · %2$@", "en": "%1$@ · %2$@"},
            "%1$@ (×%2$lld)": {"zh": "%1$@ (×%2$lld)", "en": "%1$@ (×%2$lld)"},
            "%1$@ / %2$lld kg": {"zh": "%1$@ / %2$lld kg", "en": "%1$@ / %2$lld kg"},
            "%1$@ ×%2$lld": {"zh": "%1$@ ×%2$lld", "en": "%1$@ ×%2$lld"},
            "%1$@ x%2$lld": {"zh": "%1$@ x%2$lld", "en": "%1$@ x%2$lld"},
            "%1$@ 开始建造，预计 %2$@ 后完成": {"zh": "%1$@ 开始建造，预计 %2$@ 后完成", "en": "%1$@ started, ETA: %2$@"},
            "%1$@: %2$lld": {"zh": "%1$@: %2$lld", "en": "%1$@: %2$lld"},
            "%1$lld / %2$lld": {"zh": "%1$lld / %2$lld", "en": "%1$lld / %2$lld"},
            "%1$lld/%2$lld": {"zh": "%1$lld/%2$lld", "en": "%1$lld/%2$lld"},
            "%1$lld%2$@": {"zh": "%1$lld%2$@", "en": "%1$lld%2$@"},
            "📦 %1$@ ×%2$lld": {"zh": "📦 %1$@ ×%2$lld", "en": "📦 %1$@ ×%2$lld"},
            "你将给出：%1$@\n\n你将获得：%2$@\n\n确认接受此交易？物品将立即转移。": {
                "zh": "你将给出：%1$@\n\n你将获得：%2$@\n\n确认接受此交易？物品将立即转移。",
                "en": "You will give: %1$@\n\nYou will receive: %2$@\n\nConfirm to accept this trade? Items will be transferred immediately."
            },
            "已建 %1$lld / 最多 %2$lld 个": {"zh": "已建 %1$lld / 最多 %2$lld 个", "en": "Built %1$lld / Max %2$lld"},
            "已选择位置：%1$@, %2$@": {"zh": "已选择位置：%1$@, %2$@", "en": "Selected: %1$@, %2$@"},
            "有效期: %1$lld 天 (%2$@)": {"zh": "有效期: %1$lld 天 (%2$@)", "en": "Valid: %1$lld days (%2$@)"},
            "期望 %1$@ (~%2$@x)": {"zh": "期望 %1$@ (~%2$@x)", "en": "Expected %1$@ (~%2$@x)"},
            "确定要将「%1$@」升级到 Lv.%2$lld 吗？": {"zh": "确定要将「%1$@」升级到 Lv.%2$lld 吗？", "en": "Upgrade \"%1$@\" to Lv.%2$lld?"},
            "确定要收集 %1$@ x%2$lld 吗？": {"zh": "确定要收集 %1$@ x%2$lld 吗？", "en": "Collect %1$@ x%2$lld?"},
            "确认花费 %1$@ 购买 %2$@？\n\n购买后物品将发送到待领取，请及时领取。": {
                "zh": "确认花费 %1$@ 购买 %2$@？\n\n购买后物品将发送到待领取，请及时领取。",
                "en": "Spend %1$@ to buy %2$@?\n\nItems will be sent to mailbox. Collect them promptly."
            },
            "背包容量: %1$lld/%2$lld": {"zh": "背包容量: %1$lld/%2$lld", "en": "Backpack: %1$lld/%2$lld"},
            "采样 %1$lld/%2$lld": {"zh": "采样 %1$lld/%2$lld", "en": "Sampling %1$lld/%2$lld"},
        }

        added = 0
        for key in missing:
            if key in translations:
                zh = translations[key]["zh"]
                en = translations[key]["en"]

                # 添加新条目
                data["strings"][key] = {
                    "localizations": {
                        "zh-Hans": {
                            "stringUnit": {
                                "state": "translated",
                                "value": zh
                            }
                        },
                        "en": {
                            "stringUnit": {
                                "state": "translated",
                                "value": en
                            }
                        }
                    }
                }
                added += 1
                print(f"  ✓ {zh[:50]}")

        # 保存
        with open('Localizable.xcstrings', 'w') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"\n✅ 成功添加 {added} 个新翻译")
    else:
        print("✅ 所有源代码中的字符串都已在 xcstrings 中")

if __name__ == '__main__':
    main()
