//
//  APIRequest.swift
//  APIClient
//
//  Created by Diego Trevisan Lara on 12/01/18.
//  Copyright © 2018 Diego Trevisan Lara. All rights reserved.
//

import Foundation

public enum HTTPMethod {
    case options
    case get(_ queryString: Encodable? = nil)
    case head
    case post(_ paramater: Encodable? = nil)
    case put(_ paramater: Encodable? = nil)
    case patch(_ paramater: Encodable? = nil)
    case delete
    case trace
    case connect

    var value: String {
        switch self {
        case .options:   return "OPTIONS"
        case .get:       return "GET"
        case .head:      return "HEAD"
        case .post:      return "POST"
        case .put:       return "PUT"
        case .patch:     return "PATCH"
        case .delete:    return "DELETE"
        case .trace:     return "TRACE"
        case .connect:   return "CONNECT"
        }
    }
}

public enum ParameterEncoding {
    case formUrlEncoded
    case queryString
    case json
}

open class APIRequest {
    let endpoint: APIEndpoint
    let method: HTTPMethod
    let encoding: ParameterEncoding

    public init(endpoint: APIEndpoint, method: HTTPMethod = .get(nil), encoding: ParameterEncoding = .json) {
        self.endpoint = endpoint
        self.method = method
        self.encoding = encoding
    }

    func build(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 15) -> URLRequest {
        let url = URL(string: endpoint.url)!
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        request.httpMethod = method.value

        switch encoding {
        case .formUrlEncoded:
            request.allHTTPHeaderFields = ["Content-Type": "application/x-www-form-urlencoded"]
        case .json:
            request.allHTTPHeaderFields = ["Content-Type": "application/json"]
        case .queryString:
            request.allHTTPHeaderFields = ["Content-Type": "application/x-www-form-urlencoded"]
        }

        switch method {
        case .get(let queryString):
            guard let query = try? queryString?.json().queryString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { break }
            request.url = URL(string: "\(endpoint.url)?\(query)")!

        case .post(let parameter),
             .put(let parameter),
             .patch(let parameter):
            if encoding == .json {
                request.httpBody = try? parameter?.data()
            } else {
                request.httpBody = try? parameter?.json().queryString.data(using: .utf8)
            }

        default:
            break
        }

        return request
    }
}
