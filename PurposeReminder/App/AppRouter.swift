import SwiftUI
import Combine

/// 앱 최상위 내비게이션 진입점
struct AppRouter: View {
    @StateObject private var onboardingState = AppOnboardingState()

    var body: some View {
        Group {
            if onboardingState.isReadyForMainFlow {
                MainTabView()
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
    }
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            SessionStartView()
                .tabItem {
                    Label("세션", systemImage: "play.circle")
                }

            HistoryView()
                .tabItem {
                    Label("기록", systemImage: "clock")
                }

            PolicySettingsView()
                .tabItem {
                    Label("정책", systemImage: "hand.raised.app")
                }
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
