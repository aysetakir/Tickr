import Foundation
import Testing

enum Fixture {
    static func data(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "json"),
            "Fixture bulunamadı: \(name).json"
        )
        return try Data(contentsOf: url)
    }

    static func decode<T: Decodable>(_ type: T.Type, from name: String) throws -> T {
        try JSONDecoder().decode(type, from: data(name))
    }
}

func dec(_ string: String, sourceLocation: SourceLocation = #_sourceLocation) throws -> Decimal {
    try #require(Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")),
                 "Geçersiz Decimal: \(string)",
                 sourceLocation: sourceLocation)
}
