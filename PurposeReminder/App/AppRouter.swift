import SwiftUI

/// 앱 최상위 내비게이션 진입점
struct AppRouter: View {
    @StateObject private var onboardingState = AppOnboardingState()

    var body: some View {
        Group {
            if onboardingState.isReadyForMainFlow {
                Text("Purpose Reminder")
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

@MainActor
final class AppOnboardingState: ObservableObject {
    @Published var isReadyForMainFlow: Bool = false
    let authorizationService: AuthorizationService

    init(authorizationService: AuthorizationService = AuthorizationService()) {
        self.authorizationService = authorizationService
    }

    func refresh() async {
        let snapshot = await authorizationService.fetchCurrentStatus()
        isReadyForMainFlow = snapshot.isReadyForMainFlow
    }
}
