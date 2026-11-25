import Foundation
@testable import VoiceLoop

struct TestError: LocalizedError, RetryableError {
    var isRetryable = true
    var errorDescription: String? { "Test failure" }
}
