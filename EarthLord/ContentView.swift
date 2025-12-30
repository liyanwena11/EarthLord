//
//  ContentView.swift
//  EarthLord
//
//  Created by lyanwen on 2025/12/30.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")

                Spacer()
                    .frame(height: 30)

                Text("Developed by lyanwen")
                    .font(.headline)
                    .foregroundColor(.blue)

                Spacer()
                    .frame(height: 20)

                NavigationLink(destination: TestView()) {
                    Text("进入测试页")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
