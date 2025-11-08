import Foundation

final class Logger {
    static func logRequest(_ request: URLRequest) {
        guard let url = request.url else { return }
        
        print("\n[REQUEST] \(request.httpMethod ?? "GET") \(url.absoluteString)")
        
        if let body = request.httpBody {
            if let jsonString = prettyPrintJSON(body) {
                print(jsonString)
            } else {
                print("Body: \(body.count) bytes")
                if let contentType = request.value(forHTTPHeaderField: "Content-Type"), contentType.contains("multipart") {
                    print("Content-Type: \(contentType)")
                }
            }
        }
    }
    
    static func logResponse(data: Data?, response: URLResponse?, error: Error?) {
        if let httpResponse = response as? HTTPURLResponse {
            print("[RESPONSE] Status \(httpResponse.statusCode)")
        }
        
        if let error = error {
            print("[ERROR] \(error.localizedDescription)")
        }
        
        if let data = data, let jsonString = prettyPrintJSON(data) {
            print(jsonString)
        }
        
        print("")
    }
    
    private static func prettyPrintJSON(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(
                withJSONObject: json,
                options: .prettyPrinted
              ),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return nil
        }
        return prettyString
    }
}

