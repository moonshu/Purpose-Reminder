import SwiftUI
import Combine
import FamilyControls
import UIKit
import OSLog

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var snapshot = AuthorizationSnapshot(
        screenTime: .notDetermined,
        notifications: .notDetermined
    )
    @Published private(set) var step: OnboardingStep = .landing
    @Published private(set) var screenTimeHint: String?
    @Published private(set) var notificationHint: String?

    @Published var selection = FamilyActivitySelection()
    @Published var defaultDurationMinutes: Int = Constants.Session.defaultDurationMinutes
    @Published var reminderOffsetMinutes: Int = Constants.Session.defaultReminderOffsetMinutes

    @Published private(set) var policyCount: Int = 0
    @Published private(set) var isSavingPolicy = false
    @Published private(set) var policySaveMessage: String?
    @Published var errorMessage: String?

    private var navigator = OnboardingStepNavigator()

    private let authorizationService: AuthorizationServicing
    private let appPolicyRepository: AppPolicyRepository
    private let appSelectionService: AppSelectionServicing
    private let shieldPolicyService: ShieldPolicyServicing

    init(
        authorizationService: AuthorizationServicing,
        appPolicyRepository: AppPolicyRepository,
        appSelectionService: AppSelectionServicing,
        shieldPolicyService: ShieldPolicyServicing
    ) {
        self.authorizationService = authorizationService
        self.appPolicyRepository = appPolicyRepository
        self.appSelectionService = appSelectionService
        self.shieldPolicyService = shieldPolicyService
    }

    var selectedTargetCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }

    var hasSavedInitialPolicy: Bool {
        policyCount > 0
    }

    var canMoveNext: Bool {
        switch step {
        case .screenTimePermission:
            snapshot.hasRequiredPermissions
        case .initialSetup:
            hasSavedInitialPolicy
        case .done:
            true
        default:
            true
        }
    }

    func refresh() async {
        snapshot = await authorizationService.fetchCurrentStatus()
        await loadInitialPolicyState()
        trackStepViewed()
    }

    func goNext() {
        trackCTATapped(name: "next")

        let moved = navigator.moveNext(
            hasScreenTimeAccess: snapshot.hasRequiredPermissions,
            hasSavedPolicy: hasSavedInitialPolicy
        )

        guard moved else {
            if step == .screenTimePermission {
                screenTimeHint = "Screen Time 권한을 허용하면 다음 단계로 진행할 수 있습니다."
            } else if step == .initialSetup {
                errorMessage = "최소 1개 정책을 저장해야 다음 단계로 진행할 수 있습니다."
            }
            return
        }

        step = navigator.currentStep
        trackStepViewed()
    }

    func goBack() {
        trackCTATapped(name: "back")
        guard navigator.moveBack() else {
            return
        }

        step = navigator.currentStep
        trackStepViewed()
    }

    func requestScreenTime() async {
        trackCTATapped(name: "screen_time_request")

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
        trackCTATapped(name: "notification_request")

        let updated = await authorizationService.requestNotificationAuthorization()
        snapshot = AuthorizationSnapshot(
            screenTime: snapshot.screenTime,
            notifications: updated
        )

        if updated == .authorized {
            notificationHint = "알림이 활성화되었습니다."
        } else if updated == .denied {
            notificationHint = "설정에서 알림 권한을 켜면 종료 리마인드를 받을 수 있습니다."
        } else {
            notificationHint = nil
        }
    }

    func skipNotifications() {
        trackCTATapped(name: "notification_skip")
        notificationHint = "알림은 나중에 설정에서 켤 수 있습니다."
    }

    func updateDefaultDuration(_ value: Int) {
        defaultDurationMinutes = min(max(1, value), 180)
        reminderOffsetMinutes = min(
            max(1, reminderOffsetMinutes),
            max(1, defaultDurationMinutes - 1)
        )
    }

    func updateReminderOffset(_ value: Int) {
        reminderOffsetMinutes = min(
            max(1, value),
            max(1, defaultDurationMinutes - 1)
        )
    }

    func saveInitialSetup() async {
        guard selectedTargetCount > 0 else {
            errorMessage = "최소 1개 앱/카테고리/웹 도메인을 선택해야 저장할 수 있습니다."
            policySaveMessage = nil
            return
        }

        isSavingPolicy = true
        defer { isSavingPolicy = false }

        do {
            let existingPolicies = try await appPolicyRepository.fetchAll()
            let mergedPolicies = appSelectionService.makePolicies(
                from: selection,
                existingPolicies: existingPolicies,
                defaultDurationMinutes: defaultDurationMinutes,
                reminderOffsetMinutes: reminderOffsetMinutes
            )

            guard !mergedPolicies.isEmpty else {
                errorMessage = "선택된 대상을 정책으로 변환하지 못했습니다."
                policySaveMessage = nil
                return
            }

            let selectedIds = Set(mergedPolicies.map(\.id))

            for policy in mergedPolicies {
                try await appPolicyRepository.save(policy)
            }

            for policy in existingPolicies where !selectedIds.contains(policy.id) {
                try await appPolicyRepository.delete(id: policy.id)
            }

            let refreshedPolicies = try await appPolicyRepository.fetchAll().filter(\.isActive)
            try shieldPolicyService.applyPolicies(refreshedPolicies)

            policyCount = refreshedPolicies.count
            policySaveMessage = "정책 저장이 완료되었습니다."
            errorMessage = nil
            trackCTATapped(name: "initial_setup_saved")
        } catch {
            errorMessage = "정책 저장 중 오류가 발생했습니다. 다시 시도해 주세요."
            policySaveMessage = nil
        }
    }

    func clearPolicyFeedback() {
        policySaveMessage = nil
        errorMessage = nil
    }

    private func loadInitialPolicyState() async {
        do {
            let activePolicies = try await appPolicyRepository.fetchAll().filter(\.isActive)
            policyCount = activePolicies.count
            selection = appSelectionService.makeSelection(from: activePolicies)

            if let first = activePolicies.first {
                defaultDurationMinutes = min(max(1, first.defaultDurationMinutes), 180)
                reminderOffsetMinutes = min(
                    max(1, first.reminderOffsetMinutes),
                    max(1, defaultDurationMinutes - 1)
                )
            }
        } catch {
            errorMessage = "기존 정책을 불러오지 못했습니다."
        }
    }

    private func trackStepViewed() {
        AppLogger.onboarding.info("onboarding_step_viewed step=\(self.step.analyticsName, privacy: .public)")
    }

    private func trackCTATapped(name: String) {
        AppLogger.onboarding.info(
            "onboarding_cta_tapped step=\(self.step.analyticsName, privacy: .public) cta=\(name, privacy: .public)"
        )
    }
}

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @Environment(\.openURL) private var openURL

    @State private var isPickerPresented = false

    let onCompleted: () -> Void

    init(
        authorizationService: AuthorizationServicing,
        appPolicyRepository: AppPolicyRepository,
        appSelectionService: AppSelectionServicing = AppSelectionService(),
        shieldPolicyService: ShieldPolicyServicing = ShieldPolicyService(),
        onCompleted: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: OnboardingViewModel(
                authorizationService: authorizationService,
                appPolicyRepository: appPolicyRepository,
                appSelectionService: appSelectionService,
                shieldPolicyService: shieldPolicyService
            )
        )
        self.onCompleted = onCompleted
    }

    @MainActor
    init(
        authorizationService: AuthorizationServicing,
        appSelectionService: AppSelectionServicing = AppSelectionService(),
        shieldPolicyService: ShieldPolicyServicing = ShieldPolicyService(),
        onCompleted: @escaping () -> Void
    ) {
        self.init(
            authorizationService: authorizationService,
            appPolicyRepository: SwiftDataAppPolicyRepository(context: SwiftDataStack.shared.mainContext),
            appSelectionService: appSelectionService,
            shieldPolicyService: shieldPolicyService,
            onCompleted: onCompleted
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader

            if let errorMessage = viewModel.errorMessage {
                InlineMessageBanner(
                    text: errorMessage,
                    style: .error
                )
            }

            ScrollView {
                stepBody
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            stepFooter
        }
        .padding(20)
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $viewModel.selection)
        .task {
            await viewModel.refresh()
        }
        .onChange(of: viewModel.selection, initial: false) {
            viewModel.clearPolicyFeedback()
        }
    }

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.step.progressText)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())

            ProgressView(
                value: Double(viewModel.step.rawValue + 1),
                total: Double(OnboardingStep.allCases.count)
            )
            .tint(.blue)

            Text(viewModel.step.title)
                .font(.title2.bold())

            Text(viewModel.step.subtitle)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var stepBody: some View {
        switch viewModel.step {
        case .landing:
            landingContent
        case .explain:
            explainContent
        case .screenTimePermission:
            screenTimePermissionContent
        case .initialSetup:
            initialSetupContent
        case .notificationPermission:
            notificationPermissionContent
        case .done:
            completionContent
        }
    }

    @ViewBuilder
    private var landingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            onboardingFeatureCard(
                systemImage: "target",
                title: "목표 먼저 선택",
                body: "앱을 열기 전에 지금 하려는 일을 한 문장으로 정합니다."
            )
            onboardingFeatureCard(
                systemImage: "hourglass",
                title: "제한 시간 사용",
                body: "정한 시간 안에서만 필요한 작업을 끝내도록 돕습니다."
            )
            onboardingFeatureCard(
                systemImage: "bell.badge",
                title: "마감 리마인드",
                body: "종료 시점 전에 알림으로 마무리 타이밍을 알려줍니다."
            )
        }
    }

    @ViewBuilder
    private var explainContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            onboardingFlowRow(index: 1, title: "대상 앱 선택", subtitle: "개입할 앱/카테고리를 지정합니다")
            onboardingFlowRow(index: 2, title: "목표 선택", subtitle: "무엇을 할지 먼저 정한 뒤 시작합니다")
            onboardingFlowRow(index: 3, title: "제한 시간 사용", subtitle: "정책 시간 동안만 집중해서 사용합니다")
            onboardingFlowRow(index: 4, title: "리마인드 수신", subtitle: "종료 전 알림으로 마무리를 유도합니다")
        }
    }

    @ViewBuilder
    private var screenTimePermissionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            permissionCard(
                title: "Screen Time 권한",
                status: screenTimeText(viewModel.snapshot.screenTime),
                lines: [
                    "왜 필요한가: 등록 앱 진입 전에 목표 선택을 보여주기 위해 필요합니다.",
                    "언제 사용하나: 사용자가 지정한 앱을 열려고 할 때만 사용합니다.",
                    "수집하지 않는 정보: 개인 메시지/콘텐츠 본문을 읽지 않습니다."
                ],
                actionTitle: screenTimeActionTitle(viewModel.snapshot.screenTime),
                actionEnabled: viewModel.snapshot.screenTime != .approved
            ) {
                switch viewModel.snapshot.screenTime {
                case .approved:
                    break
                case .denied:
                    openAppSettings()
                case .notDetermined:
                    Task { await viewModel.requestScreenTime() }
                }
            }

            if let hint = viewModel.screenTimeHint {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var initialSetupContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Button("대상 앱/카테고리 선택") {
                    isPickerPresented = true
                }
                .buttonStyle(.bordered)

                Text("선택된 대상: \(viewModel.selectedTargetCount)개")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Stepper(
                    value: Binding(
                        get: { viewModel.defaultDurationMinutes },
                        set: { viewModel.updateDefaultDuration($0) }
                    ),
                    in: 1...180
                ) {
                    Text("기본 사용 시간: \(viewModel.defaultDurationMinutes)분")
                }

                Stepper(
                    value: Binding(
                        get: { viewModel.reminderOffsetMinutes },
                        set: { viewModel.updateReminderOffset($0) }
                    ),
                    in: 1...max(1, viewModel.defaultDurationMinutes - 1)
                ) {
                    Text("리마인드 시점: 종료 \(viewModel.reminderOffsetMinutes)분 전")
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                Task { await viewModel.saveInitialSetup() }
            } label: {
                if viewModel.isSavingPolicy {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("선택한 정책 저장")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedTargetCount == 0 || viewModel.isSavingPolicy)

            if let message = viewModel.policySaveMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text("저장된 정책: \(viewModel.policyCount)개")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var notificationPermissionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            permissionCard(
                title: "알림 권한",
                status: notificationText(viewModel.snapshot.notifications),
                lines: [
                    "종료 전 리마인드 알림으로 세션 마무리를 도와줍니다.",
                    "알림은 나중에 설정 화면에서 언제든 바꿀 수 있습니다."
                ],
                actionTitle: notificationActionTitle(viewModel.snapshot.notifications),
                actionEnabled: viewModel.snapshot.notifications != .authorized
            ) {
                switch viewModel.snapshot.notifications {
                case .authorized:
                    break
                case .denied:
                    openAppSettings()
                case .notDetermined:
                    Task { await viewModel.requestNotifications() }
                }
            }

            Button("지금은 건너뛰기") {
                viewModel.skipNotifications()
                viewModel.goNext()
            }
            .buttonStyle(.bordered)

            if let hint = viewModel.notificationHint {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var completionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusSummaryRow(label: "Screen Time", value: screenTimeText(viewModel.snapshot.screenTime))
            statusSummaryRow(label: "알림", value: notificationText(viewModel.snapshot.notifications))
            statusSummaryRow(label: "저장된 정책", value: "\(viewModel.policyCount)개")

            Text("이제 첫 목표를 선택해서 바로 시작할 수 있습니다.")
                .foregroundStyle(.secondary)
        }
    }

    private var stepFooter: some View {
        VStack(spacing: 8) {
            Button(primaryCTAButtonTitle) {
                primaryCTAAction()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.step != .done && !viewModel.canMoveNext)

            if viewModel.step != .landing && viewModel.step != .done {
                Button("뒤로") {
                    viewModel.goBack()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private func onboardingFeatureCard(systemImage: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func onboardingFlowRow(index: Int, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption.bold())
                .frame(width: 24, height: 24)
                .background(Color(.secondarySystemBackground))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func permissionCard(
        title: String,
        status: String,
        lines: [String],
        actionTitle: String,
        actionEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(lines, id: \.self) { line in
                Text("• \(line)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button(actionTitle, action: action)
                .buttonStyle(.bordered)
                .disabled(!actionEnabled)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func statusSummaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var primaryCTAButtonTitle: String {
        switch viewModel.step {
        case .landing:
            return "시작하기"
        case .explain:
            return "권한 설정 시작"
        case .screenTimePermission:
            return "다음"
        case .initialSetup:
            return "다음"
        case .notificationPermission:
            return "다음"
        case .done:
            return "첫 목표로 시작하기"
        }
    }

    private func primaryCTAAction() {
        if viewModel.step == .done {
            onCompleted()
            return
        }

        viewModel.goNext()
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

    private func screenTimeActionTitle(_ status: ScreenTimePermissionStatus) -> String {
        switch status {
        case .approved:
            return "허용 완료"
        case .denied:
            return "설정에서 허용"
        case .notDetermined:
            return "권한 요청"
        }
    }

    private func notificationActionTitle(_ status: NotificationPermissionStatus) -> String {
        switch status {
        case .authorized:
            return "허용 완료"
        case .denied:
            return "설정에서 허용"
        case .notDetermined:
            return "알림 켜기"
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(url)
    }
}
