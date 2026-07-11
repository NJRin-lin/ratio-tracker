import WidgetKit
import SwiftUI

@main
struct RatioTrackerWidget: Widget {
    let kind = "RatioTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RatioTimelineProvider()) { entry in
            RatioWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("比率跟踪")
        .description("显示铜金比和 SOXX/QQQ 比率的最新数据")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
