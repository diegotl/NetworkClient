@testable import APIClient

enum TestEnvironment: APIEnvionment {
    case httpbin
    case weather
    case apple

    var baseUrl: String {
        switch self {
        case .httpbin: return "https://httpbin.org"
        case .weather: return "https://api.weather.com/v3"
        case .apple: return "https://www.apple.com"
        }
    }
}

enum Path: APIEndpointPath {
    case json
    case location
    case image

    var value: String {
        switch self {
        case .json: return "/json"
        case .location: return "/location/search?format=json"
        case .image: return "/ac/structured-data/images/knowledge_graph_logo.png"
        }
    }
}

