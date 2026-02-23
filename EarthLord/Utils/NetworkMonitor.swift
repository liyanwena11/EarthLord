//
//  NetworkMonitor.swift
//  EarthLord
//
//  网络状态监控
//

import Network
import SwiftUI

@MainActor
class NetworkMonitor: ObservableObject {

    static let shared = NetworkMonitor()

    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private init() {
        startMonitoring()
    }

    /// 开始监控网络状态
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type

                if path.status == .satisfied {
                    let interfaceType = path.availableInterfaces.first?.type
                    let typeDescription: String
                    switch interfaceType {
                    case .wifi?: typeDescription = "WiFi"
                    case .cellular?: typeDescription = "蜂窝网络"
                    case .wiredEthernet?: typeDescription = "有线以太网"
                    case .loopback?: typeDescription = "本地回环"
                    case .other?: typeDescription = "其他"
                    case nil: typeDescription = "未知"
                    @unknown default: typeDescription = "未知类型"
                    }
                    LogInfo("网络已连接 - 接口类型: \(typeDescription)")
                } else {
                    LogWarning("网络���断开")
                }
            }
        }
        monitor.start(queue: queue)
    }

    /// 停止监控
    func stopMonitoring() {
        monitor.cancel()
    }

    /// 检查是否连接到 WiFi
    var isWiFiConnected: Bool {
        connectionType == .wifi
    }

    /// 检查是否连接到蜂窝网络
    var isCellularConnected: Bool {
        connectionType == .cellular
    }

    /// 检查是否连接到任何网络
    var hasConnection: Bool {
        isConnected
    }
}
