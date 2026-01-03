import Foundation
import Supabase

// Supabase 配置
// 项目：EarthLord (lkekxzssfrspkyxtqysx)
// 区域：ap-southeast-1
let supabaseClient = SupabaseClient(
    supabaseURL: URL(string: "https://lkekxzssfrspkyxtqysx.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxrZWt4enNzZnJzcGt5eHRxeXN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcxMDAwNjUsImV4cCI6MjA4MjY3NjA2NX0.cqQjlAIdQIcRjXvRUtjc02h3CsdxV383WE9PofNc6iM",
    options: SupabaseClientOptions(
        auth: .init(
            emitLocalSessionAsInitialSession: true
        )
    )
)

