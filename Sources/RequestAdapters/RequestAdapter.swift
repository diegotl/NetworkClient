//
//  RequestAdapter.swift
//  APIClient
//
//  Created by Diego Trevisan Lara on 20/06/18.
//  Copyright © 2018 Diego Trevisan Lara. All rights reserved.
//

import Foundation

public protocol RequestAdapter {
    func adapt(_ request: URLRequest) -> URLRequest
    func complete(request: URLRequest, response: URLResponse?, data: Data?)
}
