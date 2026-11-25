import Foundation
import AVFoundation

final class AudioRecordingService: NSObject, AudioRecordingProtocol {
    
    // MARK: - Properties
    
    var isRecording: Bool {
        audioRecorder?.isRecording ?? false
    }
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession
    private var currentRecordingURL: URL?
    
    // MARK: - Initialization
    
    override init() {
        self.audioSession = .sharedInstance()
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleInterruption),
                name: AVAudioSession.interruptionNotification,
                object: audioSession
            )
        } catch {
            print("Failed to setup audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Permissions
    
    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }
    
    func checkPermission() -> Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }
    
    // MARK: - Recording
    
    func startRecording() throws -> URL {
        if isRecording {
            audioRecorder?.stop()
        }
        
        if !audioSession.isOtherAudioPlaying {
            try? audioSession.setActive(true)
        }
        
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let recordingURL = getTemporaryDirectory().appendingPathComponent(fileName)
        
        let recorder = try AVAudioRecorder(url: recordingURL, settings: AudioSettings.recordingSettings)
        recorder.delegate = self
        
        guard recorder.prepareToRecord() else {
            throw RecordingError.failedToStart
        }
        
        guard recorder.record() else {
            throw RecordingError.failedToStart
        }
        
        audioRecorder = recorder
        currentRecordingURL = recordingURL
        return recordingURL
    }
    
    func stopRecording() -> URL? {
        defer {
            audioRecorder = nil
        }
        
        guard let recorder = audioRecorder, recorder.isRecording else {
            return currentRecordingURL
        }
        
        recorder.stop()
        return currentRecordingURL
    }
    
    // MARK: - File Management
    
    private func getTemporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
    }
    
    func deleteRecording(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    // MARK: - Interruption Handling
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began && isRecording {
            audioRecorder?.stop()
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        try? audioSession.setActive(false)
    }
}

// MARK: - Recording Errors

enum RecordingError: LocalizedError {
    case failedToStart
    
    var errorDescription: String? {
        switch self {
        case .failedToStart:
            return "Couldn't start recording. Please try again."
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording did not finish successfully")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording encoding error: \(error.localizedDescription)")
        }
    }
}


