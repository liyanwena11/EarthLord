//
//  ProductionQueueView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-23.
//  生产队列视图
//

import SwiftUI

struct ProductionQueueView: View {
    let territoryId: String

    @StateObject private var productionManager = ProductionManager.shared
    @State private var productions: [ProductionJob] = []
    @State private var isLoading = false
    @State private var showCollectAlert = false
    @State private var jobToCollect: ProductionJob?

    var body: some View {
        VStack(spacing: 16) {
            // 标题栏
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.2.fill")
                        .foregroundColor(ApocalypseTheme.primary)
                    Text("生产队列")
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
                Spacer()
                Text("\(productions.count) 个进行中")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .padding()

            // 生产任务列表
            if isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else if productions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "gearshape.2")
                        .font(.system(size: 40))
                        .foregroundColor(ApocalypseTheme.textMuted)
                    Text("暂无生产任务")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Text("在生产建筑中开始生产，这里会显示进度")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(productions) { job in
                            ProductionJobCard(job: job) {
                                jobToCollect = job
                                showCollectAlert = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // 一键收集按钮
            if !productions.isEmpty && productions.contains(where: { $0.isCompleted }) {
                Button {
                    Task {
                        await collectAllCompleted()
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("一键收集 (\(completedCount))")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(ApocalypseTheme.success)
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
        .task {
            await loadProductions()
        }
        .onReceive(NotificationCenter.default.publisher(for: .productionCompleted)) { _ in
            Task { await loadProductions() }
        }
        .alert("收集产出", isPresented: $showCollectAlert) {
            Button("取消", role: .cancel) { }
            Button("收集") {
                Task {
                    if let job = jobToCollect {
                        await collectJob(job)
                    }
                }
            }
        } message: {
            if let job = jobToCollect {
                Text("确定要收集 \(job.resourceName) x\(job.amount) 吗？")
            }
        }
    }

    private var completedCount: Int {
        productions.filter { $0.isCompleted }.count
    }

    private func loadProductions() async {
        isLoading = true
        await productionManager.fetchActiveProductions()
        await MainActor.run {
            self.productions = productionManager.getActiveJobsForTerritory(territoryId)
            self.isLoading = false
        }
    }

    private func collectJob(_ job: ProductionJob) async {
        do {
            let (_, amount) = try await productionManager.collectProduction(jobId: job.id)
            LogInfo("✅ 收集成功: \(job.resourceName) x\(amount)")
            await loadProductions()
        } catch {
            LogError("❌ 收集失败: \(error.localizedDescription)")
        }
    }

    private func collectAllCompleted() async {
        let completedJobs = productions.filter { $0.isCompleted }
        for job in completedJobs {
            await collectJob(job)
        }
    }
}

// MARK: - ProductionJobCard

struct ProductionJobCard: View {
    let job: ProductionJob
    let onCollect: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // 资源图标
                ZStack {
                    Circle()
                        .fill(ApocalypseTheme.primary.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "leaf.fill") // TODO: 根据resourceId显示对应图标
                        .foregroundColor(ApocalypseTheme.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(job.resourceName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                    Text("来自: \(job.buildingName)")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                Spacer()

                // 数量
                VStack(alignment: .trailing, spacing: 4) {
                    Text("x\(job.amount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ApocalypseTheme.primary)

                    if job.isCompleted {
                        Text("可收集")
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.success)
                    } else {
                        Text(job.formattedRemainingTime)
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                }
            }

            // 进度条
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(job.isCompleted ? "生产完成" : "生产中...")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Spacer()
                    Text("\(Int(job.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                ProgressView(value: job.progress)
                    .tint(job.isCompleted ? ApocalypseTheme.success : ApocalypseTheme.primary)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }

            // 收集按钮
            if job.isCompleted {
                Button {
                    onCollect()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("收集产出")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(ApocalypseTheme.success)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(ApocalypseTheme.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(job.isCompleted ? ApocalypseTheme.success.opacity(0.3) : ApocalypseTheme.primary.opacity(0.2), lineWidth: 1)
        )
    }
}

// 预览
#Preview {
    ProductionQueueView(territoryId: "test-territory")
}
