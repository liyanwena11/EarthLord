//
//  AuthView.swift
//  EarthLord
//
//  Created by lyanwen on 2025/12/31.
//

import SwiftUI

/// 认证页面
/// 包含登录、注册、找回密码功能
struct AuthView: View {

    // MARK: - State Properties

    /// 认证管理器
    @StateObject private var authManager = AuthManager.shared

    /// 当前选中的Tab（登录或注册）
    @State private var selectedTab: AuthTab = .login

    /// 登录表单
    @State private var loginEmail = ""
    @State private var loginPassword = ""

    /// 注册表单
    @State private var registerEmail = ""
    @State private var registerOTP = ""
    @State private var registerPassword = ""
    @State private var registerPasswordConfirm = ""
    @State private var registerStep: RegisterStep = .email

    /// 找回密码表单
    @State private var resetEmail = ""
    @State private var resetOTP = ""
    @State private var resetPassword = ""
    @State private var resetPasswordConfirm = ""
    @State private var resetStep: ResetStep = .email

    /// 是否显示找回密码弹窗
    @State private var showResetPasswordSheet = false

    /// 倒计时（秒）
    @State private var countdown = 0
    @State private var timer: Timer? = nil

    /// Toast 提示消息
    @State private var toastMessage: String? = nil
    @State private var showToast = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景渐变
            backgroundGradient

