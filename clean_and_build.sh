#!/bin/bash

# 清理 Xcode 缓存并重新编译

echo "🧹 清理 Xcode 缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/EarthLord-*
rm -rf .build

echo "✅ 缓存清理完成！"
echo ""
echo "📝 接下来请在 Xcode 中执行以下操作："
echo ""
echo "1. 打开 EarthLord.xcodeproj"
echo "2. 按 Cmd+Shift+K (Clean Build Folder)"
echo "3. 按 Cmd+B (Build)"
echo "4. 如果还有错误，请重启 Xcode"
echo ""
echo "如果还是报错，请把完整的错误信息发给我！"
