@testable import APIClient

enum TestEnvironment: APIEnvionment {
    case httpbin
    case weather

    var baseUrl: String {
        switch self {
        case .httpbin: return "https://httpbin.org"
        case .weather: return "https://api.weather.com/v3"
        }
    }
}

enum Path: APIEndpointPath {
    case json
    case location

    var value: String {
        switch self {
        case .json: return "/json"
        case .location: return "/location/search?format=json"
        }
    }
}

