#!/bin/bash

echo "🧹 清理 Xcode 缓���..."

# 删除 DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/EarthLord-*

# 清理项目构建文件夹
if [ -d "build" ]; then
    rm -rf build
    echo "✅ 已删除 build 文件夹"
fi

# 清理 Xcode 用户数据
if [ -d "*.xcuserstate" ]; then
    rm -rf *.xcuserstate
fi

# 清理 xcuserdata
find . -name "xcuserdata" -type d -exec rm -rf {} + 2>/dev/null

echo "✅ Xcode 缓存清理完成！"
echo "请在 Xcode 中执行: Product > Clean Build Folder (⇧⌘K)"
