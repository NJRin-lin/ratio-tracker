import WidgetKit

struct RatioEntry: TimelineEntry {
    let date: Date
    let hgGC: (ratio: Double, changePct: Double)?
    let soxxQQQ: (ratio: Double, changePct: Double)?
    let isPlaceholder: Bool

    static var placeholder: RatioEntry {
        RatioEntry(date: Date(), hgGC: (0.1705, 0.41), soxxQQQ: (0.8012, -0.32), isPlaceholder: true)
    }
}
