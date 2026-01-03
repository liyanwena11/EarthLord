import Foundation
import Supabase

class AccountService {
    static let shared = AccountService()
    private let supabase = supabaseClient
    private let deleteAccountURL = "https://lkekxzssfrspkyxtqysx.supabase.co/functions/v1/delete-account"

    func deleteAccount() async throws {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔵 [AccountService] 开始删除账户流程")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // 步骤 1: 获取会话
        print("📝 [步骤 1/4] 获取用户会话...")
        guard let session = try? await supabase.auth.session else {
            print("❌ [AccountService] 错误：未找到有效会话")
            throw NSError(domain: "Auth", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "未找到有效会话，请重新登录"
            ])
        }
        print("✅ [步骤 1/4] 会话获取成功")
        print("   ├─ 用户 ID: \(session.user.id)")
        print("   ├─ 邮箱: \(session.user.email ?? "未知")")
        print("   ├─ Token 前缀: \(String(session.accessToken.prefix(30)))...")
        print("   └─ Token 长度: \(session.accessToken.count) 字符")

        // 步骤 2: 构建请求
        print("\n📝 [步骤 2/4] 构建删除请求...")
        guard let url = URL(string: deleteAccountURL) else {
            print("❌ [AccountService] 错误：URL 格式无效")
            throw NSError(domain: "DeleteAccount", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "URL 格式无效"
            ])
        }

        print("🔍 [调试] 完整请求 URL: \(url.absoluteString)")
        print("🔍 [调试] URL Host: \(url.host ?? "无")")
        print("🔍 [调试] URL Path: \(url.path)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        print("✅ [步骤 2/4] 请求构建完成")
        print("   ├─ 方法: POST")
        print("   ├─ Content-Type: application/json")
        print("   ├─ Authorization: Bearer \(String(session.accessToken.prefix(20)))...")
        print("   └─ 请求头数量: \(request.allHTTPHeaderFields?.count ?? 0)")

        // 打印所有请求头
        if let headers = request.allHTTPHeaderFields {
            print("\n🔍 [调试] 完整请求头:")
            for (key, value) in headers {
                if key == "Authorization" {
                    print("   ├─ \(key): Bearer \(String(value.dropFirst(7).prefix(20)))...")
                } else {
                    print("   ├─ \(key): \(value)")
                }
            }
        }

        // 步骤 3: 发送请求
        print("\n📝 [步骤 3/4] 发送请求到 Supabase Edge Function...")
        print("🚀 [调试] 即将发送 HTTP 请求...")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // 步骤 4: 处理响应
            print("\n📝 [步骤 4/4] 处理服务器响应...")

            if let httpResponse = response as? HTTPURLResponse {
                print("📊 [响应详情]")
                print("   ├─ HTTP 状态码: \(httpResponse.statusCode)")
                print("   ├─ 状态描述: \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))")

                // 打印响应头（用于调试）
                print("   ├─ 响应头:")
                for (key, value) in httpResponse.allHeaderFields {
                    print("   │  ├─ \(key): \(value)")
                }

                // 打印响应体（如果有）
                if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                    print("   └─ 响应体: \(responseString)")
                } else {
                    print("   └─ 响应体: [空]")
                }

                // 检查状态码
                switch httpResponse.statusCode {
                case 200...299:
                    print("\n✅ [AccountService] 账户删除成功！")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    return

                case 401:
                    print("\n❌ [AccountService] 授权失败 (401)")
                    print("⚠️  可能的原因：Token 无效或已过期")
                    throw NSError(domain: "DeleteAccount", code: 401, userInfo: [
                        NSLocalizedDescriptionKey: "授权失败，请重新登录",
                        "statusCode": httpResponse.statusCode,
                        "response": String(data: data, encoding: .utf8) ?? "无响应体"
                    ])

                case 404:
                    print("\n❌ [AccountService] 函数未找到 (404)")
                    print("⚠️  可能的原因：")
                    print("   ├─ Edge Function 未部署")
                    print("   ├─ URL 路径错误")
                    print("   └─ 函数已被删除")
                    print("\n💡 解决方案：")
                    print("   cd /Users/lyanwen/Desktop/EarthLord/supabase/functions")
                    print("   supabase functions deploy delete-account --no-verify-jwt")
                    throw NSError(domain: "DeleteAccount", code: 404, userInfo: [
                        NSLocalizedDescriptionKey: "删除账户函数未找到，请联系管理员",
                        "statusCode": httpResponse.statusCode,
                        "url": url.absoluteString
                    ])

                case 500...599:
                    print("\n❌ [AccountService] 服务器错误 (\(httpResponse.statusCode))")
                    throw NSError(domain: "DeleteAccount", code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "服务器错误，请稍后重试",
                        "statusCode": httpResponse.statusCode,
                        "response": String(data: data, encoding: .utf8) ?? "无响应体"
                    ])

                default:
                    print("\n❌ [AccountService] 未知状态码: \(httpResponse.statusCode)")
                    throw NSError(domain: "DeleteAccount", code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "删除失败（状态码：\(httpResponse.statusCode)）",
                        "statusCode": httpResponse.statusCode,
                        "response": String(data: data, encoding: .utf8) ?? "无响应体"
                    ])
                }
            } else {
                print("\n❌ [AccountService] 错误：无法解析 HTTP 响应")
                throw NSError(domain: "DeleteAccount", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "无法解析服务器响应"
                ])
            }

        } catch let error as NSError {
            // 如果错误已经是我们自己抛出的，就直接重新抛出
            if error.domain == "DeleteAccount" || error.domain == "Auth" {
                throw error
            }

            // 否则是网络错误或其他错误
            print("\n❌ [AccountService] 网络请求失败")
            print("   ├─ 错误域: \(error.domain)")
            print("   ├─ 错误代码: \(error.code)")
            print("   ├─ 错误描述: \(error.localizedDescription)")
            print("   └─ 完整错误: \(error)")

            // 如果是网络连接错误
            if error.domain == NSURLErrorDomain {
                print("\n⚠️  网络错误类型分析:")
                switch error.code {
                case NSURLErrorNotConnectedToInternet:
                    print("   └─ 未连接到互联网")
                case NSURLErrorTimedOut:
                    print("   └─ 请求超时")
                case NSURLErrorCannotFindHost:
                    print("   └─ 无法找到主机: \(url.host ?? "未知")")
                case NSURLErrorCannotConnectToHost:
                    print("   └─ 无法连接到主机: \(url.host ?? "未知")")
                default:
                    print("   └─ 其他网络错误 (代码: \(error.code))")
                }
            }

            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            throw error
        }
    }
}
