import Foundation
import Supabase
import GoogleSignIn
import UIKit
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var isSessionChecked = false  // ✅ 新增：标记 session 检查是否完成

    private let supabase = supabaseClient
    static let shared = AuthManager()

    private init() {
        // ✅ 修复：不在 init 中阻塞，改为延迟检查
        Task { @MainActor in
            await checkSession()
        }
    }

    func checkSession() async {
        defer { isSessionChecked = true }  // ✅ 无论成功失败都标记完成
        LogDebug("🔍 [AuthManager] 开始检查 Session...")
        do {
            let session = try await supabase.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
            LogInfo("✅ [AuthManager] Session 检查完成，已登录")
            LogDebug("  - 用户ID: \(session.user.id.uuidString)")
            LogDebug("  - 邮箱: \(session.user.email ?? "无")")
        } catch {
            LogError("⚠️ [AuthManager] Session 检查完成，未登录: \(error.localizedDescription)")
            self.isAuthenticated = false
        }
    }

    func resetState() {
        self.errorMessage = nil
        self.isLoading = false
    }

    // MARK: - 退出登录
    func signOut() async {
        LogDebug("🔴 [AuthManager] 正在执行退出登录...")
        self.isLoading = true
        try? await supabase.auth.signOut()
        GIDSignIn.sharedInstance.signOut() // 确保清除谷歌状态
        self.currentUser = nil
        self.isAuthenticated = false
        self.isLoading = false
    }

    // MARK: - Google 登录
    func signInWithGoogle() async {
        self.isLoading = true
        self.errorMessage = nil
        LogDebug("🔵 [AuthManager] ===== 开始 Google 登录流程 =====")
        do {
            // 1. 获取 RootViewController (Google 登录需要弹窗界面)
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                LogError("❌ [AuthManager] 无法获取 RootViewController")
                self.errorMessage = "系统错误：无法调起登录界面"
                self.isLoading = false
                return
            }
            LogInfo("✅ [AuthManager] RootViewController 获取成功")
            // 2. 执行 Google SDK 登录
            LogDebug("🔄 [AuthManager] 正在调用 Google SDK...")
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            LogInfo("✅ [AuthManager] Google SDK 登录成功")
            // 3. 获取 ID Token
            guard let idToken = result.user.idToken?.tokenString else {
                LogError("❌ [AuthManager] 无法获取 Google ID Token")
                self.errorMessage = "无法从 Google 获取验证信息"
                self.isLoading = false
                return
            }
            LogInfo("✅ [AuthManager] Google ID Token 获取成功")
            // 4. 将 Token 传给 Supabase 进行身份验证
            LogDebug("🔄 [AuthManager] 正在向 Supabase 验证 Google 身份...")
            let response = try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .google, idToken: idToken)
            )

            self.currentUser = response.user
            self.isAuthenticated = true
            LogInfo("✅ [AuthManager] Google 登录成功！")
            LogDebug("  - 用户ID: \(response.user.id.uuidString)")
            LogDebug("  - 邮箱: \(response.user.email ?? "无")")
        } catch {
            LogError("❌ [AuthManager] Google 登录失败: \(error.localizedDescription)")
            LogError("❌ [AuthManager] 错误详情: \(error)")
            self.errorMessage = "Google 登录失败：\(error.localizedDescription)"
        }
        self.isLoading = false
    }



    // MARK: - 账户删除 (保持你原有的逻辑)
    func deleteAccount() async {
        LogDebug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        LogDebug("🔴 [AuthManager] 收到删除账户指令")
        self.isLoading = true
        self.errorMessage = nil

        do {
            try await AccountService.shared.deleteAccount()
            LogInfo("✅ [AuthManager] 云端注销完成，执行本地登出...")
            await signOut()
        } catch let error as NSError {
            LogError("❌ [AuthManager] 删除账户失败: \(error.localizedDescription)")
            self.errorMessage = "注销失败：\(error.localizedDescription)"
            await signOut() // 失败也执行本地登出
        }
        self.isLoading = false
    }

    // MARK: - 邮箱登录
    func signIn(email: String, password: String) async {
        self.isLoading = true
        self.errorMessage = nil
        do {
            let response = try await supabase.auth.signIn(email: email, password: password)
            self.currentUser = response.user
            self.isAuthenticated = true
            LogInfo("✅ [AuthManager] 邮箱登录成功: \(email)")
        } catch {
            // ✅ 显示真实错误原因
            LogError("❌ [AuthManager] 登录失败: \(error)")
            self.errorMessage = "登录失败：\(error.localizedDescription)"
        }
        self.isLoading = false
    }

    // MARK: - 邮箱注册
    func signUp(email: String, password: String) async {
        self.isLoading = true
        self.errorMessage = nil
        do {
            let response = try await supabase.auth.signUp(email: email, password: password)
            self.currentUser = response.user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = "注册失败：\(error.localizedDescription)"
        }
        self.isLoading = false
    }

    // MARK: - Sign in with Apple
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        self.isLoading = true
        self.errorMessage = nil
        do {
            let authorization = try result.get()
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let idToken = String(data: identityTokenData, encoding: .utf8) else {
                self.errorMessage = "无法获取 Apple 验证信息"
                self.isLoading = false
                return
            }
            let response = try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken)
            )
            self.currentUser = response.user
            self.isAuthenticated = true
            LogInfo("✅ [AuthManager] Apple 登录成功: \(self.currentUser?.email ?? "隐藏邮箱")")
        } catch {
            let nsError = error as NSError
            // 用户主动取消不显示错误
            if nsError.domain == ASAuthorizationErrorDomain,
               nsError.code == ASAuthorizationError.canceled.rawValue {
                // ignore
            } else {
                self.errorMessage = "Apple 登录失败"
                LogError("❌ [AuthManager] Apple 登录失败: \(error)")
            }
        }
        self.isLoading = false
    }
}
