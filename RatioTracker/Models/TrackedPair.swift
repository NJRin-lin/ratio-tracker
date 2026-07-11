import Foundation

struct TrackedPair: Identifiable {
    let id = UUID()
    let name: String
    let shortName: String
    let numeratorTicker: String
    let denominatorTicker: String

    static let pairs: [TrackedPair] = [
        TrackedPair(name: "铜金比", shortName: "HG/GC", numeratorTicker: "HG=F", denominatorTicker: "GC=F"),
        TrackedPair(name: "半导体相对纳斯达克100", shortName: "SOXX/QQQ", numeratorTicker: "SOXX", denominatorTicker: "QQQ"),
    ]
}

struct RatioSnapshot: Identifiable {
    let id = UUID()
    let pair: TrackedPair
    let numeratorPrice: Double
    let denominatorPrice: Double
    let ratio: Double
    let previousRatio: Double?
    let changePercent: Double?
    let timestamp: Date
}
