//
//  AudioRecordManager.swift
//  EarthLord
//
//  音频录制和播放管理器 - Day 36 PTT 语音功能
//

import Foundation
import AVFoundation
import Combine
@preconcurrency import AVFAudio

class AudioRecordManager: NSObject, ObservableObject {
    static let shared = AudioRecordManager()

    // MARK: - Published Properties

    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var currentPlayingURL: URL?

    // MARK: - Private Properties

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var playbackTimer: Timer?

    private let recordingSession = AVAudioSession.sharedInstance()

    // 音频文件存储路径
    private var audioFilesDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioPath = documentsPath.appendingPathComponent("AudioMessages")

        // 创建目录（如果不存在）
        try? FileManager.default.createDirectory(at: audioPath, withIntermediateDirectories: true)

        return audioPath
    }

    private override init() {
        super.init()
        setupAudioSession()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            LogDebug("🎤 [音频] 录音会话设置成功")
        } catch {
            LogError("❌ [音频] 录音会话设置失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Permission

    func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            // iOS 17+ 使用新 API
            do {
                let granted = try await AVAudioApplication.requestRecordPermission()
                if granted {
                    LogInfo("🎤 [音频] 麦克风权限已授予")
                } else {
                    LogWarning("⚠️ [音频] 麦克风权限被拒绝")
                }
                return granted
            } catch {
                LogError("❌ [音频] 请求麦克风权限失败: \(error.localizedDescription)")
                return false
            }
        } else {
            // iOS 16 及以下使用旧 API
            await withCheckedContinuation { continuation in
                recordingSession.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                    if granted {
                        LogInfo("🎤 [音频] 麦克风权限已授予")
                    } else {
                        LogWarning("⚠️ [音频] 麦克风权限被拒绝")
                    }
                }
            }
        }
    }

    var hasMicrophonePermission: Bool {
        if #available(iOS 17.0, *) {
            return AVAudioApplication.shared.recordPermission == .granted
        } else {
            return recordingSession.recordPermission == .granted
        }
    }

    // MARK: - Recording

    /// 开始录音
    @discardableResult
    func startRecording() -> Bool {
        guard hasMicrophonePermission else {
            LogWarning("⚠️ [音频] 没有麦克风权限")
            return false
        }

        guard !isRecording else {
            LogWarning("⚠️ [音频] 正在录音中")
            return false
        }

        // 生成文件名（时间戳）
        let filename = "voice_\(Int(Date().timeIntervalSince1970)).m4a"
        let fileURL = audioFilesDirectory.appendingPathComponent(filename)

        // 录音设置
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            // 开始计时
            recordingDuration = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.recordingDuration += 0.1
            }

            DispatchQueue.main.async {
                self.isRecording = true
            }

            LogInfo("🎤 [音频] 开始录音: \(filename)")
            return true
        } catch {
            LogError("❌ [音频] 开始录音失败: \(error.localizedDescription)")
            return false
        }
    }

    /// 停止录音并返回音频文件信息
    func stopRecording() -> (url: URL, duration: TimeInterval)? {
        guard isRecording, let recorder = audioRecorder else {
            LogWarning("⚠️ [音频] 没有正在进行的录音")
            return nil
        }

        recorder.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil

        let url = recorder.url
        let duration = recorder.currentTime

        audioRecorder = nil

        DispatchQueue.main.async {
            self.isRecording = false
            self.recordingDuration = 0
        }

        LogInfo("✅ [音频] 录音完成: \(url.lastPathComponent), 时长: \(String(format: "%.1f", duration))秒")
        return (url: url, duration: duration)
    }

    /// 取消录音（删除文件）
    func cancelRecording() {
        guard isRecording, let recorder = audioRecorder else { return }

        let url = recorder.url
        recorder.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil

        // 删除文件
        try? FileManager.default.removeItem(at: url)

        audioRecorder = nil

        DispatchQueue.main.async {
            self.isRecording = false
            self.recordingDuration = 0
        }

        LogDebug("🗑️ [音频] 录音已取消并删除")
    }

    // MARK: - Playback

    /// 播放音频
    @discardableResult
    func playAudio(url: URL) -> Bool {
        guard !isPlaying else {
            LogWarning("⚠️ [音频] 正在播放中")
            return false
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()

            if audioPlayer?.play() == true {
                DispatchQueue.main.async {
                    self.isPlaying = true
                    self.currentPlayingURL = url
                }
                LogInfo("🔊 [音频] 开始播放: \(url.lastPathComponent)")
                return true
            } else {
                LogError("❌ [音频] 播放失败")
                return false
            }
        } catch {
            LogError("❌ [音频] 播放失败: \(error.localizedDescription)")
            return false
        }
    }

    /// 停止播放
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil

        playbackTimer?.invalidate()
        playbackTimer = nil

        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentPlayingURL = nil
        }

        LogDebug("⏹️ [音频] 停止播放")
    }

    // MARK: - File Management

    /// 获取音频文件大小（MB）
    func getFileSize(url: URL) -> Double {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? UInt64 {
                return Double(fileSize) / 1024.0 / 1024.0
            }
        } catch {
            LogError("❌ [音频] 获取文件大小失败: \(error.localizedDescription)")
        }
        return 0
    }

    /// 删除音频文件
    func deleteAudioFile(url: URL) {
        try? FileManager.default.removeItem(at: url)
        LogDebug("🗑️ [音频] 删除音频文件: \(url.lastPathComponent)")
    }

    /// 格式化时长显示
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// 清理所有音频文件
    func clearAllAudioFiles() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: audioFilesDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            LogInfo("🗑️ [音频] 已清理所有音频文件")
        } catch {
            LogError("❌ [音频] 清理音频文件失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecordManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            LogDebug("✅ [音频] 录音完成")
        } else {
            LogError("❌ [音频] 录音失败")
            DispatchQueue.main.async {
                self.isRecording = false
                self.recordingDuration = 0
            }
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            LogError("❌ [音频] 录音编码错误: \(error.localizedDescription)")
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioRecordManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentPlayingURL = nil
        }

        if flag {
            LogDebug("✅ [音频] 播放完成")
        } else {
            LogError("❌ [音频] 播放失败")
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            LogError("❌ [音频] 播放解码错误: \(error.localizedDescription)")
        }
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentPlayingURL = nil
        }
    }
}
