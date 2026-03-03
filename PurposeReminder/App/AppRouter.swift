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
                        await onboardingState.refresh()
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
    @Published var isReadyForMainFlow: Bool = false
    let authorizationService: AuthorizationService

    init(authorizationService: AuthorizationService? = nil) {
        self.authorizationService = authorizationService ?? AuthorizationService()
    }

    func refresh() async {
        let snapshot = await authorizationService.fetchCurrentStatus()
        isReadyForMainFlow = snapshot.isReadyForMainFlow
    }
}
