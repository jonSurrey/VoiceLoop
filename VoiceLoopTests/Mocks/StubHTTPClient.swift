import Foundation
import Testing
@testable import VoiceLoop

final class StubHTTPClient: HTTPClient {
    var result: Result<(Data, URLResponse), Error>
    private(set) var requests: [URLRequest] = []

    init(statusCode: Int, body: String) throws {
        let url = URL(fileURLWithPath: "stub")
        let response = try #require(HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil))
        result = .success((Data(body.utf8), response))
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        return try result.get()
    }
}
