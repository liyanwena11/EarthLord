//
//  AuthManager.swift
//  EarthLord
//
//  Created by lyanwen on 2025/12/31.
//

import Foundation
import Supabase

/// 认证管理器
/// 负责管理用户认证流程，包括注册、登录、找回密码等功能
@MainActor
class AuthManager: ObservableObject {

    // MARK: - Published Properties

    /// 是否已完成认证（已登录且完成所有必要流程）
    @Published var isAuthenticated: Bool = false

    /// 是否需要设置密码（OTP验证后必须设置密码才能进入主页）
    @Published var needsPasswordSetup: Bool = false

    /// 当前登录用户
    @Published var currentUser: User? = nil

    /// 是否正在加载
    @Published var isLoading: Bool = false

    /// 错误信息
    @Published var errorMessage: String? = nil

    /// OTP 是否已发送
    @Published var otpSent: Bool = false

    /// OTP 是否已验证（验证码已验证，等待设置密码）
    @Published var otpVerified: Bool = false

    // MARK: - Private Properties

    /// Supabase 客户端
    private let supabase = supabaseClient

    /// 认证状态监听任务
    private var authStateTask: Task<Void, Never>?

    // MARK: - Singleton

    /// 单例实例
    static let shared = AuthManager()

    private init() {
        // 初始化时检查会话
        Task {
            await checkSession()
            await setupAuthStateListener()
        }
    }

    deinit {
        // 清理监听任务
        authStateTask?.cancel()
    }

    // MARK: - Session Management

    /// 检查当前会话状态
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            currentUser = session.user

