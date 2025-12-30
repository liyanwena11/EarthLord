//
//  TestView.swift
//  EarthLord
//
//  Created by lyanwen on 2025/12/30.
//

import SwiftUI

struct TestView: View {
    var body: some View {
        ZStack {
            // 淡蓝色背景
            Color(red: 0.7, green: 0.85, blue: 0.95)
                .ignoresSafeArea()

            // 大标题
            Text("这里是分支宇宙的测试页")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

#Preview {
    TestView()
}
