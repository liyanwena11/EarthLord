import Foundation
import Combine

// MARK: - LogType Enum

enum LogType: String {
    case info = "INFO"
    case success = "SUCCESS"
    case warning = "WARNING"
    case error = "ERROR"
}

// MARK: - LogEntry Structure

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let type: LogType
}

// MARK: - TerritoryLogger

/// Territory logging manager (Singleton + ObservableObject)
final class TerritoryLogger: ObservableObject {

    // MARK: - Singleton

    static let shared = TerritoryLogger()

    // MARK: - Published Properties

    /// Log entries array
    @Published var logs: [LogEntry] = []

    /// Formatted log text for display
    @Published var logText: String = ""

    // MARK: - Private Properties

    /// Maximum log count to prevent memory overflow
    private let maxLogCount = 200

    /// Date formatter for display (HH:mm:ss)
    private let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    /// Date formatter for export (yyyy-MM-dd HH:mm:ss)
    private let exportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    // MARK: - Initialization

    private init() {
        // Private initializer ensures singleton
    }

    // MARK: - Public Methods

    /// Add a log entry
    func log(_ message: String, type: LogType = .info) {
        // Ensure UI updates on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let entry = LogEntry(timestamp: Date(), message: message, type: type)

            // Add to array
            self.logs.append(entry)

            // Limit maximum count
            if self.logs.count > self.maxLogCount {
                self.logs.removeFirst(self.logs.count - self.maxLogCount)
            }

            // Update display text
            self.updateLogText()
        }

        // Also output to console for Xcode debugging
        let prefix: String
        switch type {
        case .info: prefix = "📝"
        case .success: prefix = "✅"
        case .warning: prefix = "⚠️"
        case .error: prefix = "❌"
        }
        print("\(prefix) [Territory] \(message)")
    }

    /// Clear all logs
    func clear() {
        DispatchQueue.main.async { [weak self] in
            self?.logs.removeAll()
            self?.logText = ""
        }
    }

    /// Export logs as text
    func export() -> String {
        guard !logs.isEmpty else {
            return "No log records available"
        }

        let lines = logs.map { entry in
            let timestamp = exportDateFormatter.string(from: entry.timestamp)
            return "[\(timestamp)] [\(entry.type.rawValue)] \(entry.message)"
        }

        return """
        === Territory Test Logs ===
        Export Time: \(exportDateFormatter.string(from: Date()))
        Log Count: \(logs.count)

        \(lines.joined(separator: "\n"))
        """
    }

    // MARK: - Private Methods

    /// Update display text
    private func updateLogText() {
        let lines = logs.map { entry in
            let timestamp = displayDateFormatter.string(from: entry.timestamp)
            return "[\(timestamp)] [\(entry.type.rawValue)] \(entry.message)"
        }
        logText = lines.joined(separator: "\n")
    }
}
