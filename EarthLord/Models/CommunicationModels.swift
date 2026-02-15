//
//  CommunicationModels.swift
//  EarthLord
//
//  通讯系统数据模型
//

import Foundation
import SwiftUI

// MARK: - DeviceType

enum DeviceType: String, Codable, CaseIterable {
    case radio = "radio"
    case walkieTalkie = "walkie_talkie"
    case campRadio = "camp_radio"
    case satellite = "satellite"

    var displayName: String {
        switch self {
        case .radio: return "收音机"
        case .walkieTalkie: return "对讲机"
        case .campRadio: return "营地电台"
        case .satellite: return "卫星通讯"
        }
    }

    var iconName: String {
        switch self {
        case .radio: return "radio"
        case .walkieTalkie: return "walkie.talkie.radio"
        case .campRadio: return "antenna.radiowaves.left.and.right"
        case .satellite: return "antenna.radiowaves.left.and.right.circle"
        }
    }

    var description: String {
        switch self {
        case .radio: return "只能接收信号，无法发送消息"
        case .walkieTalkie: return "可在3公里范围内通讯"
        case .campRadio: return "可在30公里范围内广播"
        case .satellite: return "可在100公里+范围内联络"
        }
    }

    var range: Double {
        switch self {
        case .radio: return Double.infinity
        case .walkieTalkie: return 3.0
        case .campRadio: return 30.0
        case .satellite: return 100.0
        }
    }

    var rangeText: String {
        switch self {
        case .radio: return "无限制（仅接收）"
        case .walkieTalkie: return "3 公里"
        case .campRadio: return "30 公里"
        case .satellite: return "100+ 公里"
        }
    }

    var canSend: Bool { self != .radio }

    var unlockRequirement: String {
        switch self {
        case .radio, .walkieTalkie: return "默认拥有"
        case .campRadio: return "需建造「营地电台」建筑"
        case .satellite: return "需建造「通讯塔」建筑"
        }
    }
}

// MARK: - CommunicationDevice

struct CommunicationDevice: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let deviceType: DeviceType
    var deviceLevel: Int
    var isUnlocked: Bool
    var isCurrent: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case deviceType = "device_type"
        case deviceLevel = "device_level"
        case isUnlocked = "is_unlocked"
        case isCurrent = "is_current"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - CommunicationSection

enum CommunicationSection: String, CaseIterable {
    case messages = "消息"
    case channels = "频道"
    case call = "呼叫"
    case devices = "设备"

    var displayName: String { rawValue }

    var iconName: String {
        switch self {
        case .messages: return "bell.fill"
        case .channels: return "dot.radiowaves.left.and.right"
        case .call: return "phone.fill"
        case .devices: return "gearshape.fill"
        }
    }
}

// MARK: - ChannelType

enum ChannelType: String, Codable, CaseIterable {
    case official = "official"
    case publicChannel = "public"
    case walkie = "walkie"
    case camp = "camp"
    case satellite = "satellite"

    var displayName: String {
        switch self {
        case .official: return "官方频道"
        case .publicChannel: return "公开频道"
        case .walkie: return "对讲频道"
        case .camp: return "营地频道"
        case .satellite: return "卫星频道"
        }
    }

    var iconName: String {
        switch self {
        case .official: return "megaphone.fill"
        case .publicChannel: return "globe"
        case .walkie: return "walkie.talkie.radio"
        case .camp: return "antenna.radiowaves.left.and.right"
        case .satellite: return "antenna.radiowaves.left.and.right.circle"
        }
    }

    var rangeText: String {
        switch self {
        case .official, .publicChannel: return "全局"
        case .walkie: return "3 公里"
        case .camp: return "30 公里"
        case .satellite: return "100+ 公里"
        }
    }

    var requiredDevice: DeviceType? {
        switch self {
        case .official, .publicChannel: return nil
        case .walkie: return .walkieTalkie
        case .camp: return .campRadio
        case .satellite: return .satellite
        }
    }

    static var creatableTypes: [ChannelType] { [.publicChannel, .walkie, .camp, .satellite] }
}

// MARK: - MessageCategory

enum MessageCategory: String, Codable, CaseIterable {
    case survival = "survival"
    case news = "news"
    case mission = "mission"
    case alert = "alert"

    var displayName: String {
        switch self {
        case .survival: return "生存指南"
        case .news: return "游戏资讯"
        case .mission: return "任务发布"
        case .alert: return "紧急广播"
        }
    }

    var color: Color {
        switch self {
        case .survival: return .green
        case .news: return .blue
        case .mission: return .orange
        case .alert: return .red
        }
    }

