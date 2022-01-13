import Foundation
import Combine

public protocol NetworkClientProtocol {
    func request<T: Decodable>(urlRequest: URLRequest) -> AnyPublisher<T, Error>
}
