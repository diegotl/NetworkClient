import Foundation

public protocol RequestAdapter {
    func adapt(_ request: URLRequest) -> URLRequest
    func complete(request: URLRequest, response: URLResponse?, data: Data?)
}
