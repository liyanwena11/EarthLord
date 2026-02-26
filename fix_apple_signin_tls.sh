#!/bin/bash

# Apple 登录 TLS 错误修复脚本

echo "🔧 修复 Apple 登录 TLS 错误..."
echo ""

INFO_PLIST="/Users/lyanwen/Desktop/EarthLord/EarthLord/Info.plist"

# 备份 Info.plist
cp "$INFO_PLIST" "$INFO_PLIST.backup"
echo "✅ 已备份 Info.plist"

# 使用 plutil 添加 ATS 配置
echo "📝 添加 App Transport Security 配置..."

# 检查是否已有 NSAppTransportSecurity
if plutil -p "$INFO_PLIST" | grep -q "NSAppTransportSecurity"; then
    echo "⚠️  NSAppTransportSecurity 已存在，跳过"
else
    # 添加完整的 ATS 配置
    plutil -insert NSAppTransportSecurity -xml \
        -dict \
        -key NSAllowsArbitraryLoads -bool NO \
        -key NSAllowsLocalNetworking -bool YES \
        -key NSExceptionDomains -xml \
        -dict \
        -key supabase.co -xml \
        -dict \
        -key NSExceptionMinimumTLSVersion -string "TLSv1.2" \
        "$INFO_PLIST"

    echo "✅ ATS 配置已添加"
fi

echo ""
echo "🎯 配置说明："
echo "1. 已启用 Supabase HTTPS 支持 (TLSv1.2)"
echo "2. 已禁用任意 HTTP 加载（安全性）"
echo "3. 已允许本地网络（调试用）"
echo ""
echo "📱 下一步操作："
echo "1. 在 Xcode 中，选择项目文件"
echo "2. 选择 'Info' 标签"
echo "3. 检查 'App Transport Security' 设置"
echo "4. 如果需要，手动添加以下域名例外："
echo "   - supabase.co"
echo "   - lkekxzssfrspkyxtqysx.supabase.co"
echo ""
echo "✅ 修复完成！请重新编译并测试 Apple 登录"
