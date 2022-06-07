import Foundation

extension Decodable {
    
    typealias T = Self
    
    static func decode(data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
            
        } catch let error {
            throw error
        }
    }
    
}

extension Encodable {
    var data: Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try? encoder.encode(self)
    }

    var dictionary: [String: Any]? {
        guard let data = data else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
    }

    var queryString: String? {
        guard let dictionary = dictionary else { return nil }
        return encode(dictionary)
    }

    private func encode(_ dictionary: [String: Any]) -> String {
        return dictionary.compactMap { (key, value) -> String? in
            if value is [String: Any] {
                if let dictionary = value as? [String: Any] {
                    return encode(dictionary)
                }
            } else {
                return "\(key)=\(value)"
            }

            return nil
        }.joined(separator: "&")
    }
}
