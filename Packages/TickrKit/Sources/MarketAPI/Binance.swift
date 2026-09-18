import Foundation

/// Binance'in açık (API anahtarı gerektirmeyen) REST adresi.
///
/// Endpoint'lerin hepsi `baseURL` olarak bunu döndürecek. Adres tek bir
/// yerde durursa test ortamına ya da başka bir sunucuya geçmek tek satırlık
/// iş olur.
enum Binance {
    static let restBaseURL = URL(string: "https://api.binance.com")!
}
