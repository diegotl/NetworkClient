//
//  File.swift
//  
//
//  Created by Diego Trevisan Lara on 25.01.21.
//

import Foundation
import Combine

public class APIClient: APIClientProtocol {

    let adapters: [RequestAdapter]

    public init(adapters: [RequestAdapter] = []) {
        self.adapters = adapters
    }

    public func execute<T: Decodable>(apiRequest: APIRequest) -> AnyPublisher<T, Error> {
        var request = apiRequest.build()
        adapters.forEach({ request = $0.adapt(request) })

        return URLSession
            .shared
            .dataTaskPublisher(for: request)
            .map { [weak self] (data, response) in
                self?.adapters.forEach { $0.complete(request: request, response: response, data: data) }
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    public func execute(apiRequest: APIRequest, accept statusCodes: [Int] = [200]) -> AnyPublisher<EmptyObject, Error> {
        var request = apiRequest.build()
        adapters.forEach({ request = $0.adapt(request) })

        return URLSession
            .shared
            .dataTaskPublisher(for: request)
            .tryMap { [weak self] (data, response) -> EmptyObject in
                self?.adapters.forEach { $0.complete(request: request, response: response, data: data) }

                guard let httpResponse = response as? HTTPURLResponse, statusCodes.contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }

                return EmptyObject()
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    public func execute<T: Decodable, E: APIErrorProtocol>(apiRequest: APIRequest, errorType: E.Type) -> AnyPublisher<T, Error> {
        var request = apiRequest.build()
        adapters.forEach({ request = $0.adapt(request) })

        return URLSession
            .shared
            .dataTaskPublisher(for: request)
            .tryMap { [weak self] (data, response) in
                self?.adapters.forEach { $0.complete(request: request, response: response, data: data) }

                if let decodedObject = try? JSONDecoder().decode(T.self, from: data) {
                    return decodedObject
                }
                
                throw try JSONDecoder().decode(E.self, from: data)
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    public func download(apiRequest: APIRequest, destination: URL, fileManager: FileManager = .default) -> AnyPublisher<URL, Error> {
        var request = apiRequest.build()
        adapters.forEach({ request = $0.adapt(request) })

        return Future { promise in
            URLSession.shared.downloadTask(with: request) { [weak self] url, response, error in
                self?.adapters.forEach { $0.complete(request: request, response: response, data: nil) }
                
                do {
                    if let error = error { throw error }
                    let sourcePath = url?.path ?? ""

                    // Deletes file if it exists
                    if fileManager.fileExists(atPath: destination.path) {
                        try fileManager.removeItem(atPath: destination.path)
                    }

                    // Creates directory if it doesn't exist
                    try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)

                    // Move downloaded file there
                    try fileManager.moveItem(atPath: sourcePath, toPath: destination.path)
                    promise(.success(destination))
                }
                catch {
                    promise(.failure(error))
                }
            }.resume()
        }.eraseToAnyPublisher()
    }

}
