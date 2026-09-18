import Foundation

/// Grafikteki tek bir mum: belli bir zaman aralığında fiyatın nerede açıldığı,
/// nereye kadar çıkıp indiği ve nerede kapandığı (OHLC).
///
/// Çizgi grafik çizerken sadece `close` kullanılır. OHLC'nin tamamını tutuyoruz,
/// çünkü mum grafiğe (candlestick) geçmek istersen model hazır olsun.
///
/// `Decimal` Swift Charts'ta doğrudan kullanılabiliyor (`Plottable`), yani
/// grafik için `Double`'a çevirmen gerekmiyor.
public struct Candle: Hashable, Codable, Sendable, Identifiable {
    /// Mumun başladığı an. Kimlik olarak da bu kullanılıyor.
    ///
    /// Neden? `@kline_1m` stream'i henüz kapanmamış mumu saniyede bir,
    /// **aynı `openTime` ile** yeniden gönderir. Gelen mumun `id`'si
    /// dizideki son mumunkiyle aynıysa onu değiştirirsin, farklıysa sona
    /// eklersin. UUID kullansaydık bu ayrımı yapamazdık ve grafik her
    /// saniye yeni bir nokta eklerdi.
    public let openTime: Date

    public let open: Decimal
    public let high: Decimal
    public let low: Decimal
    public let close: Decimal

    /// Bu mum süresince base cinsinden işlem hacmi (ör. kaç BTC el değiştirdi).
    public let volume: Decimal

    public var id: Date { openTime }

    public init(
        openTime: Date,
        open: Decimal,
        high: Decimal,
        low: Decimal,
        close: Decimal,
        volume: Decimal
    ) {
        self.openTime = openTime
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
}

/// Bir mumun kapsadığı süre.
///
/// `rawValue`'lar Binance'in beklediği biçimde (`"1m"`, `"1h"`...). Bu
/// yazım neredeyse tüm borsalarda standart, o yüzden modele sızması sorun değil.
/// Böylece MarketAPI'de ayrı bir çeviri tablosu yazmak gerekmiyor.
public enum CandleInterval: String, Codable, Sendable, CaseIterable {
    case oneMinute = "1m"
    case fifteenMinutes = "15m"
    case oneHour = "1h"
    case fourHours = "4h"
    case oneDay = "1d"

    /// Saniye cinsinden süre. Mumun ne zaman kapanacağını hesaplamak için lazım.
    public var duration: TimeInterval {
        switch self {
        case .oneMinute:      60
        case .fifteenMinutes: 15 * 60
        case .oneHour:        60 * 60
        case .fourHours:      4 * 60 * 60
        case .oneDay:         24 * 60 * 60
        }
    }
}
