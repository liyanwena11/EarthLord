//
//  TradeMainView.swift
//  EarthLord
//
//  交易系统主页面
//

import SwiftUI

struct TradeMainView: View {
    @State private var selectedTab: TradeTab = .market
    @StateObject private var tradeManager = TradeManager.shared
    @State private var isLoading = true
    
    enum TradeTab: String, CaseIterable {
        case market = "市场"
        case myOffers = "我的"
        case history = "历史"
        case create = "发布"
        
        var displayName: String { rawValue }
        
        var iconName: String {
            switch self {
            case .market: return "globe"
            case .myOffers: return "person.fill"
            case .history: return "clock.fill"
            case .create: return "plus.circle.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部状态栏
                    tradeStatusBar
                    
                    // 导航选择器
                    tabSelector
                    
                    // 内容区域
                    contentArea
                }
            }
            .navigationTitle("交易中心")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await loadInitialData()
                }
            }
        }
    }
    
    // MARK: - 顶部状态栏
    private var tradeStatusBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(ApocalypseTheme.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("交易系统")
                    .font(.caption.bold())
                    .foregroundColor(ApocalypseTheme.textPrimary)
                Text("物物交换，各取所需")
                    .font(.caption2)
                    .foregroundColor(ApocalypseTheme.textMuted)
            }
            
            Spacer()
            
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            Text("在线")
                .font(.caption2)
                .foregroundColor(.green)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(ApocalypseTheme.cardBackground)
    }
    
    // MARK: - 标签选择器
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(TradeTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 16))
                        Text(tab.displayName)
                            .font(.system(size: 11))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(selectedTab == tab ? ApocalypseTheme.primary : ApocalypseTheme.textMuted)
                    .background(
                        selectedTab == tab
                            ? ApocalypseTheme.primary.opacity(0.1)
                            : Color.clear
                    )
                    .overlay(
                        Rectangle()
                            .fill(selectedTab == tab ? ApocalypseTheme.primary : Color.clear)
                            .frame(height: 2),
                        alignment: .bottom
                    )
                }
            }
        }
        .background(ApocalypseTheme.cardBackground)
    }
    
    // MARK: - 内容区域
    @ViewBuilder
    private var contentArea: some View {
        if isLoading {
            loadingView
        } else {
            switch selectedTab {
            case .market:
                TradeMarketView()
            case .myOffers:
                TradeMyOffersView()
            case .history:
                TradeHistoryView()
            case .create:
                TradeCreateView(selectedTab: $selectedTab)
            }
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .orange))
                Text("交易系统加载中...").foregroundColor(.orange).font(.caption)
            }
        }
    }
    
    // MARK: - 加载初始数据
    private func loadInitialData() async {
        await tradeManager.fetchAllData()
        await MainActor.run { isLoading = false }
    }
}

// MARK: - 预览
struct TradeMainView_Previews: PreviewProvider {
    static var previews: some View {
        TradeMainView()
    }
}