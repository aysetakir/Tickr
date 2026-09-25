import Foundation
import MarketCore

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
    mutating func decodeDecimalString() throws -> Decimal {
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
