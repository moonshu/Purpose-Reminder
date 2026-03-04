import SwiftUI
import Combine
import FamilyControls

@MainActor
final class PolicySettingsViewModel: ObservableObject {
    @Published var selection = FamilyActivitySelection()
    @Published private(set) var drafts: [PolicyDraft] = []
    @Published private(set) var templates: [GoalTemplate] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let repository: AppPolicyRepository
    private let templateRepository: GoalTemplateRepository
    private let appSelectionService: AppSelectionServicing
    private let shieldPolicyService: ShieldPolicyServicing
    private let tokenCodec = PolicyTargetTokenCodec()

    init(
        repository: AppPolicyRepository,
        templateRepository: GoalTemplateRepository,
        appSelectionService: AppSelectionServicing,
        shieldPolicyService: ShieldPolicyServicing
    ) {
        self.repository = repository
        self.templateRepository = templateRepository
        self.appSelectionService = appSelectionService
        self.shieldPolicyService = shieldPolicyService
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let policies = try await repository.fetchAll().filter(\.isActive)
            templates = try await templateRepository.fetchAll()
            selection = appSelectionService.makeSelection(from: policies)
            drafts = policies.map(PolicyDraft.init(policy:))
            syncDraftsWithSelection()
        } catch {
            errorMessage = "정책을 불러오지 못했습니다. 다시 시도해 주세요."
        }
    }

    func syncDraftsWithSelection(defaultDurationMinutes: Int = Constants.Session.defaultDurationMinutes,
                                 reminderOffsetMinutes: Int = Constants.Session.defaultReminderOffsetMinutes) {
        let mergedPolicies = appSelectionService.makePolicies(
            from: selection,
            existingPolicies: drafts.map(\.asPolicy),
            defaultDurationMinutes: defaultDurationMinutes,
            reminderOffsetMinutes: reminderOffsetMinutes
        )

        drafts = mergedPolicies
            .map(PolicyDraft.init(policy:))
            .sorted { $0.id.uuidString < $1.id.uuidString }

        normalizeDraftDefaultTemplates()
    }

    func save() async {
        guard !drafts.isEmpty else {
            errorMessage = "최소 1개 앱을 선택해야 정책을 저장할 수 있습니다."
            successMessage = nil
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let existingPolicies = try await repository.fetchAll()
            let selectedIds = Set(drafts.map(\.id))

            for draft in drafts {
                var normalized = draft
                normalized.defaultTemplateId = normalizedDefaultTemplateId(for: draft)
                try await repository.save(normalized.asPolicy)
            }

            for policy in existingPolicies where !selectedIds.contains(policy.id) {
                try await repository.delete(id: policy.id)
            }

            let refreshed = try await repository.fetchAll().filter(\.isActive)
            try shieldPolicyService.applyPolicies(refreshed)
            selection = appSelectionService.makeSelection(from: refreshed)
            drafts = refreshed
                .map(PolicyDraft.init(policy:))
                .sorted { $0.id.uuidString < $1.id.uuidString }

            successMessage = "정책이 저장되었습니다."
            errorMessage = nil
        } catch {
            errorMessage = "정책 저장 중 오류가 발생했습니다."
            successMessage = nil
        }
    }

    func templateOptions(for draft: PolicyDraft) -> [GoalTemplate] {
        let scoped = templates.filter { template in
            guard let templateTokenData = template.targetAppTokenData else {
                return true
            }
            return doesTemplateTokenMatchPolicy(
                templateTokenData: templateTokenData,
                policyTokenData: draft.appTokenData
            )
        }

        return scoped.sorted { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite {
                return lhs.isFavorite && !rhs.isFavorite
            }

            if lhs.useCount != rhs.useCount {
                return lhs.useCount > rhs.useCount
            }

            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }

            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    func updateDefaultTemplate(for id: UUID, templateId: UUID?) {
        updateDraft(id: id) { draft in
            draft.defaultTemplateId = templateId
        }
    }

    func updateDuration(for id: UUID, value: Int) {
        updateDraft(id: id) { draft in
            draft.defaultDurationMinutes = max(1, value)
            if draft.reminderOffsetMinutes >= draft.defaultDurationMinutes {
                draft.reminderOffsetMinutes = max(1, draft.defaultDurationMinutes - 1)
            }
        }
    }

    func updateReminderOffset(for id: UUID, value: Int) {
        updateDraft(id: id) { draft in
            draft.reminderOffsetMinutes = min(max(1, value), max(1, draft.defaultDurationMinutes - 1))
        }
    }

    private func updateDraft(id: UUID, update: (inout PolicyDraft) -> Void) {
        guard let index = drafts.firstIndex(where: { $0.id == id }) else {
            return
        }

        var copied = drafts[index]
        update(&copied)
        drafts[index] = copied
    }

    private func normalizeDraftDefaultTemplates() {
        drafts = drafts.map { draft in
            var normalized = draft
            normalized.defaultTemplateId = normalizedDefaultTemplateId(for: draft)
            return normalized
        }
    }

    private func normalizedDefaultTemplateId(for draft: PolicyDraft) -> UUID? {
        guard let defaultTemplateId = draft.defaultTemplateId else {
            return nil
        }

        return templateOptions(for: draft)
            .contains(where: { $0.id == defaultTemplateId }) ? defaultTemplateId : nil
    }

    private func doesTemplateTokenMatchPolicy(
        templateTokenData: Data,
        policyTokenData: Data
    ) -> Bool {
        // Fast path: exact byte match for same encoding strategy.
        if templateTokenData == policyTokenData {
            return true
        }

        guard let policyTarget = try? tokenCodec.decode(from: policyTokenData),
              let templateTarget = try? tokenCodec.decode(from: templateTokenData) else {
            return false
        }

        switch (policyTarget, templateTarget) {
        case let (.application(policyToken), .application(templateToken)):
            return policyToken == templateToken
        default:
            return false
        }
    }
}

