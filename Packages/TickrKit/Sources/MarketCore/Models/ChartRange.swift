import Foundation

/// Grafik ekranındaki zaman aralığı seçici: 1G / 1H / 1A / 1Y.
///
/// Kullanıcı "1 hafta" seçer ama API "hangi aralıkta, kaç mum?" diye sorar.
/// Bu enum aradaki çeviriyi tek bir yerde tutuyor. Aksi halde bu karar
/// ViewModel'e, API katmanına ve testlere dağılırdı.
///
/// Mum sayıları ekranda yüzlerce nokta olacak şekilde seçildi: grafik
/// akıcı görünsün ama tek istekte gelsin (Binance tek istekte en fazla
/// 1000 mum veriyor).
public enum ChartRange: String, Codable, Sendable, CaseIterable, Identifiable {
    case day
    case week
    case month
    case year

    public var id: String { rawValue }

    /// Segmented control'de görünen kısa etiket.
    public var title: String {
        switch self {
        case .day:   "1G"
        case .week:  "1H"
        case .month: "1A"
        case .year:  "1Y"
        }
    }

    /// Bu aralık için kaç dakikalık/saatlik mum isteneceği.
    public var interval: CandleInterval {
        switch self {
        case .day:   .fifteenMinutes
        case .week:  .oneHour
        case .month: .fourHours
        case .year:  .oneDay
        }
    }

    /// Kaç mum isteneceği (`interval` × `candleCount` ≈ aralığın süresi).
    ///
    /// - 1G:  15dk × 96  = 24 saat
    /// - 1H:  1s   × 168 = 7 gün
    /// - 1A:  4s   × 180 = 30 gün
    /// - 1Y:  1g   × 365 = 1 yıl
    public var candleCount: Int {
        switch self {
        case .day:   96
        case .week:  168
        case .month: 180
        case .year:  365
        }
    }
}
