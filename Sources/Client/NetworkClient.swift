import Foundation
import Combine
import Logging

// MARK: - Configuration

public final class NetworkClientConfiguration {
    let host: String
    let logger: Logger?
    let cachePolicy: NSURLRequest.CachePolicy

    public init(host: String = "", logger: Logger? = nil, cachePolicy: NSURLRequest.CachePolicy = .reloadIgnoringLocalAndRemoteCacheData) {
        self.host = host
        self.logger = logger
        self.cachePolicy = cachePolicy
    }
}

extension NetworkClient {
    static public var configuration: NetworkClientConfiguration = .init()
}

// MARK: - Error

public enum NetworkError: Error {
    case badContent
    case badRequest([String: Any]?, httpCode: Int)
    case invalidURL
    case unauthorized
}

// MARK: - Network

public final class NetworkClient: NetworkClientProtocol {
    // MARK: - Private variables
    private let adapters: [RequestAdapter]
    private let decoder: JSONDecoder

    // MARK: - Init

    public init(adapters: [RequestAdapter] = [], decoder: JSONDecoder = JSONDecoder()) {
        self.adapters = adapters
        self.decoder = decoder
    }

    // MARK: - Exposed functions

    public func request<T: Decodable>(urlRequest: URLRequest) -> AnyPublisher<T, Error> {
        var urlRequest = urlRequest
        adapters.forEach({ urlRequest = $0.adapt(urlRequest) })
        log(urlRequest: urlRequest)

        return makeSession()
            .dataTaskPublisher(for: urlRequest)
            .tryMap { [weak self] data, response in
                self?.adapters.forEach { $0.complete(request: urlRequest, response: response, data: data) }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.log(networkError: .badContent, urlRequest: urlRequest, responseBody: data)
                    throw NetworkError.badContent
                }

                guard (100..<400).contains(httpResponse.statusCode) else {
                    self?.log(httpResponse: httpResponse, urlRequest: urlRequest, responseBody: data)

                    if httpResponse.statusCode == 401 {
                        throw NetworkError.unauthorized
                    } else {
                        let responseBody = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] ?? nil
                        throw NetworkError.badRequest(responseBody, httpCode: httpResponse.statusCode)
                    }
                }

                self?.log(httpResponse: httpResponse, urlRequest: urlRequest)

                // If expecting an empty response, force it to be "{}" so that JSONDecoder
                // can decode the EmptyResponse object
                if data.isEmpty, EmptyResponse() is T {
                    return "{}".data(using: .utf8)!
                } else {
                    return data
                }
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error -> Error in
                return error
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

}

private extension NetworkClient {

    private func log(urlRequest: URLRequest) {
        let logger: Logger? = NetworkClient.configuration.logger
        guard let httpMethod = urlRequest.httpMethod, let absoluteString = urlRequest.url?.absoluteString else { return }

        var metadata: Logger.Metadata = .init()
        if let body = urlRequest.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            metadata["body"] = .string(bodyString)
        }

        if let requestHeaders = urlRequest.allHTTPHeaderFields?.metadataValue {
            metadata["request_headers"] = .dictionary(requestHeaders)
        }

        logger?.info("[\(httpMethod)] \(absoluteString)", metadata: metadata)
    }

    private func log(httpResponse: HTTPURLResponse, urlRequest: URLRequest, responseBody: Data? = nil) {
        let logger: Logger? = NetworkClient.configuration.logger
        guard let httpMethod = urlRequest.httpMethod, let absoluteString = httpResponse.url?.absoluteString else { return }

        if (100..<400).contains(httpResponse.statusCode) {
            logger?.info("[\(httpMethod)] \(absoluteString) -> \(httpResponse.statusCode)", metadata: ["http_status": .string("\(httpResponse.statusCode)")])
        } else {
            var metadata: Logger.Metadata = ["http_status": .string("\(httpResponse.statusCode)")]

            if let requestHeaders = urlRequest.allHTTPHeaderFields?.metadataValue {
                metadata["request_headers"] = .dictionary(requestHeaders)
            }

            if let responseHeaders = httpResponse.allHeaderFields.metadataValue {
                metadata["response_headers"] = .dictionary(responseHeaders)
            }

            if let responseBody = responseBody, let bodyString = String(data: responseBody, encoding: .utf8) {
                metadata["response_body"] = .string(bodyString)
            }

            logger?.error("[\(httpMethod)] \(absoluteString) -> \(httpResponse.statusCode)", metadata: metadata)
        }
    }

    private func log(networkError: NetworkError, urlRequest: URLRequest, responseBody: Data? = nil) {
        let logger: Logger? = NetworkClient.configuration.logger
        guard let absoluteString = urlRequest.url?.absoluteString else { return }

        var metadata: Logger.Metadata = ["network_error": .string(String(describing: networkError))]

        if let requestHeaders = urlRequest.allHTTPHeaderFields?.metadataValue {
            metadata["request_headers"] = .dictionary(requestHeaders)
        }

        if let responseBody = responseBody, let bodyString = String(data: responseBody, encoding: .utf8) {
            metadata["response_body"] = .string(bodyString)
        }

        logger?.error("\(absoluteString) -> \(networkError.localizedDescription)", metadata: metadata)
    }

}

private extension NetworkClient {

    func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        configuration.requestCachePolicy = NetworkClient.configuration.cachePolicy

        return URLSession(configuration: configuration, delegate: SessionDelegate(), delegateQueue: nil)
    }

}
