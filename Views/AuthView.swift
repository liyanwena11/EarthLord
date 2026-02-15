import SwiftUI
import GoogleSignIn
import AuthenticationServices

struct AuthView: View {
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("地球新主")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("末日生存游戏")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Apple 登录按钮
            SignInWithAppleButton {
                request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: {
                result in
                switch result {
                case .success(let authResults):
                    Task {
                        isLoading = true
                        errorMessage = nil
                        
                        do {
                            guard let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential,
                                  let idToken = appleIDCredential.identityToken,
                                  let idTokenString = String(data: idToken, encoding: .utf8) else {
                                throw NSError(domain: "AppleAuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法获取 Apple ID 令牌"])
                            }
                            
                            try await AuthManager.shared.signInWithApple(idToken: idTokenString)
                        } catch {
                            errorMessage = "Apple 登录失败: \(error.localizedDescription)"
                            print("Apple 登录失败: \(error)")
                        } finally {
                            isLoading = false
                        }
                    }
                case .failure(let error):
                    errorMessage = "Apple 登录失败: \(error.localizedDescription)"
                    print("Apple 登录失败: \(error)")
                }
            }
            .frame(height: 50)
            .cornerRadius(10)
            
            // Google 登录按钮
            Button(action: {
                Task {
                    isLoading = true
                    errorMessage = nil
                    
                    do {
                        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
                            throw NSError(domain: "GoogleAuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法获取视图控制器"])
                        }
                        
                        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
                        guard let idToken = result.user.idToken?.tokenString,
                              let accessToken = result.user.accessToken.tokenString else {
                            throw NSError(domain: "GoogleAuthError", code: 2, userInfo: [NSLocalizedDescriptionKey: "无法获取 Google 令牌"])
                        }
                        
                        try await AuthManager.shared.signInWithGoogle(idToken: idToken, accessToken: accessToken)
                    } catch {
                        errorMessage = "Google 登录失败: \(error.localizedDescription)"
                        print("Google 登录失败: \(error)")
                    } finally {
                        isLoading = false
                    }
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                    Text("使用 Google 登录")
                }
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(10)
                .border(Color.gray, width: 1)
            }
            
            Spacer()
        }
        .padding()
        .overlay {
            if isLoading {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .scaleEffect(2)
                            .tint(.white)
                    }
            }
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
