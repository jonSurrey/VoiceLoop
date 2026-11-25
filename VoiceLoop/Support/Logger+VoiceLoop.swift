import Foundation
import os

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "VoiceLoop"

    static let network = Logger(subsystem: subsystem, category: "network")
    static let audio = Logger(subsystem: subsystem, category: "audio")
}
