import Foundation

public enum NetworkError: Error, LocalizedError, CustomNSError {
    case invalidURL
    case badContent(LogData)
    case badRequest(LogData)
    case unauthorized(LogData)
    case finishedWithoutValue(LogData)

    public static var errorDomain: String {
        "NetworkError"
    }

    public var errorCode: Int {
        switch self {
        case .invalidURL:           return 100
        case .badContent:           return 102
        case .badRequest:           return 103
        case .unauthorized:         return 104
        case .finishedWithoutValue: return 105
        }
    }

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .badContent:
            return "Could not cast URLResponse as HTTPURLResponse"
        case .badRequest:
            return "Response status code not within expected range"
        case .unauthorized:
            return "Unauthorized"
        case .finishedWithoutValue:
            return "Finished without value"
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case .invalidURL:
            return [:]
        case .badContent(let logData), .badRequest(let logData), .unauthorized(let logData), .finishedWithoutValue(let logData):
            return logData.metadata
        }
    }
}
