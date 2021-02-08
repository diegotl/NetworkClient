//
//  File.swift
//  
//
//  Created by Diego Trevisan Lara on 25.01.21.
//

import Foundation
import Combine

public protocol APIErrorProtocol: Decodable, LocalizedError {}

public protocol APIClientProtocol {
    func execute<T: Decodable>(apiRequest: APIRequest) -> AnyPublisher<T, Error>
    func execute<T: Decodable, E: APIErrorProtocol>(apiRequest: APIRequest, errorType: E.Type) -> AnyPublisher<T, Error>
}