            ScrollView {
                VStack(spacing: 30) {
                    Spacer()
                        .frame(height: 40)

                    // Logo 和标题
                    logoSection

                    // Tab 切换
                    tabSelector

                    // 内容区域
                    if selectedTab == .login {
                        loginForm
                    } else {
                        registerForm
                    }

                    // 第三方登录
                    thirdPartyLoginSection

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
            }

            // Toast 提示
            if showToast, let message = toastMessage {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: showToast)
            }
        }
        .sheet(isPresented: $showResetPasswordSheet) {
            resetPasswordSheet
        }
        .onChange(of: authManager.otpVerified) { _, verified in
            // 注册流程：OTP 验证成功后，自动进入密码设置步骤
            if verified && selectedTab == .register {
                registerStep = .password
            }
        }
    }

    // MARK: - View Components

    /// 背景渐变
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color(red: 0.15, green: 0.08, blue: 0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    /// Logo 和标题
    private var logoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe.asia.australia.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(ApocalypseTheme.primary)

            Text("地球新主")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    /// Tab 选择器
    private var tabSelector: some View {
        HStack(spacing: 0) {
            // 登录 Tab
            Button(action: { selectedTab = .login }) {
                Text("登录")
                    .font(.headline)
                    .foregroundColor(selectedTab == .login ? .white : ApocalypseTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }

            // 注册 Tab
            Button(action: {
                selectedTab = .register
                authManager.resetState()
                registerStep = .email
            }) {
                Text("注册")
                    .font(.headline)
                    .foregroundColor(selectedTab == .register ? .white : ApocalypseTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            // 选中指示器
            GeometryReader { geometry in
                Rectangle()
                    .fill(ApocalypseTheme.primary)
                    .frame(width: geometry.size.width / 2, height: 3)
                    .offset(x: selectedTab == .login ? 0 : geometry.size.width / 2)
                    .animation(.spring(response: 0.3), value: selectedTab)
            }
            .frame(height: 3),
            alignment: .bottom
        )
    }

    /// 登录表单
    private var loginForm: some View {
        VStack(spacing: 20) {
            // 邮箱输入
            InputField(
                icon: "envelope.fill",
                placeholder: "邮箱",
                text: $loginEmail,
                keyboardType: .emailAddress
            )

            // 密码输入
            SecureInputField(
                icon: "lock.fill",
                placeholder: "密码",
                text: $loginPassword
            )

            // 错误提示
            if let error = authManager.errorMessage {
                ErrorText(message: error)
            }

            // 登录按钮
            PrimaryButton(
                title: "登录",
                isLoading: authManager.isLoading,
                action: handleLogin
            )

            // 忘记密码链接
            Button(action: { showResetPasswordSheet = true }) {
                Text("忘记密码？")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.primary)
            }
        }
        .padding(.vertical, 20)
    }

    /// 注册表单
    private var registerForm: some View {
        VStack(spacing: 20) {
            // 根据注册步骤显示不同内容
            switch registerStep {
            case .email:
                registerEmailStep
            case .otp:
                registerOTPStep
            case .password:
                registerPasswordStep
            }
        }
        .padding(.vertical, 20)
    }

    /// 注册第一步：邮箱输入
    private var registerEmailStep: some View {
        VStack(spacing: 20) {
            Text("输入您的邮箱")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 邮箱输入
            InputField(
                icon: "envelope.fill",
                placeholder: "邮箱",
                text: $registerEmail,
                keyboardType: .emailAddress
            )

            // 错误提示
            if let error = authManager.errorMessage {
                ErrorText(message: error)
            }

            // 发送验证码按钮
            PrimaryButton(
                title: "发送验证码",
                isLoading: authManager.isLoading,
                action: handleSendRegisterOTP
            )
        }
    }

    /// 注册第二步：验证码输入
    private var registerOTPStep: some View {
        VStack(spacing: 20) {
            Text("输入验证码")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("验证码已发送到 \(registerEmail)")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 验证码输入（6位）
            InputField(
                icon: "number",
                placeholder: "6位验证码",
                text: $registerOTP,
                keyboardType: .numberPad
            )

            // 错误提示
            if let error = authManager.errorMessage {
                ErrorText(message: error)
            }

            // 验证按钮
            PrimaryButton(
                title: "验证",
                isLoading: authManager.isLoading,
                action: handleVerifyRegisterOTP
            )

            // 重发倒计时
            resendButton(action: handleSendRegisterOTP)
        }
    }

    /// 注册第三步：设置密码
    private var registerPasswordStep: some View {
        VStack(spacing: 20) {
            Text("设置密码")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("⚠️ 必须设置密码才能完成注册")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.warning)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 密码输入
            SecureInputField(
                icon: "lock.fill",
                placeholder: "密码（至少6位）",
                text: $registerPassword
            )

            // 确认密码
            SecureInputField(
                icon: "lock.fill",
                placeholder: "确认密码",
                text: $registerPasswordConfirm
            )

            // 错误提示
            if let error = authManager.errorMessage {
                ErrorText(message: error)
            }

            // 完成注册按钮
            PrimaryButton(
                title: "完成注册",
                isLoading: authManager.isLoading,
                action: handleCompleteRegistration
            )
        }
    }

    /// 重发验证码按钮
    private func resendButton(action: @escaping () -> Void) -> some View {
        HStack {
            if countdown > 0 {
                Text("重新发送 (\(countdown)s)")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textMuted)
            } else {
                Button(action: action) {
                    Text("重新发送验证码")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }
        }
    }

    /// 第三方登录区域
    private var thirdPartyLoginSection: some View {
        VStack(spacing: 20) {
            // 分隔线
            HStack {
                Rectangle()
                    .fill(ApocalypseTheme.textMuted.opacity(0.3))
                    .frame(height: 1)
                Text("或者使用以下方式登录")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
                Rectangle()
                    .fill(ApocalypseTheme.textMuted.opacity(0.3))
                    .frame(height: 1)
            }

            VStack(spacing: 12) {
                // Apple 登录按钮
                ThirdPartyButton(
                    icon: "applelogo",
                    title: "使用 Apple 登录",
                    backgroundColor: .black,
                    action: {
                        showToastMessage("Apple 登录即将开放")
                    }
                )

                // Google 登录按钮
                ThirdPartyButton(
                    icon: "globe",
                    title: "使用 Google 登录",
                    backgroundColor: .white,
                    textColor: .black,
                    action: {
                        showToastMessage("Google 登录即将开放")
                    }
                )
            }
        }
    }

    /// 找回密码弹窗
    private var resetPasswordSheet: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 根据步骤显示不同内容
                        switch resetStep {
                        case .email:
                            resetEmailStep
                        case .otp:
                            resetOTPStep
                        case .password:
                            resetPasswordStepView
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("找回密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        showResetPasswordSheet = false
                        resetStep = .email
                        authManager.resetState()
                    }
                }
            }
        }
    }

    /// 找回密码第一步：邮箱输入
    private var resetEmailStep: some View {
        VStack(spacing: 20) {
            Text("输入您的邮箱")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            InputField(
                icon: "envelope.fill",
                placeholder: "邮箱",
                text: $resetEmail,
                keyboardType: .emailAddress
            )

            if let error = authManager.errorMessage {
                ErrorText(message: error)
            }

            PrimaryButton(
                title: "发送验证码",
                isLoading: authManager.isLoading,
                action: handleSendResetOTP
            )
        }
    }

    /// 找回密码第二步：验证码输入
    private var resetOTPStep: some View {
        VStack(spacing: 20) {
            Text("输入验证码")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("验证码已发送到 \(resetEmail)")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            InputField(
                icon: "number",
                placeholder: "6位验证码",
                text: $resetOTP,
                keyboardType: .numberPad
            )

            if let error = authManager.errorMessage {
                ErrorText(message: error)
            }

            PrimaryButton(
                title: "验证",
                isLoading: authManager.isLoading,
                action: handleVerifyResetOTP
            )

            resendButton(action: handleSendResetOTP)
        }
    }

    /// 找回密码第三步：设置新密码
    private var resetPasswordStepView: some View {
        VStack(spacing: 20) {
            Text("设置新密码")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            SecureInputField(
                icon: "lock.fill",
                placeholder: "新密码（至少6位）",
                text: $resetPassword
            )

            SecureInputField(
                icon: "lock.fill",
                placeholder: "确认新密码",
                text: $resetPasswordConfirm
            )

            if let error = authManager.errorMessage {
                ErrorText(message: error)
            }

            PrimaryButton(
                title: "重置密码",
                isLoading: authManager.isLoading,
                action: handleResetPassword
            )
        }
    }

    // MARK: - Actions

    /// 处理登录
    private func handleLogin() {
        guard !loginEmail.isEmpty, !loginPassword.isEmpty else {
            authManager.errorMessage = "请填写完整信息"
            return
        }

        Task {
            await authManager.signIn(email: loginEmail, password: loginPassword)
        }
    }

    /// 发送注册验证码
    private func handleSendRegisterOTP() {
        guard !registerEmail.isEmpty else {
            authManager.errorMessage = "请输入邮箱"
            return
        }

        guard isValidEmail(registerEmail) else {
            authManager.errorMessage = "邮箱格式不正确"
            return
        }

        Task {
            await authManager.sendRegisterOTP(email: registerEmail)
            if authManager.otpSent {
                registerStep = .otp
                startCountdown()
            }
        }
    }

    /// 验证注册验证码
    private func handleVerifyRegisterOTP() {
        guard registerOTP.count == 6 else {
            authManager.errorMessage = "请输入6位验证码"
            return
        }

        Task {
            await authManager.verifyRegisterOTP(email: registerEmail, code: registerOTP)
            // 验证成功后会自动触发 onChange，切换到密码设置步骤
        }
    }

    /// 完成注册
    private func handleCompleteRegistration() {
        guard !registerPassword.isEmpty, !registerPasswordConfirm.isEmpty else {
            authManager.errorMessage = "请填写密码"
            return
        }

        guard registerPassword.count >= 6 else {
            authManager.errorMessage = "密码至少6位"
            return
        }

        guard registerPassword == registerPasswordConfirm else {
            authManager.errorMessage = "两次密码不一致"
            return
        }

        Task {
            await authManager.completeRegistration(password: registerPassword)
        }
    }

    /// 发送找回密码验证码
    private func handleSendResetOTP() {
        guard !resetEmail.isEmpty else {
            authManager.errorMessage = "请输入邮箱"
            return
        }

        guard isValidEmail(resetEmail) else {
            authManager.errorMessage = "邮箱格式不正确"
            return
        }

        Task {
            await authManager.sendResetOTP(email: resetEmail)
            if authManager.otpSent {
                resetStep = .otp
                startCountdown()
            }
        }
    }

    /// 验证找回密码验证码
    private func handleVerifyResetOTP() {
        guard resetOTP.count == 6 else {
            authManager.errorMessage = "请输入6位验证码"
            return
        }

        Task {
            await authManager.verifyResetOTP(email: resetEmail, code: resetOTP)
            if authManager.otpVerified {
                resetStep = .password
            }
        }
    }

    /// 重置密码
    private func handleResetPassword() {
        guard !resetPassword.isEmpty, !resetPasswordConfirm.isEmpty else {
            authManager.errorMessage = "请填写密码"
            return
        }

        guard resetPassword.count >= 6 else {
            authManager.errorMessage = "密码至少6位"
            return
        }

        guard resetPassword == resetPasswordConfirm else {
            authManager.errorMessage = "两次密码不一致"
            return
        }

        Task {
            await authManager.resetPassword(newPassword: resetPassword)
            if authManager.isAuthenticated {
                showResetPasswordSheet = false
                resetStep = .email
            }
        }
    }

    // MARK: - Helper Methods

    /// 开始60秒倒计时
    private func startCountdown() {
        countdown = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer?.invalidate()
            }
        }
    }

    /// 验证邮箱格式
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// 显示 Toast 消息
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

// MARK: - Enums

/// 认证 Tab
enum AuthTab {
    case login
    case register
}

/// 注册步骤
enum RegisterStep {
    case email      // 输入邮箱
    case otp        // 输入验证码
    case password   // 设置密码
}

/// 找回密码步骤
enum ResetStep {
    case email      // 输入邮箱
    case otp        // 输入验证码
    case password   // 设置新密码
}

// MARK: - Custom Components

/// 输入框组件
struct InputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(width: 20)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .foregroundColor(.white)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }
}

/// 密码输入框组件
struct SecureInputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(width: 20)

            SecureField(placeholder, text: $text)
                .foregroundColor(.white)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }
}

/// 主要按钮组件
struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }

                Text(title)
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isLoading ? ApocalypseTheme.textMuted : ApocalypseTheme.primary)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}

/// 第三方登录按钮
struct ThirdPartyButton: View {
    let icon: String
    let title: String
    var backgroundColor: Color = .white
    var textColor: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))

                Text(title)
                    .font(.subheadline)
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
        }
    }
}

/// 错误提示文本
struct ErrorText: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundColor(ApocalypseTheme.danger)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

// MARK: - Preview

#Preview {
    AuthView()
}
