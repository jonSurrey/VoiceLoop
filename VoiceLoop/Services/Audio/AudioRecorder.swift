import AVFoundation
import os

final class AudioRecorder: NSObject, AudioRecording {
    var onInterruption: (() -> Void)?

    private let session = AVAudioSession.sharedInstance()
    private var recorder: AVAudioRecorder?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionWasInterrupted(_:)),
            name: AVAudioSession.interruptionNotification,
            object: session
        )
    }

    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func checkPermission() -> Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }

    func startRecording() throws {
        do {
            try session.setCategory(.record, mode: .default, options: .allowBluetoothHFP)
            try session.setActive(true)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(AudioSettings.fileExtension)
            let recorder = try AVAudioRecorder(url: url, settings: AudioSettings.recordingSettings)
            guard recorder.record() else {
                throw RecordingError.failedToStart
            }
            self.recorder = recorder
        } catch {
            Logger.audio.error("Recording failed to start: \(error.localizedDescription, privacy: .public)")
            deactivateSession()
            throw RecordingError.failedToStart
        }
    }

    func stopRecording() -> URL? {
        guard let recorder else {
            return nil
        }
        recorder.stop()
        self.recorder = nil
        deactivateSession()
        return recorder.url
    }

    func deleteRecording(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            Logger.audio.error("Recording couldn't be deleted: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func deactivateSession() {
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            Logger.audio.error("Audio session couldn't be deactivated: \(error.localizedDescription, privacy: .public)")
        }
    }

    @objc private nonisolated func sessionWasInterrupted(_ notification: Notification) {
        guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: rawType) == .began else {
            return
        }
        Task { @MainActor in
            self.interruptionBegan()
        }
    }

    private func interruptionBegan() {
        guard recorder != nil else {
            return
        }
        onInterruption?()
    }
}

enum RecordingError: LocalizedError {
    case failedToStart

    var errorDescription: String? {
        switch self {
        case .failedToStart:
            "Couldn't start recording. Please try again."
        }
    }
}
