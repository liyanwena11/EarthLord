//
//  EmblemManager.swift
//  EarthLord
//
//  Created by Claude on 2026-02-23.
//  徽章管理器
//

import Foundation
import Supabase
import Combine

class EmblemManager: ObservableObject {
    static let shared = EmblemManager()

    @Published var unlockedEmblems: Set<String> = []
    @Published var territoryEmblems: [String: String] = [:] // territoryId -> emblemId
    @Published var isLoading: Bool = false

    private let supabase = supabaseClient

    private init() {
        loadUnlockedEmblems()
        LogDebug("🏆 [徽章] EmblemManager 初始化完成")
    }

    // MARK: - Emblem Management

    func isEmblemUnlocked(_ emblemId: String) -> Bool {
        return unlockedEmblems.contains(emblemId)
    }

    func unlockEmblem(_ emblemId: String) async throws {
        guard let emblem = Emblem.allEmblems.first(where: { $0.id == emblemId }) else {
            throw NSError(domain: "EmblemManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "徽章不存在"])
        }

        // 检查是否已解锁
        if unlockedEmblems.contains(emblemId) {
            return
        }

        // 检查解锁条件
        guard emblem.requirement.isMet else {
            throw NSError(domain: "EmblemManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "未满足解锁条件"])
        }

        // TODO: 保存到数据库
        _ = await MainActor.run {
            self.unlockedEmblems.insert(emblemId)
            return emblemId
        }

        LogInfo("🏆 [徽章] 解锁徽章: \(emblem.name)")
    }

    func equipEmblem(emblemId: String, to territoryId: String) async throws {
        guard unlockedEmblems.contains(emblemId) else {
            throw NSError(domain: "EmblemManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "徽章未解锁"])
        }

        // TODO: 保存到数据库
        await MainActor.run {
            self.territoryEmblems[territoryId] = emblemId
        }

        LogInfo("🏆 [徽章] 装备徽章到领地 \(territoryId): \(emblemId)")
    }

    func getEquippedEmblem(for territoryId: String) -> Emblem? {
        guard let emblemId = territoryEmblems[territoryId] else { return nil }
        return Emblem.allEmblems.first { $0.id == emblemId }
    }

    // MARK: - Bonus Calculation

    func calculateTerritoryBonus(for territoryId: String) -> EmblemBonus? {
        guard let emblem = getEquippedEmblem(for: territoryId) else { return nil }
        return emblem.bonus
    }

    func getResourceProductionBonus(for territoryId: String) -> Double {
        guard let bonus = calculateTerritoryBonus(for: territoryId),
              let productionBonus = bonus.resourceProduction else {
            return 0
        }
        return productionBonus
    }

    func getBuildingSpeedBonus(for territoryId: String) -> Double {
        guard let bonus = calculateTerritoryBonus(for: territoryId),
              let speedBonus = bonus.buildingSpeed else {
            return 0
        }
        return speedBonus
    }

    // MARK: - Data Loading

    private func loadUnlockedEmblems() {
        // TODO: 从数据库加载已解锁的徽章
        // 暂时使用本地数据
        unlockedEmblems = []
    }

    func fetchUserEmblems() async {
        isLoading = true
        // TODO: 从 Supabase 加载用户徽章数据
        try? await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run {
            self.isLoading = false
        }
    }
}
