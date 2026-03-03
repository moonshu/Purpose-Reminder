import SwiftUI

struct SessionStartView: View {
    @StateObject private var viewModel: SessionStartRecommendationViewModel

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
                Section {
                    if viewModel.recommendations.isEmpty && !viewModel.isLoading {
                        Text("추천 가능한 빠른 목표가 없습니다.")
                            .foregroundStyle(.secondary)
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
                            .disabled(viewModel.isStarting)
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

                        Button("새 목표로 시작") {
                            Task { await viewModel.startFromCustomGoal() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canStartCustomGoal)
                    }
                }

                if let startedSession = viewModel.startedSession {
                    Section("시작됨") {
                        Text(startedSession.goalTextSnapshot)
                            .font(.headline)

                        Text("계획 시간: \(startedSession.plannedDurationMinutes)분")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("세션 시작")
            .overlay {
                if viewModel.isLoading || viewModel.isStarting {
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
