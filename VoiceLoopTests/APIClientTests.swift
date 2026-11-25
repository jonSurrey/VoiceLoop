import Foundation
import Testing
@testable import VoiceLoop

@Suite("API client")
struct APIClientTests {
    private struct Reply: Decodable, Equatable {
        let text: String
    }

    private let endpoint = "https://example.com/chat"

    @Test("A successful response is decoded and the request is authorised JSON")
    func successfulResponse() async throws {
        let http = try StubHTTPClient(statusCode: 200, body: #"{"text":"hi"}"#)
        let client = APIClient(apiKey: "key", httpClient: http)

        let reply: Reply = try await client.post(["question": "hello"], to: endpoint)

        #expect(reply == Reply(text: "hi"))
        let request = try #require(http.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer key")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("A missing API key fails before any request is sent")
    func missingAPIKey() async throws {
        let http = try StubHTTPClient(statusCode: 200, body: "{}")
        let client = APIClient(apiKey: "", httpClient: http)

        await #expect(throws: APIError.missingAPIKey) {
            let _: Reply = try await client.post(["question": "hello"], to: endpoint)
        }
        #expect(http.requests.isEmpty)
    }

    @Test("A non-success status becomes a server error", arguments: [401, 429, 500])
    func serverError(statusCode: Int) async throws {
        let client = APIClient(apiKey: "key", httpClient: try StubHTTPClient(statusCode: statusCode, body: "{}"))

        await #expect(throws: APIError.server(statusCode: statusCode)) {
            let _: Reply = try await client.post(["question": "hello"], to: endpoint)
        }
    }

    @Test("A transport failure becomes a network error")
    func transportFailure() async throws {
        let http = try StubHTTPClient(statusCode: 200, body: "{}")
        http.result = .failure(URLError(.notConnectedToInternet))
        let client = APIClient(apiKey: "key", httpClient: http)

        await #expect(throws: APIError.network) {
            let _: Reply = try await client.post(["question": "hello"], to: endpoint)
        }
    }

    @Test("A body that doesn't match the response type is an invalid response")
    func undecodableBody() async throws {
        let client = APIClient(apiKey: "key", httpClient: try StubHTTPClient(statusCode: 200, body: "not json"))

        await #expect(throws: APIError.invalidResponse) {
            let _: Reply = try await client.post(["question": "hello"], to: endpoint)
        }
    }
}

@Suite("Chat completion request")
struct ChatCompletionRequestTests {
    @Test("Messages map to roles and content in order")
    func mapsMessages() {
        let messages = [Message(role: .user, content: "Hi"), Message(role: .assistant, content: "Hello")]

        let request = ChatCompletionRequest(model: "model", messages: messages)

        #expect(request.model == "model")
        #expect(request.messages == [.init(role: "user", content: "Hi"), .init(role: "assistant", content: "Hello")])
    }
}
