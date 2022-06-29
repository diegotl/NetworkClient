import Foundation
import Logging

public final class LogData {
    // MARK: - Private variables
    private let logResponse: Bool

    // MARK: - Public variables
    public let urlRequest: URLRequest
    public let httpResponse: HTTPURLResponse?
    public let responseBody: Data?

    var message: String {
        guard
            let httpMethod = urlRequest.httpMethod,
            let urlString = urlRequest.url?.absoluteString
        else {
            return "No method or URL to log"
        }

        var message = "[\(httpMethod)] \(urlString)"
        if let responseCode = httpResponse?.statusCode {
            message += " -> \(responseCode)"
        }
        return message
    }

    var metadata: Logger.Metadata {
        var metadata: Logger.Metadata = .init()

        if let urlString = urlRequest.url?.absoluteString {
            metadata["url"] = .string(urlString)
        }

        if let httpMethod = urlRequest.httpMethod {
            metadata["http_method"] = .string(httpMethod)
        }

        if let requestHeaders = urlRequest.allHTTPHeaderFields?.metadataValue {
            metadata["request_headers"] = .dictionary(requestHeaders)
        }

        if let body = urlRequest.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            metadata["request_body"] = .string(bodyString)
        }

        if let responseHeaders = httpResponse?.allHeaderFields.metadataValue {
            metadata["response_headers"] = .dictionary(responseHeaders)
        }

        if let responseCode = httpResponse?.statusCode {
            metadata["response_code"] = .string("\(responseCode)")
        }

        if logResponse, let responseBody = responseBody, let bodyString = String(data: responseBody, encoding: .utf8) {
            metadata["response_body"] = .string(bodyString)
        }

        return metadata
    }

    init(urlRequest: URLRequest, httpResponse: HTTPURLResponse? = nil, responseBody: Data? = nil, logResponse: Bool = false) {
        self.httpResponse = httpResponse
        self.urlRequest = urlRequest
        self.responseBody = responseBody
        self.logResponse = logResponse
    }

}
