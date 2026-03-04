import SwiftUI

struct SessionStartView: View {
    @StateObject private var viewModel: SessionStartRecommendationViewModel
    @State private var shouldNavigateToActiveSession = false

    init(preferredAppTokenData: Data? = nil) {
        _viewModel = StateObject(
            wrappedValue: SessionStartRecommendationViewModel(
                preferredAppTokenData: preferredAppTokenData
            )
        )
    }

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        InlineMessageBanner(
                            text: errorMessage,
                            style: .error
                        )
                    }
                }

                if let warningMessage = viewModel.warningMessage {
                    Section {
                        InlineMessageBanner(
                            text: warningMessage,
                            style: .warning
                        )
                    }
                }

                Section {
                    if viewModel.recommendations.isEmpty && !viewModel.isLoading {
                        EmptyStateCard(
                            iconName: "sparkles",
                            title: "추천 가능한 빠른 목표가 없습니다.",
                            subtitle: "목표 템플릿을 추가하거나 세션을 한 번 시작하면 추천이 정교해집니다."
                        )
                    } else {
                        ForEach(viewModel.recommendations) { recommendation in
                            Button {
                                Task { await viewModel.startFromRecommendation(recommendation) }
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(recommendation.template.text)
                                        .font(.headline)

                                    Text(sourceTitle(recommendation.source))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                            .disabled(viewModel.isStarting || viewModel.isStartLocked)
                        }
                    }
                } header: {
                    Text("빠른 시작")
                } footer: {
                    Text("목표를 탭하면 즉시 세션이 시작됩니다.")
                }

                if viewModel.shouldShowCustomGoalInput {
                    Section("새 목표 입력") {
                        TextField(
                            "예: DM 3개만 답장",
                            text: $viewModel.customGoalText,
                            axis: .vertical
                        )
                        .lineLimit(2...4)
                    }
                }

                if let activeSession = viewModel.resumableSession ?? viewModel.startedSession {
                    Section("진행 중 세션") {
                        Text(activeSession.goalTextSnapshot)
                            .font(.headline)

                        Text("계획 시간: \(activeSession.plannedDurationMinutes)분")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("진행 화면으로 이동") {
                            shouldNavigateToActiveSession = true
                        }
                    }
                }

                Section("바로가기") {
                    NavigationLink("진행 중 세션 보기") {
                        SessionActiveView()
                    }

                    NavigationLink("목표 템플릿 관리") {
                        GoalTemplatesView()
                    }
                }
            }
            .navigationTitle("세션 시작")
            .overlay {
                if viewModel.isLoading || viewModel.isStarting {
                    ProgressView()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.shouldShowCustomGoalInput {
                    Button("새 목표로 시작") {
                        Task { await viewModel.startFromCustomGoal() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canStartCustomGoal)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                }
            }
            .navigationDestination(isPresented: $shouldNavigateToActiveSession) {
                SessionActiveView()
            }
        }
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.startedSession?.id) { _, sessionId in
            guard sessionId != nil else {
                return
            }
            shouldNavigateToActiveSession = true
        }
    }

    private func sourceTitle(_ source: QuickGoalRecommendationSource) -> String {
        switch source {
        case .favorite:
            return "즐겨찾기"
        case .recentForTargetApp:
            return "같은 앱 최근 목표"
        case .recentGlobal:
            return "전체 최근 목표"
        case .appDefault:
            return "앱 기본 목표"
        }
    }
}
