import Foundation
@testable import VoiceLoop

final class MockAudioRecorder: AudioRecording {
    var permission = true
    var startError: Error?
    let recordingFile = URL(fileURLWithPath: "recording.m4a")
    lazy var stopResult: URL? = recordingFile
    private(set) var deletedURLs: [URL] = []

    func requestPermission() async -> Bool {
        permission
    }

    func checkPermission() -> Bool {
        permission
    }

    func startRecording() throws -> URL {
        if let startError {
            throw startError
        }
        return recordingFile
    }

    func stopRecording() -> URL? {
        stopResult
    }

    func deleteRecording(at url: URL) {
        deletedURLs.append(url)
    }
}
