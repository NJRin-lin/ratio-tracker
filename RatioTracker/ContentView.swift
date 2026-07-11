import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RatioViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 错误提示
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle").foregroundColor(.orange)
                    Text(error).font(.caption)
                    Spacer()
                    Button("关闭") { viewModel.errorMessage = nil }.buttonStyle(.plain)
                }
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(.orange.opacity(0.1))
            }

            // 主轴内容
            ScrollView {
                VStack(spacing: 10) {
                    // 时间范围选择
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(viewModel.timeRanges, id: \.self) { range in
                                Button {
                                    viewModel.selectedRange = range
                                    Task { await viewModel.loadChartData() }
                                } label: {
                                    Text(range)
                                        .font(.caption.monospacedDigit())
                                        .foregroundColor(viewModel.selectedRange == range ? .white : .secondary)
                                        .padding(.horizontal, 8).padding(.vertical, 2)
                                        .background(viewModel.selectedRange == range ? Color.accentColor : Color.secondary.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                    }

                    // 比率卡片
                    ForEach(viewModel.pairs) { pair in
                        RatioCardView(
                            pairName: pair.shortName,
                            pairDisplayName: "\(pair.name) \(pair.shortName)",
                            snapshot: viewModel.snapshots[pair.shortName],
                            chartData: viewModel.chartData[pair.shortName] ?? [],
                            rangeChangePct: viewModel.rangeChangePct[pair.shortName],
                            isRefreshing: viewModel.isRefreshing
                        )
                    }
                }
                .padding(10)
            }

            // 底部状态
            Divider()
            HStack(spacing: 4) {
                if let date = viewModel.lastUpdated {
                    Text("更新于 \(date.formatted(.relative(presentation: .named)))")
                        .font(.caption).foregroundColor(.secondary)
                } else {
                    Text("等待首次刷新...").font(.caption).foregroundColor(.secondary)
                }
                Text("· 自动").font(.caption).foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
        }
        .navigationTitle("比率跟踪")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        if viewModel.isRefreshing {
                            ProgressView().scaleEffect(0.6)
                        }
                    }
                }
                .disabled(viewModel.isRefreshing)
            }
        }
    }
}
