import Foundation
import Logging

extension Dictionary where Key == String, Value == String {

    var metadataValue: [String: Logger.MetadataValue]? {
        let result: [String: Logger.MetadataValue] = reduce([String: Logger.MetadataValue](), { partialResult, pair in
            var partialResult = partialResult
            partialResult[pair.key] = .string(pair.value)
            return partialResult
        })

        guard !result.isEmpty else { return nil }
        return result
    }

}

extension Dictionary where Key == AnyHashable, Value == Any {

    var metadataValue: [String: Logger.MetadataValue]? {
        let result: [String: Logger.MetadataValue] = reduce([String: Logger.MetadataValue]()) { partialResult, pair in
            var partialResult = partialResult
            guard let key = pair.key as? String, let value = pair.value as? String else { return partialResult }
            partialResult[key] = .string(value)
            return partialResult
        }

        guard !result.isEmpty else { return nil }
        return result
    }

}
