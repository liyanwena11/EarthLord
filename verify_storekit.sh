#!/bin/bash
# StoreKit 配置验证脚本

echo "🔍 检查 StoreKit 配置..."
echo ""

PROJECT_DIR="/Users/lyanwen/Desktop/EarthLord"
STOREKIT_FILE="$PROJECT_DIR/EarthLord/EarthLord.storekit"

# 检查文件是否存在
if [ -f "$STOREKIT_FILE" ]; then
    echo "✅ .storekit 文件存在: $STOREKIT_FILE"
    ls -lh "$STOREKIT_FILE"
else
    echo "❌ .storekit 文件不存在"
    exit 1
fi

echo ""
echo "📋 文件内容验证:"
plutil -lint "$STOREKIT_FILE"

echo ""
echo "📊 产品数量统计:"
grep -c "<key>identifier</key>" "$STOREKIT_FILE"
echo "个产品 ID"

echo ""
echo "✅ 验证完成！"
echo ""
echo "📝 下一步操作："
echo "1. 完全退出 Xcode"
echo "2. 删除 ~/Library/Developer/Xcode/DerivedData 中的 EarthLord 文件夹"
echo "3. 重新打开项目"
echo "4. Product → Clean Build Folder"
echo "5. 重新运行应用"
