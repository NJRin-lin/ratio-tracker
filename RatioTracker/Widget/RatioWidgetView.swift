import SwiftUI
import WidgetKit

struct RatioWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: RatioEntry

    var body: some View {
        switch family {
        case .systemSmall: smallView
        default: mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("比率跟踪").font(.caption2.weight(.semibold)).foregroundColor(.secondary)
            Spacer(minLength: 0)
            ratioRow("HG/GC", data: entry.hgGC)
            Spacer(minLength: 0)
            ratioRow("SOXX/QQQ", data: entry.soxxQQQ)
            Spacer(minLength: 0)
            Text(entry.date, style: .relative).font(.system(size: 8)).foregroundColor(.secondary.opacity(0.5))
        }
        .padding(10)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumView: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("比率跟踪").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                ratioRow("铜金比 HG/GC", data: entry.hgGC)
                ratioRow("半导体/纳指 SOXX/QQQ", data: entry.soxxQQQ)
                Spacer()
                Text("更新于 \(entry.date, style: .relative)").font(.system(size: 8)).foregroundColor(.secondary.opacity(0.5))
            }
            Spacer()
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder
    private func ratioRow(_ name: String, data: (Double, Double)?) -> some View {
        if let (ratio, pct) = data {
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.caption2).foregroundColor(.secondary)
                HStack(spacing: 6) {
                    Text(String(format: "%.4f", ratio)).font(.callout.monospacedDigit().weight(.bold))
                    let sign = pct >= 0 ? "+" : ""
                    Text("\(sign)\(String(format: "%.2f", pct))%")
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(pct >= 0 ? .green : .red)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.caption2).foregroundColor(.secondary)
                Text("--").font(.callout).foregroundColor(.secondary)
            }
        }
    }
}
