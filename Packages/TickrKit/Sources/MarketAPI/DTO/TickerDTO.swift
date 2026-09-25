import Foundation
import MarketCore

/// `/api/v3/ticker/24hr` cevabındaki tek bir öğe.
///
/// Neden doğrudan `Ticker`'ı `Decodable` yapmıyoruz? Çünkü Binance'in
/// gönderdiği şey ile uygulamanın istediği şey birbirini tutmuyor:
///
/// | Binance          | Ticker        |
/// |------------------|---------------|
/// | `"83730.81"`     | `Decimal`     |
/// | `closeTime` (ms) | `Date`        |
/// | 22 alan          | ihtiyaç: 7    |
///
/// Bu çirkinlik MarketAPI'de kalırsa, yarın borsa alan adını değiştirdiğinde
/// ya da başka bir kaynağa geçtiğinde sadece bu dosya değişir; ekranlar,
/// alarm mantığı ve testler `Ticker`'ı görmeye devam eder.
///
/// `Decodable`, `Codable` değil: bu tipi asla geri JSON'a çevirmiyoruz.
struct TickerDTO: Decodable {
    let symbol: String
    let lastPrice: Decimal
    let openPrice: Decimal
    let highPrice: Decimal
    let lowPrice: Decimal
    let quoteVolume: Decimal
    /// Bu özetin kapsadığı pencerenin bitişi, Unix epoch'tan beri **milisaniye**.
    let closeTime: Int

    enum CodingKeys: String, CodingKey {
        case symbol, lastPrice, openPrice, highPrice, lowPrice, quoteVolume, closeTime
    }

    /// Fiyat alanlarının hepsi string geldiği için elle yazıldı.
    ///
    /// Parse edilemeyen bir fiyatta hata fırlatıyoruz, `0` koymuyoruz.
    /// Sessiz varsayılan burada tehlikeli: ekranda "BTC: 0,00 $" görünür,
    /// daha kötüsü "fiyat 60.000'in altına düştü" alarmı tetiklenir.
    /// Gürültülü hata, sessiz yanlış veriden iyidir.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        symbol = try container.decode(String.self, forKey: .symbol)
        lastPrice = try container.decodeDecimalString(forKey: .lastPrice)
        openPrice = try container.decodeDecimalString(forKey: .openPrice)
        highPrice = try container.decodeDecimalString(forKey: .highPrice)
        lowPrice = try container.decodeDecimalString(forKey: .lowPrice)
        quoteVolume = try container.decodeDecimalString(forKey: .quoteVolume)
        closeTime = try container.decode(Int.self, forKey: .closeTime)
    }

    /// Ağ katmanının tipini uygulamanın tipine çevirir.
    var ticker: Ticker {
        Ticker(
            symbol: symbol,
            lastPrice: lastPrice,
            openPrice: openPrice,
            highPrice: highPrice,
            lowPrice: lowPrice,
            quoteVolume: quoteVolume,
            updatedAt: Date(timeIntervalSince1970: TimeInterval(closeTime) / 1000)
        )
    }
}

extension KeyedDecodingContainer {
    /// `"83730.81000000"` → `Decimal`.
    ///
    /// İki tuzak var:
    ///
    /// 1. **`Double` üzerinden geçme.** `Decimal(Double("0.1")!)` ondalık
    ///    değeri birebir vermez; string'i doğrudan `Decimal`e çevirmek
    ///    kayıpsızdır. Fiyatları `Decimal` tutmanın tüm sebebi buydu.
    ///
    /// 2. **Locale.** `Decimal(string:)` verilen locale'in ondalık ayıracını
    ///    kullanır. Cihaz Türkçe iken `Decimal(string: "63250.12",
    ///    locale: Locale(identifier: "tr_TR"))` → `63250` döner; noktadan
    ///    sonrası sessizce düşer. Bu yüzden locale'i şansa bırakmıyoruz,
    ///    `en_US_POSIX` sabitliyoruz: sunucudan gelen sayı bir metin değil,
    ///    bir veri biçimi — kullanıcının diliyle ilgisi yok.
    func decodeDecimalString(forKey key: Key) throws -> Decimal {
        let raw = try decode(String.self, forKey: key)
        guard let value = Decimal(string: raw, locale: .posix) else {
            // `DecodingError` fırlatıyoruz, kendi hata tipimizi değil: Courier
            // bunu `NetworkError.decoding(_, raw:)` içine ham gövdeyle birlikte
            // sarıyor, yani hata mesajında hem hangi alan hem de sunucunun
            // tam olarak ne gönderdiği görünüyor.
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Sayıya çevrilemeyen fiyat: \"\(raw)\""
            )
        }
        return value
    }
}

extension Locale {
    /// Makineden makineye giden sayılar için sabit locale.
    static let posix = Locale(identifier: "en_US_POSIX")
}
