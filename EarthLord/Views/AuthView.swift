import SwiftUI
import AuthenticationServices

struct AuthView: View {
    // 监听我们刚才改好的大脑（✅ 修复：shared 单例用 @ObservedObject）
    @ObservedObject private var authManager = AuthManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var isRegisterMode = false
    
    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13) // #FF6B21

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ApocalypseTheme.background,
                    Color(red: 0.15, green: 0.10, blue: 0.08),
                    ApocalypseTheme.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // 1. 顶部 Logo
                VStack(spacing: 12) {
                    Image(systemName: "globe.asia.australia.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(brandOrange)
                    
                    Text("末世领主")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("末日生存，探索领地")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)

                VStack(spacing: 18) {
                    // 2. 登录/注册 切换
                    HStack(spacing: 0) {
                        TabButton(title: "登录", isActive: !isRegisterMode) {
                            isRegisterMode = false
                            authManager.resetState()
                        }
                        TabButton(title: "注册", isActive: isRegisterMode) {
                            isRegisterMode = true
                            authManager.resetState()
                        }
                    }
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)

                    // 3. 输入框
                    VStack(spacing: 15) {
                        AuthInputField(icon: "envelope.fill", placeholder: "邮箱地址", text: $email)
                        AuthInputField(icon: "lock.fill", placeholder: "访问密码", text: $password, isSecure: true)
                    }

                    // 错误显示
                    if let error = authManager.errorMessage {
                        Text(error).foregroundColor(.red).font(.caption).multilineTextAlignment(.center)
                    }

                    // 4. 核心登录/注册按钮
                    Button(action: {
                        Task {
                            if isRegisterMode {
                                await authManager.signUp(email: email, password: password)
                            } else {
                                await authManager.signIn(email: email, password: password)
                            }
                        }
                    }) {
                        if authManager.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(isRegisterMode ? "立即注册" : "登录系统")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(brandOrange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(ApocalypseTheme.cardBackground.opacity(0.88))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(brandOrange.opacity(0.22), lineWidth: 1)
                )
                .padding(.horizontal, 16)

                Spacer()

                // 5. 第三方登录 (这里是修复按钮没反应的关键！)
                VStack(spacing: 15) {
                    HStack {
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                        Text("或者使用以下方式登录").font(.caption2).foregroundColor(.gray).fixedSize()
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                    }
                    

                    
                    // SIGN IN WITH APPLE 按钮（必须排在第三方登录首位）
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task { await authManager.handleAppleSignIn(result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(10)

                    // GOOGLE 登录按钮
                    Button(action: {
                        Task { await authManager.signInWithGoogle() }
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                            Text("通过 Google 登录")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
    }
}

// 内部小组件保持不变
struct TabButton: View {
    let title: String; let isActive: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(isActive ? Color(red: 1.0, green: 0.42, blue: 0.13) : Color.clear)
                .foregroundColor(.white).cornerRadius(10)
        }.padding(4)
    }
}

struct AuthInputField: View {
    let icon: String; let placeholder: String; @Binding var text: String; var isSecure: Bool = false
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.gray).frame(width: 30)
            if isSecure { SecureField(placeholder, text: $text).foregroundColor(.white) }
            else { TextField(placeholder, text: $text).foregroundColor(.white).autocapitalization(.none) }
        }.padding().background(Color.white.opacity(0.1)).cornerRadius(10)
    }
}
