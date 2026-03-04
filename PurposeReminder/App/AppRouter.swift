import SwiftUI
import Combine
import OSLog

enum MainTab: Hashable {
    case session
    case history
    case policy
}

/// 앱 최상위 내비게이션 진입점
struct AppRouter: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var onboardingState = AppOnboardingState()
    @StateObject private var runtimeState = AppRuntimeState()

    var body: some View {
        Group {
            if onboardingState.isReadyForMainFlow {
                MainTabView(
                    selectedTab: $runtimeState.selectedTab,
                    preferredAppTokenData: $runtimeState.preferredSessionTargetTokenData,
                    sessionStartRouteNonce: $runtimeState.sessionStartRouteNonce
                )
            } else {
                OnboardingView(
                    authorizationService: onboardingState.authorizationService
                ) {
                    Task {
                        await onboardingState.completeOnboarding()
                    }
                }
            }
        }
        .task {
            await onboardingState.refresh()
        }
        .task(id: onboardingState.isReadyForMainFlow) {
            guard onboardingState.isReadyForMainFlow else {
                return
            }

            await runtimeState.handleAppActivated()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard onboardingState.isReadyForMainFlow, newPhase == .active else {
                return
            }

            Task {
                await runtimeState.handleAppActivated()
            }
        }
    }
}

private struct MainTabView: View {
    @Binding var selectedTab: MainTab
    @Binding var preferredAppTokenData: Data?
    @Binding var sessionStartRouteNonce: UUID

    var body: some View {
        TabView(selection: $selectedTab) {
            SessionStartView(preferredAppTokenData: preferredAppTokenData)
                .id(sessionStartRouteNonce)
                .tag(MainTab.session)
                .tabItem {
                    Label("세션", systemImage: "play.circle")
                }

            HistoryView()
                .tag(MainTab.history)
                .tabItem {
                    Label("기록", systemImage: "clock")
                }

            PolicySettingsView()
                .tag(MainTab.policy)
                .tabItem {
                    Label("정책", systemImage: "hand.raised.app")
                }
        }
    }
}

@MainActor
final class AppRuntimeState: ObservableObject {
    @Published var selectedTab: MainTab = .session
    @Published var preferredSessionTargetTokenData: Data?
    @Published var sessionStartRouteNonce = UUID()

    private let shieldRouteInbox: ShieldRouteInboxServicing
    private let timeoutInbox: SessionTimeoutInboxServicing
    private let sessionRepository: GoalSessionRepository
    private let sessionCoordinator: SessionCoordinator

    init(
        shieldRouteInbox: ShieldRouteInboxServicing,
        timeoutInbox: SessionTimeoutInboxServicing,
        sessionRepository: GoalSessionRepository,
        sessionCoordinator: SessionCoordinator
    ) {
        self.shieldRouteInbox = shieldRouteInbox
        self.timeoutInbox = timeoutInbox
        self.sessionRepository = sessionRepository
        self.sessionCoordinator = sessionCoordinator
    }

    convenience init() {
        let repository = SwiftDataGoalSessionRepository(context: SwiftDataStack.shared.mainContext)
        self.init(
            shieldRouteInbox: ShieldRouteInboxService(),
            timeoutInbox: SessionTimeoutInboxService(),
            sessionRepository: repository,
            sessionCoordinator: SessionCoordinator(repository: repository)
        )
    }

    func handleAppActivated() async {
        await applyTimeoutIfNeeded()
        consumeShieldRouteIfNeeded()
    }

    func consumeShieldRouteIfNeeded() {
        guard let event = shieldRouteInbox.consumeLastEvent() else {
            return
        }

        switch event.route {
        case .startGoalSelection:
            preferredSessionTargetTokenData = event.targetTokenData
            sessionStartRouteNonce = UUID()
            selectedTab = .session
        case .dismissShield:
            break
        }
    }

    private func applyTimeoutIfNeeded() async {
        guard timeoutInbox.consumeTimeoutEvent() != nil else {
            return
        }

        do {
            let sessions = try await sessionRepository.fetchAll()
            guard let activeSession = sessions
                .filter({ $0.status == .active && $0.endedAt == nil })
                .sorted(by: { lhs, rhs in
                    if lhs.startedAt != rhs.startedAt {
                        return lhs.startedAt > rhs.startedAt
                    }
                    return lhs.id.uuidString < rhs.id.uuidString
                })
                .first else {
                return
            }

            try await sessionCoordinator.attachToActiveSessionIfNeeded(sessionId: activeSession.id)
            _ = try await sessionCoordinator.timeoutSession()
        } catch {
            AppLogger.session.error("Failed to apply timeout event: \(error.localizedDescription, privacy: .public)")
        }
    }
}

@MainActor
final class AppOnboardingState: ObservableObject {
    private enum StorageKey {
        static let onboardingCompleted = "onboarding_completed_v2"
    }

    @Published var isReadyForMainFlow: Bool = false
    let authorizationService: AuthorizationService
    private let userDefaults: UserDefaults

    init(
        authorizationService: AuthorizationService? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.authorizationService = authorizationService ?? AuthorizationService()
        self.userDefaults = userDefaults
    }

    func refresh() async {
        let snapshot = await authorizationService.fetchCurrentStatus()
        let hasCompletedOnboarding = userDefaults.bool(forKey: StorageKey.onboardingCompleted)
        isReadyForMainFlow = snapshot.hasRequiredPermissions && hasCompletedOnboarding
    }

    func completeOnboarding() async {
        userDefaults.set(true, forKey: StorageKey.onboardingCompleted)
        await refresh()
    }
}
