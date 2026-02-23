//
//  Logger.swift
//  EarthLord
//
//  统一日志系统 - 仅在 DEBUG 模式输出
//

import Foundation

enum LogLevel: String {
    case debug = "🔍 DEBUG"
    case info = "ℹ️ INFO"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
}

/// 统一日志系统
/// - Parameters:
///   - level: 日志级别
///   - message: 日志消息
///   - file: 文件名（自动获取）
///   - function: 函数名（自动获取）
///   - line: 行号（自动获取）
func Logger(
    _ level: LogLevel,
    _ message: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    #if DEBUG
    let filename = (file as NSString).lastPathComponent
    let timestamp = ISO8601DateFormatter().string(from: Date())
    print("[\(timestamp)] [\(level.rawValue)] [\(filename):\(line)] \(message)")
    #endif
}

/// 便捷日志函数
func LogDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger(.debug, message, file: file, function: function, line: line)
}

func LogInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger(.info, message, file: file, function: function, line: line)
}

func LogWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger(.warning, message, file: file, function: function, line: line)
}

func LogError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger(.error, message, file: file, function: function, line: line)
}
