import Foundation

protocol AudioRecording: AnyObject {
    var onInterruption: (() -> Void)? { get set }

    func requestPermission() async -> Bool
    func checkPermission() -> Bool
    func startRecording() throws
    func stopRecording() -> URL?
    func deleteRecording(at url: URL)
}
