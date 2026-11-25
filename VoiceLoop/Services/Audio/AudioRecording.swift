import Foundation
import AVFoundation

protocol AudioRecording {
    var isRecording: Bool { get }
    
    func requestPermission() async -> Bool
    func checkPermission() -> Bool
    func startRecording() throws -> URL
    func stopRecording() -> URL?
    func deleteRecording(at url: URL)
}

