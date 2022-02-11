import Foundation

final class SessionDelegate: NSObject, URLSessionDelegate {

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            let urlCredential = URLCredential(trust: trust)
            completionHandler(.useCredential, urlCredential)
        } else {
            NetworkClient.configuration.logger?.warning("SecTrust is null", metadata: ["session": .string(session.description)])
            completionHandler(.useCredential, nil)
        }
    }

}