            // 如果有会话，说明用户已登录
            // 但需要检查是否已设置密码（通过检查用户元数据或其他方式）
            isAuthenticated = true
            needsPasswordSetup = false

        } catch {
            // 没有有效会话
            currentUser = nil
            isAuthenticated = false
            needsPasswordSetup = false
        }
    }

    /// 设置认证状态监听
    /// 监听 Supabase 认证状态变化，自动更新应用状态
    private func setupAuthStateListener() async {
        authStateTask = Task {
            for await state in await supabase.auth.authStateChanges {
                await MainActor.run {
                    switch state.event {
                    case .signedIn:
                        // 用户登录
                        currentUser = state.session?.user

                        // 如果不需要设置密码，则认证完成
                        if !needsPasswordSetup {
                            isAuthenticated = true
                        }

                        print("🔐 用户已登录: \(state.session?.user.email ?? "未知")")

                    case .signedOut:
                        // 用户退出
                        currentUser = nil
                        isAuthenticated = false
                        needsPasswordSetup = false
                        otpSent = false
                        otpVerified = false

                        print("🔓 用户已退出")

                    case .tokenRefreshed:
                        // Token 刷新
                        currentUser = state.session?.user
                        print("🔄 Token 已刷新")

                    case .userUpdated:
                        // 用户信息更新
                        currentUser = state.session?.user
                        print("👤 用户信息已更新")

                    case .passwordRecovery:
                        // 密码恢复流程
                        print("🔑 进入密码恢复流程")

                    default:
                        break
                    }
                }
            }
        }
    }

    // MARK: - Registration Flow

    /// 发送注册验证码
    /// - Parameter email: 用户邮箱
    func sendRegisterOTP(email: String) async {
        isLoading = true
        errorMessage = nil
        otpSent = false

        do {
            // 发送 OTP，允许创建新用户
            try await supabase.auth.signInWithOTP(
                email: email,
                shouldCreateUser: true
            )

            // 成功发送
            otpSent = true
            errorMessage = nil

        } catch {
            // 发送失败
            errorMessage = "发送验证码失败：\(error.localizedDescription)"
            otpSent = false
        }

        isLoading = false
    }

    /// 验证注册验证码
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - code: 验证码
    /// - Note: 验证成功后用户已登录，但必须设置密码才能进入主页
    func verifyRegisterOTP(email: String, code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 验证 OTP
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .email
            )

            // 验证成功，用户已登录
            currentUser = session.user
            otpVerified = true
            needsPasswordSetup = true  // 必须设置密码
            isAuthenticated = false     // 但尚未完成完整流程
            errorMessage = nil

        } catch {
            // 验证失败
            errorMessage = "验证码错误：\(error.localizedDescription)"
            otpVerified = false
        }

        isLoading = false
    }

    /// 完成注册（设置密码）
    /// - Parameter password: 用户密码
    /// - Note: 此方法在 OTP 验证成功后调用，完成注册流程
    func completeRegistration(password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 更新用户密码
            _ = try await supabase.auth.update(
                user: UserAttributes(
                    password: password
                )
            )

            // 注册完成
            needsPasswordSetup = false
            isAuthenticated = true
            errorMessage = nil

        } catch {
            // 设置密码失败
            errorMessage = "设置密码失败：\(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Sign In

    /// 登录（邮箱 + 密码）
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - password: 用户密码
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 使用邮箱和密码登录
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            // 登录成功
            currentUser = session.user
            isAuthenticated = true
            needsPasswordSetup = false
            errorMessage = nil

        } catch {
            // 登录失败
            errorMessage = "登录失败：\(error.localizedDescription)"
            isAuthenticated = false
        }

        isLoading = false
    }

    // MARK: - Password Reset Flow

    /// 发送找回密码验证码
    /// - Parameter email: 用户邮箱
    func sendResetOTP(email: String) async {
        isLoading = true
        errorMessage = nil
        otpSent = false

        do {
            // 发送密码重置邮件
            try await supabase.auth.resetPasswordForEmail(email)

            // 成功发送
            otpSent = true
            errorMessage = nil

        } catch {
            // 发送失败
            errorMessage = "发送验证码失败：\(error.localizedDescription)"
            otpSent = false
        }

        isLoading = false
    }

    /// 验证找回密码验证码
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - code: 验证码
    /// - Note: 验证成功后用户已登录，需要设置新密码
    func verifyResetOTP(email: String, code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 验证 OTP（使用 recovery 类型）
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .recovery  // ⚠️ 注意：找回密码使用 .recovery 类型
            )

            // 验证成功，用户已登录
            currentUser = session.user
            otpVerified = true
            needsPasswordSetup = true  // 需要设置新密码
            isAuthenticated = false     // 但尚未完成完整流程
            errorMessage = nil

        } catch {
            // 验证失败
            errorMessage = "验证码错误：\(error.localizedDescription)"
            otpVerified = false
        }

        isLoading = false
    }

    /// 重置密码（设置新密码）
    /// - Parameter newPassword: 新密码
    /// - Note: 此方法在找回密码 OTP 验证成功后调用
    func resetPassword(newPassword: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 更新用户密码
            _ = try await supabase.auth.update(
                user: UserAttributes(
                    password: newPassword
                )
            )

            // 密码重置完成
            needsPasswordSetup = false
            isAuthenticated = true
            errorMessage = nil

        } catch {
            // 设置密码失败
            errorMessage = "重置密码失败：\(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Third-Party Sign In (预留)

    /// 使用 Apple 登录
    /// - Note: TODO: 实现 Apple 登录功能
    func signInWithApple() async {
        // TODO: 实现 Apple 登录
        // 1. 获取 Apple 授权凭证
        // 2. 调用 supabase.auth.signInWithIdToken(...)
        // 3. 更新认证状态
        errorMessage = "Apple 登录功能即将上线"
    }

    /// 使用 Google 登录
    /// - Note: TODO: 实现 Google 登录功能
    func signInWithGoogle() async {
        // TODO: 实现 Google 登录
        // 1. 获取 Google 授权凭证
        // 2. 调用 supabase.auth.signInWithIdToken(...)
        // 3. 更新认证状态
        errorMessage = "Google 登录功能即将上线"
    }

    // MARK: - Sign Out

    /// 退出登录
    func signOut() async {
        isLoading = true
        errorMessage = nil

        do {
            // 退出登录
            try await supabase.auth.signOut()

            // 清空状态
            currentUser = nil
            isAuthenticated = false
            needsPasswordSetup = false
            otpSent = false
            otpVerified = false
            errorMessage = nil

        } catch {
            // 退出失败
            errorMessage = "退出登录失败：\(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Helper Methods

    /// 重置所有状态
    func resetState() {
        otpSent = false
        otpVerified = false
        errorMessage = nil
    }
}
