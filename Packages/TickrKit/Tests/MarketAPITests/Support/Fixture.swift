import Foundation
import Testing

/// Testlerin okuduğu JSON dosyaları.
///
/// Bunlar elle uydurulmuş değil, Binance'ten canlı çekilmiş gerçek cevaplar
/// (`exchangeInfo` kısaltıldı, çünkü tam hali birkaç MB). Uydurma JSON
/// yazmanın sorunu şu: kendi hayalindeki biçimi test edersin, sunucunun
/// gönderdiğini değil.
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

/// Test içinde okunaklı `Decimal` yazmanın kısa yolu.
///
/// `Decimal(83588.15)` yazamayız: o önce `Double` olur ve değeri birebir
/// tutmaz — tam olarak kaçınmaya çalıştığımız hata. String'den ve sabit
/// locale ile kuruyoruz.
func dec(_ string: String, sourceLocation: SourceLocation = #_sourceLocation) throws -> Decimal {
    try #require(Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")),
                 "Geçersiz Decimal: \(string)",
                 sourceLocation: sourceLocation)
}
