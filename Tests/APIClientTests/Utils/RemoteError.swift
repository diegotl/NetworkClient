@testable import APIClient

class RemoteError: APIErrorProtocol {
    let success: Bool
    
    var errorDescription: String? {
        return "This is a custom error"
    }
}
