import Foundation
import Logging

public final class NetworkClientConfiguration {
    let host: String
    let logger: Logger?
    let cachePolicy: NSURLRequest.CachePolicy

    public init(host: String = "", logger: Logger? = nil, cachePolicy: NSURLRequest.CachePolicy = .reloadIgnoringLocalAndRemoteCacheData) {
        self.host = host
        self.logger = logger
        self.cachePolicy = cachePolicy
    }
}
