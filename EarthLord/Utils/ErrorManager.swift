//
//  ErrorManager.swift
//  EarthLord
//
//  统一错误提示管理器
//

import SwiftUI

@MainActor
class ErrorManager: ObservableObject {

    static let shared = ErrorManager()

    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var errorTitle: String = "提示"

    private init() {}

    /// 显示错误提示
    /// - Parameters:
    ///   - message: 错误消息
    ///   - title: 标题（默认"提示"）
    ///   - autoHide: 是否自动隐藏（默认3秒后）
    func show(
        _ message: String,
        title: String = "提示",
        autoHide: Bool = true
    ) {
        errorTitle = title
        errorMessage = message
        showError = true

        if autoHide {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.hideError()
            }
        }
    }

    /// 隐藏错误提示
    func hideError() {
        errorMessage = nil
        showError = false
    }

    /// 包装网络请求，自动处理错误
    func handleError<T>(
        _ operation: String,
        block: () async throws -> T
    ) async -> T? {
        do {
            return try await block()
        } catch {
            let errorMsg = "\(operation)失败：\(error.localizedDescription)"
            LogError(errorMsg)
            show(errorMsg, title: "错误")
            return nil
        }
    }
}

/// SwiftUI 错误提示修饰符
struct ErrorAlert: ViewModifier {
    @ObservedObject var errorManager = ErrorManager.shared

    func body(content: Content) -> some View {
        content
            .alert(errorManager.errorTitle, isPresented: $errorManager.showError) {
                Button("确定") {
                    errorManager.hideError()
                }
            } message: {
                if let errorMessage = errorManager.errorMessage {
                    Text(errorMessage)
                }
            }
    }
}

extension View {
    /// 添加全局错误提示
    func withErrorAlert() -> some View {
        self.modifier(ErrorAlert())
    }
}
