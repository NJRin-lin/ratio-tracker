import SwiftUI
import Charts

struct RatioCardView: View {
    let pairName: String
    let pairDisplayName: String
    let snapshot: RatioSnapshot?
    let chartData: [(Date, Double)]
    let rangeChangePct: Double?
    let isRefreshing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 标题行
            HStack {
                Text(pairDisplayName)
                    .font(.headline)
                Spacer()
                if let snap = snapshot {
                    Text(String(format: "%.4f", snap.ratio))
                        .font(.title2.monospacedDigit().weight(.bold))
                    let pct = rangeChangePct ?? snap.changePercent
                    if let pct {
                        let sign = pct >= 0 ? "+" : ""
                        Text("\(sign)\(String(format: "%.2f", pct))%")
                            .font(.callout.monospacedDigit())
                            .foregroundColor(pct >= 0 ? .green : .red)
                    }
                } else if isRefreshing {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Text("--").font(.title2).foregroundColor(.secondary)
                }
            }

            // 走势图
            if !chartData.isEmpty {
                let values = chartData.map(\.1)
                let yMin = (values.min() ?? 0) * 0.998
                let yMax = (values.max() ?? 1) * 1.002

                Chart {
                    ForEach(chartData.indices, id: \.self) { i in
                        AreaMark(x: .value("日期", chartData[i].0), y: .value("比率", chartData[i].1))
                            .foregroundStyle(LinearGradient(
                                colors: [.blue.opacity(0.2), .blue.opacity(0.02)],
                                startPoint: .top, endPoint: .bottom
                            ))
                        LineMark(x: .value("日期", chartData[i].0), y: .value("比率", chartData[i].1))
                            .foregroundStyle(.blue).lineStyle(StrokeStyle(lineWidth: 1.5))
                    }
                }
                .chartYScale(domain: yMin...yMax)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine().foregroundStyle(.secondary.opacity(0.2))
                        AxisValueLabel(format: dateFormat).foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { _ in
                        AxisValueLabel().foregroundStyle(.secondary)
                    }
                }
                .clipped()
                .frame(height: 130)
            } else if isRefreshing {
                ProgressView().frame(height: 130)
            } else {
                Rectangle().fill(.quaternary.opacity(0.3)).frame(height: 130)
                    .overlay(Text("暂无数据").font(.caption).foregroundColor(.secondary))
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var dateFormat: Date.FormatStyle {
        chartData.count > 180 ? .dateTime.month(.abbreviated).year(.twoDigits) : .dateTime.month(.abbreviated).day()
    }
}