    var iconName: String {
        switch self {
        case .survival: return "leaf.fill"
        case .news: return "newspaper.fill"
        case .mission: return "target"
        case .alert: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - CommunicationChannel

struct CommunicationChannel: Codable, Identifiable, Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: CommunicationChannel, rhs: CommunicationChannel) -> Bool { lhs.id == rhs.id }

    let id: UUID
    let creatorId: UUID
    let channelType: ChannelType
    let channelCode: String
    let name: String
    let description: String?
    let isActive: Bool
    let memberCount: Int
    let latitude: Double?
    let longitude: Double?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case creatorId = "creator_id"
        case channelType = "channel_type"
        case channelCode = "channel_code"
        case name, description
        case isActive = "is_active"
        case memberCount = "member_count"
        case latitude, longitude
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        creatorId = try c.decode(UUID.self, forKey: .creatorId)
        let typeString = try c.decode(String.self, forKey: .channelType)
        channelType = typeString == "public" ? .publicChannel : (ChannelType(rawValue: typeString) ?? .publicChannel)
        channelCode = try c.decode(String.self, forKey: .channelCode)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        isActive = try c.decode(Bool.self, forKey: .isActive)
        memberCount = try c.decode(Int.self, forKey: .memberCount)
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(creatorId, forKey: .creatorId)
        try c.encode(channelType == .publicChannel ? "public" : channelType.rawValue, forKey: .channelType)
        try c.encode(channelCode, forKey: .channelCode)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encode(isActive, forKey: .isActive)
        try c.encode(memberCount, forKey: .memberCount)
        try c.encodeIfPresent(latitude, forKey: .latitude)
        try c.encodeIfPresent(longitude, forKey: .longitude)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - ChannelSubscription

struct ChannelSubscription: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let channelId: UUID
    var isMuted: Bool
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case channelId = "channel_id"
        case isMuted = "is_muted"
        case joinedAt = "joined_at"
    }
}

struct SubscribedChannel: Identifiable {
    let channel: CommunicationChannel
    let subscription: ChannelSubscription
    var id: UUID { channel.id }
}

// MARK: - LocationPoint

struct LocationPoint: Codable {
    let latitude: Double
    let longitude: Double

    static func fromPostGIS(_ wkt: String) -> LocationPoint? {
        let pattern = #"POINT\(([0-9.-]+)\s+([0-9.-]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: wkt, range: NSRange(wkt.startIndex..., in: wkt)),
              let lonRange = Range(match.range(at: 1), in: wkt),
              let latRange = Range(match.range(at: 2), in: wkt),
              let longitude = Double(wkt[lonRange]),
              let latitude = Double(wkt[latRange]) else { return nil }
        return LocationPoint(latitude: latitude, longitude: longitude)
    }
}

// MARK: - MessageMetadata

struct MessageMetadata: Codable {
    let deviceType: String?
    let category: String?
    enum CodingKeys: String, CodingKey {
        case deviceType = "device_type"; case category
    }
}

// MARK: - ChannelMessage

struct ChannelMessage: Codable, Identifiable {
    let messageId: UUID
    let channelId: UUID
    let senderId: UUID?
    let senderCallsign: String?
    let content: String
    let senderLocation: LocationPoint?
    let metadata: MessageMetadata?
    let createdAt: Date
    let senderDeviceType: DeviceType?

    var id: UUID { messageId }

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case channelId = "channel_id"
        case senderId = "sender_id"
        case senderCallsign = "sender_callsign"
        case content
        case senderLocation = "sender_location"
        case metadata
        case createdAt = "created_at"
        case senderDeviceType = "sender_device_type"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        messageId = try c.decode(UUID.self, forKey: .messageId)
        channelId = try c.decode(UUID.self, forKey: .channelId)
        senderId = try c.decodeIfPresent(UUID.self, forKey: .senderId)
        senderCallsign = try c.decodeIfPresent(String.self, forKey: .senderCallsign)
        content = try c.decode(String.self, forKey: .content)
        metadata = try c.decodeIfPresent(MessageMetadata.self, forKey: .metadata)

        if let locStr = try? c.decode(String.self, forKey: .senderLocation) {
            senderLocation = LocationPoint.fromPostGIS(locStr)
        } else {
            senderLocation = try c.decodeIfPresent(LocationPoint.self, forKey: .senderLocation)
        }

        if let dateStr = try? c.decode(String.self, forKey: .createdAt) {
            createdAt = ChannelMessage.parseDate(dateStr) ?? Date()
        } else {
            createdAt = try c.decode(Date.self, forKey: .createdAt)
        }

        if let dtStr = try? c.decode(String.self, forKey: .senderDeviceType),
           let dt = DeviceType(rawValue: dtStr) {
            senderDeviceType = dt
        } else if let dtStr = metadata?.deviceType, let dt = DeviceType(rawValue: dtStr) {
            senderDeviceType = dt
        } else {
            senderDeviceType = nil
        }
    }

    private static func parseDate(_ string: String) -> Date? {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
            "yyyy-MM-dd'T'HH:mm:ssXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss"
        ]
        for format in formats {
            let f = DateFormatter()
            f.dateFormat = format
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = f.date(from: string) { return date }
        }
        return nil
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(createdAt)
        if interval < 60 { return "刚刚" }
        if interval < 3600 { return "\(Int(interval / 60))分钟前" }
        if interval < 86400 { return "\(Int(interval / 3600))小时前" }
        let f = DateFormatter(); f.dateFormat = "MM-dd HH:mm"
        return f.string(from: createdAt)
    }

    var timeString: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: createdAt)
    }

    var deviceType: String? { metadata?.deviceType }

    var category: MessageCategory? {
        guard let s = metadata?.category else { return nil }
        return MessageCategory(rawValue: s)
    }
}
