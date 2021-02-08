//
//  APIEndpoint.swift
//  APIClient
//
//  Created by Diego Trevisan Lara on 19/01/18.
//  Copyright © 2018 Diego Trevisan Lara. All rights reserved.
//

import Foundation

// MARK: - Environment

public protocol APIEnvionment {
    var baseUrl: String { get }
}

// MARK: - Endpoint Path

public protocol APIEndpointPath {
    var value: String { get }
}

// MARK: - Endpoint

open class APIEndpoint {
    let environment: APIEnvionment
    let path: APIEndpointPath
    
    public init(environment: APIEnvionment, path: APIEndpointPath) {
        self.environment = environment
        self.path = path
    }
    
    public var url: String {
        return "\(environment.baseUrl)\(path.value)"
    }
}
