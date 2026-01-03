#!/bin/bash

# 部署 delete-account 边缘函数到 Supabase
# 使用方法: ./deploy.sh

PROJECT_REF="lkekxzssfrspkyxtqysx"

echo "🚀 开始部署 delete-account 边缘函数..."

# 检查是否安装了 Supabase CLI
if ! command -v supabase &> /dev/null; then
    echo "❌ 未检测到 Supabase CLI"
    echo "请先安装: brew install supabase/tap/supabase"
    exit 1
fi

# 检查是否已登录
if ! supabase projects list &> /dev/null; then
    echo "📝 请先登录 Supabase..."
    supabase login
fi

# 链接到项目（如果尚未链接）
echo "🔗 链接到项目..."
supabase link --project-ref $PROJECT_REF 2>/dev/null || echo "已链接"

# 部署函数
echo "📤 部署函数..."
supabase functions deploy delete-account --no-verify-jwt

if [ $? -eq 0 ]; then
    echo "✅ 部署成功！"
    echo "函数 URL: https://$PROJECT_REF.supabase.co/functions/v1/delete-account"
else
    echo "❌ 部署失败"
    exit 1
fi
