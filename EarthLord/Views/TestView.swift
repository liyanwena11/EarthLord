import SwiftUI

#if DEBUG
import Supabase

struct TestView: View {
    @State private var connectionStatus = "等待测试..."
    @State private var statusColor = Color.gray
    @State private var isLoading = false
    
    // 这里填你的 Supabase URL 和 Key
    let supabaseUrl = "https://lkekxzssfrspkyxtqysx.supabase.co" // 记得换成真的
    let supabaseKey = "sb_publishable_8Gg8z5XRTOkupYVm6MbACg_Lc9CXU4I" // 记得换成真的

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(.system(size: 60))
                .foregroundColor(statusColor)
            
            Text("Supabase 连接测试")
                .font(.title2)
                .bold()
            
            // 状态显示卡片
            VStack(alignment: .leading, spacing: 10) {
                Text(connectionStatus)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            if isLoading {
                ProgressView()
            }
            
            Button(action: testConnection) {
                Text("测试连接")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    func testConnection() {
        isLoading = true
        connectionStatus = "正在连接..."
        statusColor = .yellow
        
        Task {
            do {
                let client = SupabaseClient(
                    supabaseURL: URL(string: supabaseUrl)!,
                    supabaseKey: supabaseKey
                )
                
                // 尝试简单的健康检查或查询
                let _ = try await client
                    .from("non_existent_table") // 故意查个不存在的表也没事，只要服务器回话了就算通
                    .select()
                    .execute()
                
                // 如果能走到这里，说明网络通了（即使报错表不存在）
                isLoading = false
                connectionStatus = "✅ 连接成功 (服务器已响应)"
                statusColor = .green
                
            } catch {
                isLoading = false
                // 只要报错里包含 PostgrestError，说明连上服务器了，只是没表
                let errorString = String(describing: error)
                if errorString.contains("PostgrestError") {
                    connectionStatus = "✅ 连接成功 (服务器已响应)\n说明: 收到 PostgrestError 表示服务器正常工作，只是查询的表不存在。"
                    statusColor = .green
                } else {
                    connectionStatus = "❌ 连接失败: \(error.localizedDescription)"
                    statusColor = .red
                }
            }
        }
    }
}

#Preview {
    TestView()
}
#endif
