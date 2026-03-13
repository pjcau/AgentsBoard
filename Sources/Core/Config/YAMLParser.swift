// MARK: - YAML Parser (DIP wrapper around Yams)
// This is the ONLY file that imports Yams.

import Foundation
import Yams

/// Concrete implementation wrapping Yams behind YAMLParsing protocol.
struct YAMLParserImpl: YAMLParsing {

    func decode<T: Decodable>(_ type: T.Type, from yaml: String) throws -> T {
        let decoder = YAMLDecoder()
        return try decoder.decode(type, from: yaml)
    }

    func encode<T: Encodable>(_ value: T) throws -> String {
        let encoder = YAMLEncoder()
        return try encoder.encode(value)
    }
}
