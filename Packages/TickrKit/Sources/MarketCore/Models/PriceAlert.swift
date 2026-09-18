import Foundation

/// Kullanıcının kurduğu fiyat alarmı: "BTC 70.000'in üstüne çıkınca haber ver".
///
/// Bu domain modeli. SwiftData'ya kaydederken Persistence modülünde ayrı bir
/// `@Model` sınıfı yazıp bu struct'a çevireceksin. Neden ikisi ayrı?
/// - `@Model` bir class ve `MainActor`/`ModelContext`'e bağlı. Alarmı
///   değerlendirecek kod arka planda çalışacak, orada class taşımak zahmetli.
///   `Sendable` bir struct ise her yere rahatça gider.
/// - Widget, Live Activity ve testler SwiftData bilmeden alarmla çalışabilsin.
public struct PriceAlert: Identifiable, Hashable, Codable, Sendable {
    /// Alarm hangi yönde tetiklensin?
    ///
    /// Tek başına "hedef fiyat" yetmez. BTC şu an 65.000'deyse ve alarm
    /// 60.000'deyse, kullanıcı düşüşü mü bekliyor yoksa 60.000'e inip tekrar
    /// çıkmasını mı? Yönü kullanıcıya açıkça seçtiriyoruz.
    public enum Direction: String, Codable, Sendable, CaseIterable {
        /// Fiyat hedefin üstüne çıkınca.
        case above
        /// Fiyat hedefin altına inince.
        case below
    }

    /// `let`, çünkü bildirim de bu kimlikle eşleşecek: bildirime tıklanınca
    /// hangi alarmı açacağımızı buradan bileceğiz.
    public let id: UUID

    /// Hangi çift için, ör. `"BTCUSDT"`.
    public let symbol: String

    public var targetPrice: Decimal
    public var direction: Direction

    /// Kullanıcı alarmı silmeden kapatabilsin.
    public var isEnabled: Bool

    public let createdAt: Date

    /// Son tetiklenme zamanı. Henüz tetiklenmediyse `nil`.
    ///
    /// Bu alan olmasaydı ne olurdu? Fiyat 70.000'in üstündeyken WebSocket
    /// saniyede bir güncelleme gönderiyor ve her güncellemede "üstünde mi?"
    /// sorusunun cevabı evet. Kullanıcı saniyede bir bildirim alırdı.
    /// Alerts modülündeki değerlendirici bu alana bakıp tekrar tetiklemeyi
    /// engelleyecek.
    public var lastTriggeredAt: Date?

    public init(
        id: UUID = UUID(),
        symbol: String,
        targetPrice: Decimal,
        direction: Direction,
        isEnabled: Bool = true,
        createdAt: Date = .now,
        lastTriggeredAt: Date? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.targetPrice = targetPrice
        self.direction = direction
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.lastTriggeredAt = lastTriggeredAt
    }
}