struct PolicyDraft: Identifiable, Equatable {
    let id: UUID
    let appTokenData: Data
    var isActive: Bool
    var defaultDurationMinutes: Int
    var reminderOffsetMinutes: Int
    var defaultTemplateId: UUID?

    init(policy: AppPolicy) {
        self.id = policy.id
        self.appTokenData = policy.appTokenData
        self.isActive = policy.isActive
        self.defaultDurationMinutes = policy.defaultDurationMinutes
        self.reminderOffsetMinutes = policy.reminderOffsetMinutes
        self.defaultTemplateId = policy.defaultTemplateId
    }

    var asPolicy: AppPolicy {
        AppPolicy(
            id: id,
            appTokenData: appTokenData,
            isActive: isActive,
            defaultDurationMinutes: defaultDurationMinutes,
            reminderOffsetMinutes: reminderOffsetMinutes,
            defaultTemplateId: defaultTemplateId
        )
    }
}

struct PolicySettingsView: View {
    @StateObject private var viewModel: PolicySettingsViewModel
    @State private var isPickerPresented = false

    init(
        repository: AppPolicyRepository,
        templateRepository: GoalTemplateRepository,
        appSelectionService: AppSelectionServicing = AppSelectionService(),
        shieldPolicyService: ShieldPolicyServicing = ShieldPolicyService()
    ) {
        _viewModel = StateObject(
            wrappedValue: PolicySettingsViewModel(
                repository: repository,
                templateRepository: templateRepository,
                appSelectionService: appSelectionService,
                shieldPolicyService: shieldPolicyService
            )
        )
    }

    @MainActor
    init(
        appSelectionService: AppSelectionServicing = AppSelectionService(),
        shieldPolicyService: ShieldPolicyServicing = ShieldPolicyService()
    ) {
        self.init(
            repository: SwiftDataAppPolicyRepository(context: SwiftDataStack.shared.mainContext),
            templateRepository: SwiftDataGoalTemplateRepository(context: SwiftDataStack.shared.mainContext),
            appSelectionService: appSelectionService,
            shieldPolicyService: shieldPolicyService
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("대상 앱 선택") {
                        isPickerPresented = true
                    }

                    Text(
                        """
                        선택된 대상: 앱 \(viewModel.selection.applicationTokens.count)개 · \
                        카테고리 \(viewModel.selection.categoryTokens.count)개 · \
                        웹 \(viewModel.selection.webDomainTokens.count)개
                        """
                    )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("앱 목록이 보이지 않으면 카테고리 선택으로도 정책 저장/실험이 가능합니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

#if targetEnvironment(simulator)
                    Text("시뮬레이터에서는 설치 앱 목록이 제한될 수 있어 실기기 테스트가 필요합니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
#endif
                } header: {
                    Text("대상 앱")
                }

                Section {
                    if viewModel.drafts.isEmpty {
                        Text("앱을 선택해 정책을 추가하세요.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(viewModel.drafts.enumerated()), id: \.element.id) { index, draft in
                            VStack(alignment: .leading, spacing: 12) {
                                Text("대상 정책 \(index + 1)")
                                    .font(.headline)

                                Stepper(value: Binding(
                                    get: { draft.defaultDurationMinutes },
                                    set: { viewModel.updateDuration(for: draft.id, value: $0) }
                                ), in: 1...180) {
                                    Text("기본 사용 시간: \(draft.defaultDurationMinutes)분")
                                }

                                Stepper(value: Binding(
                                    get: { draft.reminderOffsetMinutes },
                                    set: { viewModel.updateReminderOffset(for: draft.id, value: $0) }
                                ), in: 1...max(1, draft.defaultDurationMinutes - 1)) {
                                    Text("리마인드 시점: 종료 \(draft.reminderOffsetMinutes)분 전")
                                }

                                Picker(
                                    "기본 템플릿",
                                    selection: Binding(
                                        get: { draft.defaultTemplateId },
                                        set: { viewModel.updateDefaultTemplate(for: draft.id, templateId: $0) }
                                    )
                                ) {
                                    Text("없음").tag(UUID?.none)
                                    ForEach(viewModel.templateOptions(for: draft)) { template in
                                        Text(template.text).tag(Optional(template.id))
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("정책")
                } footer: {
                    Text("최소 1개 정책을 저장해야 다음 단계로 진행할 수 있습니다.")
                }
            }
            .navigationTitle("대상 앱 설정")
            .overlay {
                if viewModel.isLoading || viewModel.isSaving {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        Task {
                            await viewModel.save()
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
        }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $viewModel.selection)
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.selection, initial: false) {
            viewModel.syncDraftsWithSelection()
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
        .alert(
            "저장 완료",
            isPresented: Binding(
                get: { viewModel.successMessage != nil },
                set: { _ in viewModel.successMessage = nil }
            )
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }
}
