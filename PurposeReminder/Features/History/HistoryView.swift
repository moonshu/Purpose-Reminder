import SwiftUI
import Combine

struct HistorySummary: Equatable {
    let totalToday: Int
    let completedToday: Int
    let extendedToday: Int
    let abandonedToday: Int
    let timedOutToday: Int

    var completionRate: Double {
        guard totalToday > 0 else {
            return 0
        }
        return Double(completedToday + extendedToday) / Double(totalToday)
    }

    static let empty = HistorySummary(
        totalToday: 0,
        completedToday: 0,
        extendedToday: 0,
        abandonedToday: 0,
        timedOutToday: 0
    )
}

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var summary: HistorySummary = .empty
    @Published private(set) var recentSessions: [GoalSession] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repository: GoalSessionRepository
    private let calendar: Calendar
    private let nowProvider: () -> Date

    init(
        repository: GoalSessionRepository,
        calendar: Calendar = .current,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.calendar = calendar
        self.nowProvider = nowProvider
    }

    convenience init() {
        let context = SwiftDataStack.shared.mainContext
        self.init(repository: SwiftDataGoalSessionRepository(context: context))
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let now = nowProvider()
            let todaySessions = try await fetchTodaySessions(now: now)
            summary = makeSummary(from: todaySessions)

            let recentRangeStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            let recentRangeEnd = now.addingTimeInterval(1)
            let recent = try await repository.fetch(from: recentRangeStart, to: recentRangeEnd)
            recentSessions = recent.sorted { lhs, rhs in
                if lhs.startedAt != rhs.startedAt {
                    return lhs.startedAt > rhs.startedAt
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }

            errorMessage = nil
        } catch {
            summary = .empty
            recentSessions = []
            errorMessage = "기록을 불러오지 못했습니다. 다시 시도해 주세요."
        }
    }

    private func fetchTodaySessions(now: Date) async throws -> [GoalSession] {
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return []
        }

        return try await repository.fetch(from: start, to: end)
    }

    private func makeSummary(from sessions: [GoalSession]) -> HistorySummary {
        HistorySummary(
            totalToday: sessions.count,
            completedToday: sessions.filter { $0.status == .completed }.count,
            extendedToday: sessions.filter { $0.status == .extended }.count,
            abandonedToday: sessions.filter { $0.status == .abandoned }.count,
            timedOutToday: sessions.filter { $0.status == .timedOut }.count
        )
    }
}

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel

    init(viewModel: HistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    init() {
        _viewModel = StateObject(wrappedValue: HistoryViewModel())
    }

    var body: some View {
        NavigationStack {
            List {
                Section("오늘 요약") {
                    LabeledContent("총 세션", value: "\(viewModel.summary.totalToday)개")
                    LabeledContent(
                        "달성률",
                        value: "\(Int(viewModel.summary.completionRate * 100))%"
                    )
                    LabeledContent("완료", value: "\(viewModel.summary.completedToday)개")
                    LabeledContent("연장", value: "\(viewModel.summary.extendedToday)개")
                    LabeledContent("중단", value: "\(viewModel.summary.abandonedToday)개")
                    LabeledContent("시간초과", value: "\(viewModel.summary.timedOutToday)개")
                }

                Section("최근 7일") {
                    if viewModel.recentSessions.isEmpty && !viewModel.isLoading {
                        Text("아직 기록이 없습니다.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.recentSessions) { session in
                            SessionHistoryRow(session: session)
                        }
                    }
                }
            }
            .navigationTitle("기록")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .alert(
            "오류",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct SessionHistoryRow: View {
    let session: GoalSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.goalTextSnapshot)
                .font(.headline)

            HStack {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(statusLabel)
                    .foregroundStyle(statusColor)
            }
            .font(.caption)

            Text("계획 시간: \(session.plannedDurationMinutes)분")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var statusLabel: String {
        switch session.status {
        case .active:
            return "진행 중"
        case .completed:
            return "완료"
        case .extended:
            return "연장 완료"
        case .abandoned:
            return "중단"
        case .timedOut:
            return "시간초과"
        }
    }

    private var statusColor: Color {
        switch session.status {
        case .active:
            return .blue
        case .completed, .extended:
            return .green
        case .abandoned:
            return .orange
        case .timedOut:
            return .red
        }
    }
}
