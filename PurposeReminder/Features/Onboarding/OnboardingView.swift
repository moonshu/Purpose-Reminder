import SwiftUI
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var snapshot = AuthorizationSnapshot(
        screenTime: .notDetermined,
        notifications: .notDetermined
    )
    @Published private(set) var screenTimeHint: String?

    private let authorizationService: AuthorizationServicing

    init(authorizationService: AuthorizationServicing) {
        self.authorizationService = authorizationService
    }

    func refresh() async {
        snapshot = await authorizationService.fetchCurrentStatus()
    }

    func requestScreenTime() async {
        let previous = snapshot.screenTime
        let result = await authorizationService.requestScreenTimeAuthorization()
        snapshot = AuthorizationSnapshot(
            screenTime: result.status,
            notifications: snapshot.notifications
        )

        if result.status == .approved {
            screenTimeHint = nil
            return
        }

        if let errorDescription = result.errorDescription, !errorDescription.isEmpty {
            screenTimeHint = "요청 실패: \(errorDescription)"
            return
        }

        if previous == .notDetermined && result.status == .notDetermined {
            screenTimeHint = "권한 창이 뜨지 않으면 실기기 실행 여부와 Family Controls Capability 설정을 확인하세요."
            return
        }

        if result.status == .denied {
            screenTimeHint = "설정 > 스크린 타임에서 권한 상태를 확인하세요."
            return
        }

        screenTimeHint = nil
    }

    func requestNotifications() async {
        let updated = await authorizationService.requestNotificationAuthorization()
        snapshot = AuthorizationSnapshot(
            screenTime: snapshot.screenTime,
            notifications: updated
        )
    }
}

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    let onCompleted: () -> Void

    init(
        authorizationService: AuthorizationServicing,
        onCompleted: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: OnboardingViewModel(authorizationService: authorizationService)
        )
        self.onCompleted = onCompleted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Purpose Reminder")
                .font(.largeTitle.bold())
            Text("앱 개입 기능을 사용하려면 아래 권한이 필요합니다.")
                .foregroundStyle(.secondary)

            permissionRow(
                title: "Screen Time 권한",
                status: screenTimeText(viewModel.snapshot.screenTime)
            ) {
                Task { await viewModel.requestScreenTime() }
            }

            if let hint = viewModel.screenTimeHint {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            permissionRow(
                title: "알림 권한",
                status: notificationText(viewModel.snapshot.notifications)
            ) {
                Task { await viewModel.requestNotifications() }
            }

            Button("계속") {
                onCompleted()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.snapshot.isReadyForMainFlow)
            .padding(.top, 8)

            Spacer()
        }
        .padding(20)
        .task {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private func permissionRow(
        title: String,
        status: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button("권한 요청", action: action)
                .buttonStyle(.bordered)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func screenTimeText(_ status: ScreenTimePermissionStatus) -> String {
        switch status {
        case .approved:
            return "허용됨"
        case .denied:
            return "거부됨"
        case .notDetermined:
            return "미요청"
        }
    }

    private func notificationText(_ status: NotificationPermissionStatus) -> String {
        switch status {
        case .authorized:
            return "허용됨"
        case .denied:
            return "거부됨"
        case .notDetermined:
            return "미요청"
        }
    }
}
