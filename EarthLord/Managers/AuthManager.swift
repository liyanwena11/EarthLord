import Foundation
import Supabase
import GoogleSignIn
import UIKit
import AuthenticationServices // 必须导入，用于 Apple 登录

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let supabase = supabaseClient
    static let shared = AuthManager()

    private init() { Task { await checkSession() } }

    func checkSession() async {
        if let session = try? await supabase.auth.session {
            self.currentUser = session.user
            self.isAuthenticated = true
        }
    }

    func resetState() {
        self.errorMessage = nil
        self.isLoading = false
    }

    // MARK: - 退出登录
    func signOut() async {
        print("🔴 [AuthManager] 正在执行退出登录...")
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
        print("🔵 [AuthManager] 开始 Google 登录流程...")

        do {
            // 1. 获取 RootViewController (Google 登录需要弹窗界面)
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                print("❌ [AuthManager] 无法获取 RootViewController")
                self.errorMessage = "系统错误：无法调起登录界面"
                self.isLoading = false
                return
            }

            // 2. 执行 Google SDK 登录
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            // 3. 获取 ID Token
            guard let idToken = result.user.idToken?.tokenString else {
                print("❌ [AuthManager] 无法获取 Google ID Token")
                self.errorMessage = "无法从 Google 获取验证信息"
                self.isLoading = false
                return
            }

            // 4. 将 Token 传给 Supabase 进行身份验证
            print("🔄 [AuthManager] 正在向 Supabase 验证 Google 身份...")
            let response = try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .google, idToken: idToken)
            )

            self.currentUser = response.user
            self.isAuthenticated = true
            print("✅ [AuthManager] Google 登录成功！用户: \(self.currentUser?.email ?? "")")

        } catch {
            print("❌ [AuthManager] Google 登录失败: \(error.localizedDescription)")
            self.errorMessage = "Google 登录失败"
        }
        self.isLoading = false
    }

    // MARK: - Apple 登录 (简单实现方案)
    func signInWithApple() async {
        // 注意：Apple 登录在 iOS 上通常配合 SignInWithAppleButton 使用效果更好
        // 这里提供一个逻辑入口，你需要在 View 中使用相应组件获取 Token 后传给此方法
        print("🔵 [AuthManager] Apple 登录功能已准备就绪，等待 Token 接入")
        self.errorMessage = "请在真机上测试 Apple 登录"
    }

    // MARK: - 账户删除 (保持你原有的逻辑)
    func deleteAccount() async {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔴 [AuthManager] 收到删除账户指令")
        self.isLoading = true
        self.errorMessage = nil

        do {
            try await AccountService.shared.deleteAccount()
            print("✅ [AuthManager] 云端注销完成，执行本地登出...")
            await signOut()
        } catch let error as NSError {
            print("❌ [AuthManager] 删除账户失败: \(error.localizedDescription)")
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
        } catch {
            self.errorMessage = "登录失败：邮箱或密码错误"
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
}
