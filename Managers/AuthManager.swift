import Foundation
import Supabase
import GoogleSignIn
import AuthenticationServices

class AuthManager {
    static let shared = AuthManager()
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://gqqkmgwpmwwvtrcpcchv.supabase.co")!,
        supabaseKey: "**************************************************************************************************************************************************************************************************************************"
    )
    
    private init() {}
    
    func signInWithApple(idToken: String) async throws {
        let response = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: ""
            )
        )
        print("Apple 登录成功: \(response.user?.id ?? "未知用户")")
    }
    
    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        let response = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
        print("Google 登录成功: \(response.user?.id ?? "未知用户")")
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        print("退出登录成功")
    }
    
    func getCurrentUser() async -> User? {
        return try? await supabase.auth.session?.user
    }
}
