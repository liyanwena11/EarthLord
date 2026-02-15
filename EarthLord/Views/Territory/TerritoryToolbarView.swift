//
//  TerritoryToolbarView.swift
//  EarthLord
//
//  领地详情顶部悬浮工具栏
//

import SwiftUI

struct TerritoryToolbarView: View {
    var onDismiss: () -> Void
    var onBuildingBrowser: () -> Void
    @Binding var showInfoPanel: Bool

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }

            Spacer()

            Button {
                onBuildingBrowser()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "hammer.fill")
                    Text("建造")
                        .font(.headline)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(20)
            }

            Button {
                withAnimation {
                    showInfoPanel.toggle()
                }
            } label: {
                Image(systemName: showInfoPanel ? "info.circle.fill" : "info.circle")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

