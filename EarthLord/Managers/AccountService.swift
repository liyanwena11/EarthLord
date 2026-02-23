import Foundation
import Supabase

class AccountService {
    static let shared = AccountService()
    private let supabase = supabaseClient
    private let deleteAccountURL = "https://lkekxzssfrspkyxtqysx.supabase.co/functions/v1/delete-account"

    func deleteAccount() async throws {
        LogInfo("开始删除账户流程")

        guard let session = try? await supabase.auth.session else {
            LogError("未找到有效会话")
            throw NSError(domain: "Auth", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "未找到有效会话，请重新登录"
            ])
        }
        LogDebug("会话获取成功 - 用户ID: \(session.user.id)")

        guard let url = URL(string: deleteAccountURL) else {
            LogError("URL 格式无效")
            throw NSError(domain: "DeleteAccount", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "URL 格式无效"
            ])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                LogDebug("HTTP状态码: \(httpResponse.statusCode)")

                if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                    LogDebug("响应体: \(responseString)")
                }

                switch httpResponse.statusCode {
                case 200...299:
                    LogInfo("账户删除成功")
                    return

                case 401:
                    LogError("授权失败 (401)")
                    throw NSError(domain: "DeleteAccount", code: 401, userInfo: [
                        NSLocalizedDescriptionKey: "授权失败，请重新登录",
                        "statusCode": httpResponse.statusCode,
                        "response": String(data: data, encoding: .utf8) ?? "无响应体"
                    ])

                case 404:
                    LogError("删除账户函数未找到 (404)")
                    throw NSError(domain: "DeleteAccount", code: 404, userInfo: [
                        NSLocalizedDescriptionKey: "删除账户函数未找到，请联系管理员",
                        "statusCode": httpResponse.statusCode,
                        "url": url.absoluteString
                    ])

                case 500...599:
                    LogError("服务器错误 (\(httpResponse.statusCode))")
                    throw NSError(domain: "DeleteAccount", code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "服务器错误，请稍后重试",
                        "statusCode": httpResponse.statusCode,
                        "response": String(data: data, encoding: .utf8) ?? "无响应体"
                    ])

                default:
                    LogError("未知状态码: \(httpResponse.statusCode)")
                    throw NSError(domain: "DeleteAccount", code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "删除失败（状态码：\(httpResponse.statusCode)）",
                        "statusCode": httpResponse.statusCode,
                        "response": String(data: data, encoding: .utf8) ?? "无响应体"
                    ])
                }
            } else {
                LogError("无法解析 HTTP 响应")
                throw NSError(domain: "DeleteAccount", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "无法解析服务器响应"
                ])
            }

        } catch let error as NSError {
            if error.domain == "DeleteAccount" || error.domain == "Auth" {
                throw error
            }

            LogError("网络请求失败: \(error.localizedDescription)")
            throw error
        }
    }
}
