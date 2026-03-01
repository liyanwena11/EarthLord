import os
import re

def test_pattern():
    # 测试一些实际的代码片��
    test_cases = [
        ('Text("任务中心".localized)', '应该被替换'),
        ('error.localizedDescription', '不应该被替换'),
        ('"加入时间:".localized', '应该被替换'),
        ('"退出登录".localized', '应该被替换'),
        ('LogDebug("xxx")', '不应该被替换'),
    ]

    pattern = r'(?<!\.)(?<!\w)"([^"\.\[\]]+)"\.localized'

    for code, description in test_cases:
        matches = re.findall(pattern, code)
        print(f"{description}:")
        print(f"  代码: {code}")
        print(f"  匹配: {matches}")
        print()

test_pattern()
