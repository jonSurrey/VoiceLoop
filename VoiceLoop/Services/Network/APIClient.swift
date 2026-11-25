import Foundation
import os

final class APIClient {
    private static let timeout: TimeInterval = 60

    private let apiKey: String
    private let httpClient: HTTPClient
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(apiKey: String, httpClient: HTTPClient = URLSession.shared) {
        self.apiKey = apiKey
        self.httpClient = httpClient
    }

    func post<Response: Decodable>(_ body: some Encodable, to endpoint: String) async throws -> Response {
        guard !apiKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: Self.timeout)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encode(body)

        let (data, response) = try await send(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        Logger.network.debug("POST \(url.absoluteString, privacy: .public) → \(httpResponse.statusCode)")
        guard HTTPStatus.success.contains(httpResponse.statusCode) else {
            throw APIError.server(statusCode: httpResponse.statusCode)
        }
        return try decode(data)
    }

    private func encode(_ body: some Encodable) throws -> Data {
        do {
            return try encoder.encode(body)
        } catch {
            throw APIError.invalidRequest
        }
    }

    private func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await httpClient.data(for: request)
        } catch let error as URLError {
            Logger.network.error("Request failed: \(error.localizedDescription, privacy: .public)")
            throw APIError.network
        }
    }

    private func decode<Response: Decodable>(_ data: Data) throws -> Response {
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }
}
