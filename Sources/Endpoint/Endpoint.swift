import Foundation

public enum RequestMethod: String {
    case get    = "GET"
    case post   = "POST"
    case delete = "DELETE"
    case put    = "PUT"
    case patch  = "PATCH"
}

public protocol Endpoint {
    var method: RequestMethod { get }
    var host: String { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
    var body: Encodable? { get }
    var contentType: String? { get }

    func makeRequest() throws -> URLRequest
}

public extension Endpoint {

    var queryItems: [URLQueryItem] {
        []
    }

    var body: Encodable? {
        nil
    }

    var contentType: String? {
        nil
    }

    func makeRequest() throws -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = host
        urlComponents.path = path

        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = body?.data

        if let contentType = contentType {
            urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")

            switch contentType {
            case "application/x-www-form-urlencoded":
                urlRequest.httpBody = body?.queryString?.data(using: .utf8)
            default:
                urlRequest.httpBody = body?.data
            }
        }

        return urlRequest
    }

}
