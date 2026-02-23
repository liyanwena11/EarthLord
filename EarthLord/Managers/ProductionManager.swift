//
//  ProductionManager.swift
//  EarthLord
//
//  Created by Claude on 2026-02-23.
//  资源生产管理器 - 管理建筑的生产任务
//

import Foundation
import Supabase
import Combine

class ProductionManager: ObservableObject {
    static let shared = ProductionManager()

    @Published var activeProductions: [ProductionJob] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase = supabaseClient
    private var productionCheckTimer: Timer?

    // 生产建筑配置（生产模板）
    private let productionTemplates: [ProductionTemplate] = [
        ProductionTemplate(
            buildingTemplateId: "farm",
            resourceId: "food",
            resourceName: "食物",
            resourceIcon: "leaf.fill",
            baseAmount: 50,
            productionTimeMinutes: 60,
            requiredBuildingLevel: 1
        ),
        ProductionTemplate(
            buildingTemplateId: "water_purifier",
            resourceId: "water",
            resourceName: "水",
            resourceIcon: "drop.fill",
            baseAmount: 30,
            productionTimeMinutes: 30,
            requiredBuildingLevel: 1
        ),
        ProductionTemplate(
            buildingTemplateId: "solar_panel",
            resourceId: "energy",
            resourceName: "能量",
            resourceIcon: "bolt.fill",
            baseAmount: 20,
            productionTimeMinutes: 15,
            requiredBuildingLevel: 1
        ),
        ProductionTemplate(
            buildingTemplateId: "scrap_collector",
            resourceId: "metal",
            resourceName: "金属",
            resourceIcon: "cube.fill",
            baseAmount: 15,
            productionTimeMinutes: 45,
            requiredBuildingLevel: 1
        ),
        ProductionTemplate(
            buildingTemplateId: "chemistry_lab",
            resourceId: "medical",
            resourceName: "医疗物资",
            resourceIcon: "cross.fill",
            baseAmount: 5,
            productionTimeMinutes: 120,
            requiredBuildingLevel: 2
        )
    ]

    private init() {
        startProductionTicker()
        LogDebug("🏭 [生产] ProductionManager 初始化完成")
    }

    // MARK: - Template Management

    func getTemplate(for buildingTemplateId: String) -> ProductionTemplate? {
        productionTemplates.first { $0.buildingTemplateId == buildingTemplateId }
    }

    func getAllTemplates() -> [ProductionTemplate] {
        return productionTemplates
    }

    // MARK: - Start Production

    func startProduction(
        buildingId: String,
        buildingName: String,
        territoryId: String,
        buildingLevel: Int
    ) async throws {
        // 获取生产模板
        guard let building = await BuildingManager.shared.playerBuildings.first(where: { $0.id.uuidString == buildingId }) else {
            throw ProductionError.buildingNotFound
        }

        guard let template = getTemplate(for: building.templateId) else {
            throw ProductionError.buildingNotFound
        }

        // 检查建筑状态
        guard building.status == .active else {
            throw ProductionError.buildingNotActive
        }

        // 检查建筑等级
        guard buildingLevel >= template.requiredBuildingLevel else {
            throw ProductionError.buildingLevelTooLow(required: template.requiredBuildingLevel)
        }

        // 检查是否已有生产任务
        let existingJobs = activeProductions.filter { $0.buildingId == buildingId && !$0.isCollected }
        guard existingJobs.isEmpty else {
            throw ProductionError.productionAlreadyActive
        }

        // 计算产出（基于建筑等级）
        let levelMultiplier = 1.0 + (Double(buildingLevel - 1) * 0.2) // 每级+20%
        let finalAmount = Int(Double(template.baseAmount) * levelMultiplier)

        let now = Date()
        let completionTime = now.addingTimeInterval(Double(template.productionTimeMinutes * 60))

        let newJob = NewProductionJob(
            building_id: buildingId,
            territory_id: territoryId,
            resource_id: template.resourceId,
            resource_name: template.resourceName,
            amount: finalAmount,
            start_time: now,
            completion_time: completionTime,
            is_collected: false,
            building_name: buildingName
        )

        let inserted: ProductionJob = try await supabase
            .from("production_jobs")
            .insert(newJob)
            .select()
            .single()
            .execute()
            .value

        await MainActor.run {
            self.activeProductions.append(inserted)
        }

        LogInfo("🏭 [生产] 开始生产: \(buildingName) - \(template.resourceName) x\(finalAmount)")
    }

    // MARK: - Collect Production

    func collectProduction(jobId: String) async throws -> (resourceId: String, amount: Int) {
        guard let job = activeProductions.first(where: { $0.id == jobId }) else {
            throw ProductionError.buildingNotFound
        }

        guard job.isCompleted else {
            throw ProductionError.buildingNotActive // 还在生产中
        }

        // 添加到背包
        try await InventoryManager.shared.addItem(itemId: job.resourceId, quantity: job.amount)

        // 更新任务状态
        let update = ProductionJobUpdate(is_collected: true, collected_at: Date())
        try await supabase
            .from("production_jobs")
            .update(update)
            .eq("id", value: jobId)
            .execute()

        // 从活跃列表移除
        await MainActor.run {
            self.activeProductions.removeAll { $0.id == jobId }
        }

        LogInfo("🏭 [生产] 收集完成: \(job.resourceName) x\(job.amount)")
        return (job.resourceId, job.amount)
    }

    // MARK: - Fetch Jobs

    func fetchActiveProductions() async {
        let userIdString = await MainActor.run { AuthManager.shared.currentUser?.id.uuidString }
        guard let userIdString else { return }

        await MainActor.run { self.isLoading = true; self.errorMessage = nil }

        do {
            let jobs: [ProductionJob] = try await supabase
                .from("production_jobs")
                .select()
                .eq("is_collected", value: false)
                .gte("completion_time", value: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-24*3600)))
                .execute()
                .value

            await MainActor.run {
                self.activeProductions = jobs
                self.isLoading = false
            }
            LogInfo("🏭 [生产] 加载 \(jobs.count) 个活跃生产任务")
        } catch {
            LogError("❌ [生产] 加载失败: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "加载生产任务失败"
            }
        }
    }

    // MARK: - Production Ticker

    private func startProductionTicker() {
        // 每分钟检查一次
        productionCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { await self?.checkCompletedProductions() }
        }
        LogDebug("🏭 [生产] 生产检查定时器已启动")
    }

    private func checkCompletedProductions() async {
        let completedJobs = activeProductions.filter { $0.isCompleted }
        if !completedJobs.isEmpty {
            LogDebug("🏭 [生产] 有 \(completedJobs.count) 个生产任务完成")
        }
    }

    // MARK: - Helpers

    func getActiveJobsForTerritory(_ territoryId: String) -> [ProductionJob] {
        activeProductions.filter { $0.territoryId == territoryId && !$0.isCollected }
    }

    func getActiveJobsForBuilding(_ buildingId: String) -> [ProductionJob] {
        activeProductions.filter { $0.buildingId == buildingId && !$0.isCollected }
    }

    deinit {
        productionCheckTimer?.invalidate()
    }
}

// MARK: - Notification

extension Notification.Name {
    static let productionCompleted = Notification.Name("productionCompleted")
    static let productionStarted = Notification.Name("productionStarted")
}
