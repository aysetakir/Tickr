import Foundation
import MarketCore

struct TickerDTO: Decodable {
    let symbol: String
    let lastPrice: Decimal
    let openPrice: Decimal
    let highPrice: Decimal
    let lowPrice: Decimal
    let quoteVolume: Decimal
    let closeTime: Int

    enum CodingKeys: String, CodingKey {
        case symbol, lastPrice, openPrice, highPrice, lowPrice, quoteVolume, closeTime
    }

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
    func decodeDecimalString(forKey key: Key) throws -> Decimal {
        let raw = try decode(String.self, forKey: key)
        guard let value = Decimal(string: raw, locale: .posix) else {
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
    static let posix = Locale(identifier: "en_US_POSIX")
}
