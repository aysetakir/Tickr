import Foundation
import MarketCore

/// `/api/v3/klines` cevabındaki tek bir mum.
///
/// Binance mumu nesne olarak değil, **dizi** olarak gönderiyor:
///
/// ```json
/// [1790344800000, "83923.71", "84030.01", "83183.00", "84016.01",
///  "2047.65742", 1790348399999, "171277495.13", 358243, ...]
/// ```
///
/// Yani alanların adı yok, sırası var. `CodingKeys` böyle bir JSON'ı
/// okuyamaz; anahtarsız kap (`unkeyedContainer`) gerekiyor. Kaptan her
/// `decode` çağrısı imleci bir ileri kaydırır, o yüzden **sıra kritik**:
/// aşağıdaki çağrıları yer değiştirirsen `high` ile `low` sessizce yer
/// değiştirir ve grafik ters çizilir.
///
/// İhtiyacımız olan ilk 6 alan. Kalanını okumuyoruz; anahtarsız kapta
/// diziyi sonuna kadar tüketme zorunluluğu yok.
struct KlineDTO: Decodable {
    let openTime: Int
    let open: Decimal
    let high: Decimal
    let low: Decimal
    let close: Decimal
    let volume: Decimal

    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        openTime = try container.decode(Int.self)
        open = try container.decodeDecimalString()
        high = try container.decodeDecimalString()
        low = try container.decodeDecimalString()
        close = try container.decodeDecimalString()
        volume = try container.decodeDecimalString()
    }

    var candle: Candle {
        Candle(
            openTime: Date(timeIntervalSince1970: TimeInterval(openTime) / 1000),
            open: open,
            high: high,
            low: low,
            close: close,
            volume: volume
        )
    }
}

extension UnkeyedDecodingContainer {
    /// `TickerDTO`'daki string→`Decimal` kuralının anahtarsız kap sürümü.
    /// Locale ve "parse edilemezse hata fırlat" kararının gerekçesi orada.
    mutating func decodeDecimalString() throws -> Decimal {
        // Hata mesajında kaçıncı alanda patladığımız görünsün diye, imleç
        // ilerlemeden önce okunuyor. Kapsayıcının kendi `codingPath`'i
        // ilerlemiş imleci raporladığı için bir fazlasını gösterir.
        let index = currentIndex
        let raw = try decode(String.self)
        guard let value = Decimal(string: raw, locale: .posix) else {
            throw DecodingError.dataCorruptedError(
                in: self,
                debugDescription: "Sayıya çevrilemeyen değer (dizide \(index). sıra, 0'dan): \"\(raw)\""
            )
        }
        return value
    }
}
