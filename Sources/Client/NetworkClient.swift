import Foundation
import Combine
import Logging

// MARK: - NetworkClientProtocol

public protocol NetworkClientProtocol {
    func request<T: Decodable>(urlRequest: URLRequest) -> AnyPublisher<T, Error>
    func request<T: Decodable>(urlRequest: URLRequest) async throws -> T

    func download(urlRequest: URLRequest, destination: URL, fileManager: FileManager) -> AnyPublisher<URL, Error>
    func download(urlRequest: URLRequest, destination: URL, fileManager: FileManager) async throws -> URL
}

// MARK: - NetworkClient

public final class NetworkClient: NetworkClientProtocol {
    // MARK: - Static variables
    static public var configuration: NetworkClientConfiguration = .init()

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
        let logger: Logger? = NetworkClient.configuration.logger

        var urlRequest = urlRequest
        adapters.forEach({ urlRequest = $0.adapt(urlRequest) })

        let logData = LogData(urlRequest: urlRequest)
        logger?.info("\(logData.message)", metadata: logData.metadata)

        return makeSession()
            .dataTaskPublisher(for: urlRequest)
            .tryMap { [weak self] data, response in
                self?.adapters.forEach { $0.complete(request: urlRequest, response: response, data: data) }

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.badContent(.init(urlRequest: urlRequest, responseBody: data, logResponse: true))
                }

                guard (100..<400).contains(httpResponse.statusCode) else {
                    let logData = LogData(urlRequest: urlRequest, httpResponse: httpResponse, responseBody: data, logResponse: true)
                    logger?.error("\(logData.message)", metadata: logData.metadata)

                    if httpResponse.statusCode == 401 {
                        throw NetworkError.unauthorized(logData)
                    } else {
                        throw NetworkError.badRequest(logData)
                    }
                }

                let logData = LogData(urlRequest: urlRequest, httpResponse: httpResponse, responseBody: data)
                logger?.info("\(logData.message)", metadata: logData.metadata)

                // If expecting an empty response, force it to be "{}" so that JSONDecoder
                // can decode the EmptyResponse object
                if data.isEmpty, EmptyResponse() is T {
                    return "{}".data(using: .utf8)!
                } else {
                    return data
                }
            }
            .decode(type: T.self, decoder: decoder)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    public func request<T: Decodable>(urlRequest: URLRequest) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var finishedWithoutValue = true

            cancellable = request(urlRequest: urlRequest).first()
                .sink { result in
                    switch result {
                    case .finished:
                        if finishedWithoutValue {
                            continuation.resume(throwing: NetworkError.finishedWithoutValue(.init(urlRequest: urlRequest)))
                        }
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { (value: T) in
                    finishedWithoutValue = false
                    continuation.resume(with: .success(value))
                }
        }
    }

    public func download(urlRequest: URLRequest, destination: URL, fileManager: FileManager) -> AnyPublisher<URL, Error> {
        let logger: Logger? = NetworkClient.configuration.logger

        var urlRequest = urlRequest
        adapters.forEach({ urlRequest = $0.adapt(urlRequest) })

        let logData = LogData(urlRequest: urlRequest)
        logger?.info("\(logData.message)", metadata: logData.metadata)

        return Future { [weak self] promise in
            self?.makeSession()
                .downloadTask(with: urlRequest) { [weak self] url, response, error in
                    self?.adapters.forEach { $0.complete(request: urlRequest, response: response, data: nil) }

                    do {
                        if let error = error { throw error }
                        let sourcePath = url?.path ?? ""
                        try fileManager.moveItem(atPath: sourcePath, toPath: destination.path)
                        promise(.success(destination))
                    }
                    catch {
                        promise(.failure(error))
                    }
            }.resume()
        }.eraseToAnyPublisher()
    }

    public func download(urlRequest: URLRequest, destination: URL, fileManager: FileManager) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var finishedWithoutValue = true

            cancellable = download(urlRequest: urlRequest, destination: destination, fileManager: fileManager).first()
                .sink { result in
                    switch result {
                    case .finished:
                        if finishedWithoutValue {
                            continuation.resume(throwing: NetworkError.finishedWithoutValue(.init(urlRequest: urlRequest)))
                        }
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { (value: URL) in
                    finishedWithoutValue = false
                    continuation.resume(with: .success(value))
                }
        }
    }

    // MARK: - Private functions
    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        configuration.requestCachePolicy = NetworkClient.configuration.cachePolicy

        return URLSession(configuration: configuration, delegate: SessionDelegate(), delegateQueue: nil)
    }

}
