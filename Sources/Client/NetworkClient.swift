import Foundation
import Combine

// MARK: - Configuration

final class NetworkClientConfiguration {
    var host: String = ""
}

extension NetworkClient {
    static var configuration: NetworkClientConfiguration = .init()
}

// MARK: - Error

public enum NetworkError: Error {
    case badContent
    case badRequest([String: Any]?, httpCode: Int)
    case invalidURL
    case unauthorized
}

// MARK: - Network

public class NetworkClient: NetworkClientProtocol {
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
        var request = urlRequest
        adapters.forEach({ request = $0.adapt(request) })

        return makeSession()
            .dataTaskPublisher(for: urlRequest)
            .tryMap { [weak self] data, response in
                self?.adapters.forEach { $0.complete(request: request, response: response, data: data) }

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.badContent
                }

                guard (200..<300).contains(httpResponse.statusCode) else {
                    if httpResponse.statusCode == 401 {
                        throw NetworkError.unauthorized
                    } else {
                        let body = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] ?? nil
                        throw NetworkError.badRequest(body, httpCode: httpResponse.statusCode)
                    }
                }

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

    func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120

        return URLSession(configuration: configuration)
    }

}
