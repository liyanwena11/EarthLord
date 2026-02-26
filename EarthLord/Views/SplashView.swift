//
//  SplashView.swift
//  EarthLord
//
//  Created by lyanwen on 2025/12/30.
//

import SwiftUI
import AVKit
import UIKit

/// 启动页视图（带视频背景）
struct SplashView: View {
    /// 是否显示加载动画
    @State private var isAnimating = false

    /// Logo 缩放动画
    @State private var logoScale: CGFloat = 0.8

    /// Logo 透明度
    @State private var logoOpacity: Double = 0

    /// 是否完成加载
    @Binding var isFinished: Bool

    /// 视频播放器
    @State private var player: AVPlayer?

    /// 视频循环通知
    @State private var playerLoopObserver: NSObjectProtocol?

    /// 监听播放失败通知
    @State private var playerFailureObserver: NSObjectProtocol?

    /// 监听播放器 item 状态
    @State private var playerItemStatusObserver: NSKeyValueObservation?

    /// 避免 onAppear 重复触发时重复初始化
    @State private var hasStarted = false

    /// 避免重复结束开屏
    @State private var hasFinished = false

    var body: some View {
        ZStack {
            // 1. 视频背景层
            if let player = player {
                SplashVideoPlayer(player: player)
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
            } else {
                // 视频加载失败时的备用背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.10, green: 0.10, blue: 0.18),
                        Color(red: 0.09, green: 0.13, blue: 0.24),
                        Color(red: 0.06, green: 0.06, blue: 0.10)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            // 2. 渐变叠加层（让文字更清晰）
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.6)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Logo
                ZStack {
                    // 外圈光晕（呼吸动画）
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    ApocalypseTheme.primary.opacity(0.3),
                                    ApocalypseTheme.primary.opacity(0)
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isAnimating
                        )

                    // Logo 圆形背景
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    ApocalypseTheme.primary,
                                    ApocalypseTheme.primary.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: ApocalypseTheme.primary.opacity(0.5), radius: 20)

                    // 地球图标
                    Image(systemName: "globe.asia.australia.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // 标题
                VStack(spacing: 8) {
                    Text("末世领主")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    Text("EARTH LORD")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ApocalypseTheme.textSecondary)
                        .tracking(4)
                }
                .opacity(logoOpacity)

                Spacer()

                // 加载指示器
                VStack(spacing: 16) {
                    // 三点加载动画
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(ApocalypseTheme.primary)
                                .frame(width: 10, height: 10)
                                .scaleEffect(isAnimating ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }

                    // 加载文字
                    Text("正在启动系统...")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            LogDebug("🎬 [SplashView] onAppear 被调用")
            setupVideo()
            startAnimations()
            simulateLoading()
        }
        .onDisappear {
            // 清理播放器
            player?.pause()
            player = nil
            if let observer = playerLoopObserver {
                NotificationCenter.default.removeObserver(observer)
                playerLoopObserver = nil
            }
            if let observer = playerFailureObserver {
                NotificationCenter.default.removeObserver(observer)
                playerFailureObserver = nil
            }
            playerItemStatusObserver = nil
        }
    }

    // MARK: - 设置视频

    private func setupVideo() {
        if let url = locateSplashVideoURL() {
            LogInfo("🎬 [SplashView] 找到启动视频: \(url.path)")
            setupPlayer(with: url)
            return
        }
        LogWarning("⚠️ [SplashView] 未找到 splash_video.mp4，使用渐变背景")
    }

    private func locateSplashVideoURL() -> URL? {
        let candidates: [URL?] = [
            Bundle.main.url(forResource: "splash_video", withExtension: "mp4"),
            Bundle.main.url(forResource: "splash_video", withExtension: "mp4", subdirectory: "Resources"),
            Bundle.main.resourceURL?.appendingPathComponent("splash_video.mp4"),
            Bundle.main.resourceURL?.appendingPathComponent("Resources/splash_video.mp4"),
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
                .appendingPathComponent("splash_video.mp4")
        ]

        for url in candidates.compactMap({ $0 }) {
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }

    private func setupPlayer(with url: URL) {
        let playerItem = AVPlayerItem(url: url)

        self.playerItemStatusObserver = playerItem.observe(\.status, options: [.new]) { item, _ in
            guard item.status == .failed else { return }
            let reason = item.error?.localizedDescription ?? "未知错误"
            DispatchQueue.main.async {
                LogError("❌ [SplashView] 启动视频播放失败: \(reason)")
                self.player?.pause()
                self.player = nil
            }
        }

        if let observer = self.playerFailureObserver {
            NotificationCenter.default.removeObserver(observer)
            self.playerFailureObserver = nil
        }
        self.playerFailureObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { notification in
            let reason = (notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)?
                .localizedDescription ?? "未知错误"
            LogError("❌ [SplashView] 启动视频播放中断: \(reason)")
            self.player?.pause()
            self.player = nil
        }

        if let observer = self.playerLoopObserver {
            NotificationCenter.default.removeObserver(observer)
            self.playerLoopObserver = nil
        }

        let avPlayer = AVPlayer(playerItem: playerItem)
        avPlayer.isMuted = true
        avPlayer.actionAtItemEnd = .pause

        self.playerLoopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            LogInfo("✅ [SplashView] 启动视频播放完成")
            self.finishSplash()
        }

        self.player = avPlayer
        avPlayer.play()
        LogInfo("✅ [SplashView] 启动视频开始播放")
    }

    // MARK: - 动画方法

    private func startAnimations() {
        // Logo 入场动画
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // 启动循环动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = true
        }
    }

    // MARK: - 加载流程

    private func simulateLoading() {
        LogDebug("🎬 [SplashView] 设置开屏兜底计时器")
        // 兜底：8 秒内无论如何都结束开屏，避免用户被卡住
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            self.finishSplash()
        }
    }

    private func finishSplash() {
        guard !hasFinished else { return }
        hasFinished = true
        withAnimation(.easeInOut(duration: 0.25)) {
            isFinished = true
        }
        LogInfo("✅ [SplashView] 开屏结束，进入主界面")
    }
}

private struct SplashVideoPlayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer {
        // swiftlint:disable:next force_cast
        layer as! AVPlayerLayer
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}
