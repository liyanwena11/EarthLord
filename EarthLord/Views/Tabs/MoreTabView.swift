//
//  MoreTabView.swift
//  EarthLord
//
//  Created by lyanwen on 2025/12/30.
//

import SwiftUI

struct MoreTabView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background
                    .ignoresSafeArea()

                List {
                    Section("开发工具") {
                        NavigationLink {
                            SupabaseTestView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "network")
                                    .font(.title3)
                                    .foregroundColor(ApocalypseTheme.primary)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Supabase 连接测试")
                                        .font(.body)
                                        .foregroundColor(ApocalypseTheme.textPrimary)

                                    Text("检测数据库连接状态")
                                        .font(.caption)
                                        .foregroundColor(ApocalypseTheme.textSecondary)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listRowBackground(ApocalypseTheme.cardBackground)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("更多")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    MoreTabView()
}
