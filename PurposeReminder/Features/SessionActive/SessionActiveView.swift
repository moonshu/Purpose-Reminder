import SwiftUI
import Combine

@MainActor
final class SessionActiveViewModel: ObservableObject {
    @Published private(set) var activeSession: GoalSession?
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var isLoading = false
    @Published private(set) var isProcessing = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let repository: GoalSessionRepository
    private let coordinator: SessionCoordinator
    private let nowProvider: () -> Date

    private var timerTask: Task<Void, Never>?

    init(
        repository: GoalSessionRepository,
        coordinator: SessionCoordinator,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.coordinator = coordinator
        self.nowProvider = nowProvider
    }

    convenience init() {
        let repository = SwiftDataGoalSessionRepository(context: SwiftDataStack.shared.mainContext)
        self.init(
            repository: repository,
            coordinator: SessionCoordinator(repository: repository)
        )
    }

    deinit {
        timerTask?.cancel()
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            activeSession = try await fetchLatestActiveSession()
            recalculateRemainingSeconds()
            await timeoutExpiredSessionIfNeeded()
            startTimerIfNeeded()
            errorMessage = nil
        } catch {
            activeSession = nil
            remainingSeconds = 0
            errorMessage = "진행 중인 세션을 불러오지 못했습니다."
        }
    }

    func complete() async {
        await finishSession(
            successMessage: "세션을 완료했습니다."
        ) {
            try await coordinator.completeSession()
        }
    }

    func extend() async {
        await finishSession(
            successMessage: "세션을 연장 처리했습니다."
        ) {
            try await coordinator.extendSession(by: Constants.Session.extensionDurationMinutes)
        }
    }

    func abandon() async {
        await finishSession(
            successMessage: "세션을 중단 처리했습니다."
        ) {
            try await coordinator.abandonSession()
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func finishSession(
        successMessage: String,
        transition: () async throws -> GoalSession
    ) async {
        guard let activeSession else {
            self.errorMessage = "진행 중인 세션이 없습니다."
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            try await coordinator.attachToActiveSessionIfNeeded(sessionId: activeSession.id)
            _ = try await transition()
            self.activeSession = nil
            self.remainingSeconds = 0
            self.successMessage = successMessage
            self.errorMessage = nil
            stopTimer()
        } catch {
            self.errorMessage = "세션 상태 변경에 실패했습니다. 잠시 후 다시 시도해 주세요."
        }
    }

    private func fetchLatestActiveSession() async throws -> GoalSession? {
        try await repository.fetchAll()
            .filter { $0.status == .active && $0.endedAt == nil }
            .sorted { lhs, rhs in
                if lhs.startedAt != rhs.startedAt {
                    return lhs.startedAt > rhs.startedAt
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
            .first
    }

    private func startTimerIfNeeded() {
        stopTimer()

        guard activeSession != nil else {
            return
        }

        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.tick()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func tick() {
        recalculateRemainingSeconds()
        guard activeSession != nil, remainingSeconds == 0 else {
            return
        }

        stopTimer()
        Task { [weak self] in
            await self?.timeoutExpiredSessionIfNeeded()
        }
    }

    private func recalculateRemainingSeconds() {
        guard let activeSession else {
            remainingSeconds = 0
            return
        }

        let totalDuration = max(0, activeSession.plannedDurationMinutes * 60)
        let elapsed = max(0, Int(nowProvider().timeIntervalSince(activeSession.startedAt)))
        remainingSeconds = max(0, totalDuration - elapsed)
    }

    private func timeoutExpiredSessionIfNeeded() async {
        guard let activeSession, remainingSeconds == 0 else {
            return
        }

        do {
            try await coordinator.attachToActiveSessionIfNeeded(sessionId: activeSession.id)
            _ = try await coordinator.timeoutSession()
            self.activeSession = nil
            self.remainingSeconds = 0
            self.successMessage = "세션 시간이 종료되어 자동으로 마감했습니다."
            self.errorMessage = nil
            stopTimer()
        } catch {
            self.errorMessage = "세션 만료 처리를 완료하지 못했습니다."
        }
    }
}

struct SessionActiveView: View {
    @StateObject private var viewModel: SessionActiveViewModel

    init(viewModel: SessionActiveViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    init() {
        _viewModel = StateObject(wrappedValue: SessionActiveViewModel())
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Section {
                    InlineMessageBanner(
                        text: errorMessage,
                        style: .error
                    )
                }
            }

            if let successMessage = viewModel.successMessage {
                Section {
                    InlineMessageBanner(
                        text: successMessage,
                        style: .success
                    )
                }
            }

            if let activeSession = viewModel.activeSession {
                Section("진행 중 세션") {
                    Text(activeSession.goalTextSnapshot)
                        .font(.headline)

                    LabeledContent("남은 시간") {
                        Text(remainingTimeLabel)
                            .monospacedDigit()
                    }
                    LabeledContent("시작 시각", value: activeSession.startedAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("계획 시간", value: "\(activeSession.plannedDurationMinutes)분")
                }

                Section("세션 종료") {
                    Button("완료") {
                        Task { await viewModel.complete() }
                    }
                    .disabled(viewModel.isProcessing)

                    Button("연장 \(Constants.Session.extensionDurationMinutes)분") {
                        Task { await viewModel.extend() }
                    }
                    .disabled(viewModel.isProcessing)

                    Button("중단", role: .destructive) {
                        Task { await viewModel.abandon() }
                    }
                    .disabled(viewModel.isProcessing)
                }
            } else if !viewModel.isLoading {
                Section {
                    EmptyStateCard(
                        iconName: "timer",
                        title: "진행 중인 세션이 없습니다.",
                        subtitle: "세션 시작 화면에서 목표를 선택하면 여기서 진행 상황을 확인할 수 있습니다."
                    )
                }
            }
        }
        .navigationTitle("세션 진행")
        .overlay {
            if viewModel.isLoading || viewModel.isProcessing {
                ProgressView()
            }
        }
        .task {
            await viewModel.load()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }

    private var remainingTimeLabel: String {
        let minutes = viewModel.remainingSeconds / 60
        let seconds = viewModel.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
