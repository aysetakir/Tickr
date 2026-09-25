import Courier
import Foundation
import MarketCore

/// Uygulamanın kullandığı bütün Binance REST uçları.
///
/// Her uç bir `case`. Yeni bir uç eklemek yeni bir `case` eklemek demek ve
/// derleyici aşağıdaki `switch`'lerde onu ele almadığını hemen söyler.
/// Adreslerin tamamı tek dosyada göründüğü için "bu uygulama sunucudan tam
/// olarak neyi istiyor?" sorusunun cevabı burası.
///
/// Hepsi `GET` ve anahtarsız, o yüzden `method` ve `body` varsayılanda
/// bırakıldı; sadece `requiresAuthentication` ezildi.
///
/// Tip `internal`: dışarısı `BinanceMarketService`'i görür, onun hangi
/// adreslere gittiğini görmez. Uçları değiştirmek MarketAPI'nin iç işi.
enum BinanceEndpoint: Endpoint {
    /// İşlem yapılabilen tüm çiftler. Cevap büyük (~3000 çift, birkaç MB),
    /// bu yüzden ekran açılışında değil, arama ekranında bir kez çağrılacak.
    case exchangeInfo

    /// Verilen sembollerin 24 saatlik özeti.
    ///
    /// Tek istekte hepsini alıyoruz; sembol başına ayrı istek atmak hem
    /// yavaş olur hem de Binance'in ağırlık limitini hızla tüketir.
    case ticker24h(symbols: [String])

    /// Grafik için geçmiş mumlar.
    case klines(symbol: String, interval: CandleInterval, limit: Int)

    var baseURL: URL { Binance.restBaseURL }

    var path: String {
        switch self {
        case .exchangeInfo: "/api/v3/exchangeInfo"
        case .ticker24h:    "/api/v3/ticker/24hr"
        case .klines:       "/api/v3/klines"
        }
    }

    /// Binance'in açık uçları API anahtarı istemiyor.
    ///
    /// Courier'de varsayılan `true`, çünkü tipik bir uygulamada uçların
    /// çoğu korumalıdır ve "yetki eklemeyi unutmak" sessizce 401 dönen bir
    /// hataya yol açar. Burada bilinçli olarak `false` diyoruz: aksi halde
    /// `AuthInterceptor` olmayan bir token'ı aramaya kalkardı.
    var requiresAuthentication: Bool { false }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .exchangeInfo:
            // Filtresiz çağrı zaten tüm çiftleri döndürüyor.
            nil

        case .ticker24h(let symbols):
            // Binance burada standart bir liste parametresi beklemiyor
            // (`symbols=BTCUSDT&symbols=ETHUSDT` değil): tek bir parametrede,
            // JSON dizisi biçiminde ve **boşluksuz** istiyor:
            //     symbols=["BTCUSDT","ETHUSDT"]
            // Yüzde kodlamasını `URLComponents` hallediyor, elle yapma.
            [URLQueryItem(name: "symbols", value: jsonArrayLiteral(symbols))]

        case .klines(let symbol, let interval, let limit):
            [
                URLQueryItem(name: "symbol", value: symbol),
                // `CandleInterval`in ham değerleri ("15m", "1h"…) zaten
                // Binance'in beklediği yazım. Ayrı bir çeviri tablosu yok.
                URLQueryItem(name: "interval", value: interval.rawValue),
                URLQueryItem(name: "limit", value: String(limit)),
            ]
        }
    }
}

/// `["BTCUSDT","ETHUSDT"]` — `JSONEncoder` değil, çünkü o boşluk koymasa da
/// sıralama ve kaçış davranışını garanti etmesi gereken tek yer burası ve
/// sonuç tek satırda okunuyor.
private func jsonArrayLiteral(_ values: [String]) -> String {
    "[" + values.map { "\"\($0)\"" }.joined(separator: ",") + "]"
}
