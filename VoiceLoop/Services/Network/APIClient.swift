import Foundation

final class APIClient {
    private let apiKey: String
    
    init(apiKey: String = APIConfig.openAIAPIKey) {
        self.apiKey = apiKey
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "POST",
        body: Data? = nil,
        contentType: String = "application/json"
    ) async throws -> T {
        guard APIConfig.isConfigured else {
            throw APIError.serverError("API key not configured. Please add your OpenAI API key.")
        }
        
        let request = try createRequest(
            endpoint: endpoint,
            method: method,
            body: body,
            contentType: contentType
        )
        
        Logger.logRequest(request)
        
        let (data, _) = try await performRequest(request)
        
        return try decodeResponse(data: data, type: T.self)
    }
    
    private func createRequest(
        endpoint: String,
        method: String,
        body: Data?,
        contentType: String
    ) throws -> URLRequest {
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 60.0
        
        return request
    }
    
    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.logResponse(data: data, response: response, error: nil)
                throw APIError.serverError("Invalid response from server")
            }
            
            Logger.logResponse(data: data, response: response, error: nil)
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.serverError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
            return (data, response)
        } catch let error as APIError {
            Logger.logResponse(data: nil, response: nil, error: error)
            throw error
        } catch {
            Logger.logResponse(data: nil, response: nil, error: error)
            throw APIError.networkError(error)
        }
    }
    
    private func decodeResponse<T: Decodable>(data: Data, type: T.Type) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            throw APIError.decodingError
        } catch {
            throw APIError.decodingError
        }
    }
}

