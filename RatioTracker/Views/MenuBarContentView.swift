import SwiftUI
import Charts

struct MenuBarContentView: View {
    @EnvironmentObject var viewModel: RatioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题栏
            HStack {
                Text("比率跟踪").font(.headline)
                Spacer()
                if viewModel.isRefreshing {
                    ProgressView().scaleEffect(0.6)
                }
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                }
                .disabled(viewModel.isRefreshing)
                .buttonStyle(.plain)
            }

            // 时间范围
            HStack(spacing: 4) {
                ForEach(viewModel.timeRanges, id: \.self) { range in
                    Button {
                        viewModel.selectedRange = range
                        Task { await viewModel.loadChartData() }
                    } label: {
                        Text(range)
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(viewModel.selectedRange == range ? .white : .secondary)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(viewModel.selectedRange == range ? Color.accentColor : Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            // 比率卡片
            ForEach(viewModel.pairs) { pair in
                pairCard(for: pair)
            }

            // 底部
            if let date = viewModel.lastUpdated {
                Text("更新于 \(date.formatted(.relative(presentation: .named)))")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(width: 320)
    }

    @ViewBuilder
    private func pairCard(for pair: TrackedPair) -> some View {
        let snap = viewModel.snapshots[pair.shortName]
        let data = viewModel.chartData[pair.shortName] ?? []
        let pct = viewModel.rangeChangePct[pair.shortName] ?? snap?.changePercent

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(pair.shortName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let snap {
                    Text(String(format: "%.4f", snap.ratio))
                        .font(.callout.monospacedDigit().weight(.bold))
                    if let pct {
                        let sign = pct >= 0 ? "+" : ""
                        Text("\(sign)\(String(format: "%.2f", pct))%")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(pct >= 0 ? .green : .red)
                    }
                } else {
                    Text("--").font(.callout).foregroundColor(.secondary)
                }
            }

            if !data.isEmpty {
                let values = data.map(\.1)
                let yMin = (values.min() ?? 0) * 0.998
                let yMax = (values.max() ?? 1) * 1.002
                Chart {
                    ForEach(data.indices, id: \.self) { i in
                        LineMark(x: .value("日", data[i].0), y: .value("值", data[i].1))
                            .foregroundStyle(.blue).lineStyle(StrokeStyle(lineWidth: 1.2))
                    }
                }
                .chartYScale(domain: yMin...yMax)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .clipped()
                .frame(height: 40)
            } else if viewModel.isRefreshing {
                ProgressView().scaleEffect(0.5).frame(height: 40)
            }
        }
        .padding(8)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
