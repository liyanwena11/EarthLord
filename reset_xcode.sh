#!/bin/bash
# Xcode 清理和重置脚本

echo "🧹 开始清理 Xcode 缓存和派生数据..."
echo ""

# 关闭 Xcode
echo "1️⃣  关闭 Xcode..."
killall Xcode 2>/dev/null
sleep 2

# 清理 DerivedData
echo "2️⃣  清理派生数据..."
DERIVED_DATA=~/Library/Developer/Xcode/DerivedData
if [ -d "$DERIVED_DATA" ]; then
    find "$DERIVED_DATA" -name "EarthLord-*" -type d -exec rm -rf {} + 2>/dev/null
    echo "   ✅ 已清理 DerivedData 中的 EarthLord 文件"
fi

# 清理构建���件夹
echo "3️⃣  清理项目构建文件夹..."
if [ -d "/Users/lyanwen/Desktop/EarthLord/build" ]; then
    rm -rf "/Users/lyanwen/Desktop/EarthLord/build"
    echo "   ✅ 已清理 build 文件夹"
fi

# 清理 Xcode 缓存
echo "4️⃣  清理 Xcode 缓存..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode 2>/dev/null
echo "   ✅ 已清理 Xcode 缓存"

echo ""
echo "✅ 清理完成！"
echo ""
echo "📝 下一步操作："
echo "1. 打开 EarthLord.xcodeproj"
echo "2. 选择 Product → Clean Build Folder (Shift+Cmd+K)"
echo "3. 按 Cmd+R 运行应用"
echo "4. 查看控制台是否显示：🔧 [IAP] 检测到本地 StoreKit 测试模式"
echo ""
