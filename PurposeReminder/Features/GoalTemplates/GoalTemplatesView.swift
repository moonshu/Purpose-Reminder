import SwiftUI
import Combine

enum GoalTemplateFilter: String, CaseIterable, Identifiable {
    case all
    case favorites

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "전체"
        case .favorites:
            return "즐겨찾기"
        }
    }
}

@MainActor
final class GoalTemplatesViewModel: ObservableObject {
    struct EditingDraft: Identifiable, Equatable {
        let id: UUID
        var text: String
    }

    @Published private(set) var templates: [GoalTemplate] = []
    @Published var draftText: String = ""
    @Published var selectedFilter: GoalTemplateFilter = .all
    @Published var editingDraft: EditingDraft?
    @Published private(set) var isLoading = false
    @Published private(set) var isProcessing = false
    @Published var errorMessage: String?

    private let repository: GoalTemplateRepository
    private let targetAppTokenData: Data?
    private let nowProvider: () -> Date

    init(
        repository: GoalTemplateRepository,
        targetAppTokenData: Data? = nil,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.targetAppTokenData = targetAppTokenData
        self.nowProvider = nowProvider
    }

    convenience init(targetAppTokenData: Data? = nil) {
        self.init(
            repository: SwiftDataGoalTemplateRepository(context: SwiftDataStack.shared.mainContext),
            targetAppTokenData: targetAppTokenData
        )
    }

    var filteredTemplates: [GoalTemplate] {
        switch selectedFilter {
        case .all:
            return templates
        case .favorites:
            return templates.filter(\.isFavorite)
        }
    }

    var canCreateTemplate: Bool {
        !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let all = try await repository.fetchAll()
            templates = sortTemplates(all)
            errorMessage = nil
        } catch {
            templates = []
            errorMessage = "템플릿을 불러오지 못했습니다."
        }
    }

    func createTemplate() async {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "템플릿 문구를 입력해 주세요."
            return
        }

        guard !hasDuplicate(text: trimmed, excluding: nil) else {
            errorMessage = "동일한 템플릿이 이미 존재합니다."
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let newTemplate = GoalTemplate(
                targetAppTokenData: targetAppTokenData,
                text: trimmed,
                isFavorite: false,
                useCount: 0,
                lastUsedAt: nil,
                createdAt: nowProvider()
            )
            try await repository.save(newTemplate)
            draftText = ""
            await load()
        } catch {
            errorMessage = "템플릿 저장에 실패했습니다."
        }
    }

    func beginEditing(_ template: GoalTemplate) {
        editingDraft = EditingDraft(id: template.id, text: template.text)
    }

    func saveEditingDraft() async {
        guard let editingDraft else {
            return
        }

        let trimmed = editingDraft.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "템플릿 문구를 입력해 주세요."
            return
        }

        guard !hasDuplicate(text: trimmed, excluding: editingDraft.id) else {
            errorMessage = "동일한 템플릿이 이미 존재합니다."
            return
        }

        guard var existing = templates.first(where: { $0.id == editingDraft.id }) else {
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            existing.text = trimmed
            try await repository.save(existing)
            self.editingDraft = nil
            await load()
        } catch {
            errorMessage = "템플릿 수정에 실패했습니다."
        }
    }

    func toggleFavorite(id: UUID) async {
        guard var existing = templates.first(where: { $0.id == id }) else {
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            existing.isFavorite.toggle()
            try await repository.save(existing)
            await load()
        } catch {
            errorMessage = "즐겨찾기 변경에 실패했습니다."
        }
    }

    func deleteTemplate(id: UUID) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await repository.delete(id: id)
            await load()
        } catch {
            errorMessage = "템플릿 삭제에 실패했습니다."
        }
    }

    private func hasDuplicate(text: String, excluding id: UUID?) -> Bool {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return templates.contains { template in
            if let id, template.id == id {
                return false
            }
            let sameScope = template.targetAppTokenData == targetAppTokenData
            let sameText = template.text.trimmingCharacters(in: .whitespacesAndNewlines) == normalized
            return sameScope && sameText
        }
    }

    private func sortTemplates(_ templates: [GoalTemplate]) -> [GoalTemplate] {
        templates.sorted { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite {
                return lhs.isFavorite && !rhs.isFavorite
            }

            switch (lhs.lastUsedAt, rhs.lastUsedAt) {
            case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
                return lhsDate > rhsDate
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                break
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
}

struct GoalTemplatesView: View {
    @StateObject private var viewModel: GoalTemplatesViewModel

    init(viewModel: GoalTemplatesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    init(targetAppTokenData: Data? = nil) {
        _viewModel = StateObject(
            wrappedValue: GoalTemplatesViewModel(targetAppTokenData: targetAppTokenData)
        )
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

            Section("새 템플릿") {
                TextField("예: DM 3개만 답장", text: $viewModel.draftText)
                Button("추가") {
                    Task { await viewModel.createTemplate() }
                }
                .disabled(!viewModel.canCreateTemplate)
            }

            Section {
                Picker("필터", selection: $viewModel.selectedFilter) {
                    ForEach(GoalTemplateFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("템플릿 목록") {
                if viewModel.filteredTemplates.isEmpty && !viewModel.isLoading {
                    EmptyStateCard(
                        iconName: "text.badge.plus",
                        title: "등록된 템플릿이 없습니다.",
                        subtitle: "자주 하는 목표 문구를 추가하면 세션을 더 빠르게 시작할 수 있습니다."
                    )
                } else {
                    ForEach(viewModel.filteredTemplates) { template in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(template.text)
                                .font(.body)

                            HStack(spacing: 8) {
                                if template.isFavorite {
                                    Label("즐겨찾기", systemImage: "star.fill")
                                        .foregroundStyle(.yellow)
                                }
                                Text("사용 \(template.useCount)회")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                Task { await viewModel.toggleFavorite(id: template.id) }
                            } label: {
                                Label(
                                    template.isFavorite ? "즐겨찾기 해제" : "즐겨찾기",
                                    systemImage: template.isFavorite ? "star.slash" : "star"
                                )
                            }
                            .tint(.yellow)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteTemplate(id: template.id) }
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }

                            Button {
                                viewModel.beginEditing(template)
                            } label: {
                                Label("수정", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("목표 템플릿")
        .overlay {
            if viewModel.isLoading || viewModel.isProcessing {
                ProgressView()
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(item: $viewModel.editingDraft) { _ in
            NavigationStack {
                Form {
                    TextField(
                        "템플릿 문구",
                        text: Binding(
                            get: { viewModel.editingDraft?.text ?? "" },
                            set: {
                                guard let editing = viewModel.editingDraft else {
                                    return
                                }
                                viewModel.editingDraft = .init(id: editing.id, text: $0)
                            }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                }
                .navigationTitle("템플릿 수정")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("취소") {
                            viewModel.editingDraft = nil
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("저장") {
                            Task { await viewModel.saveEditingDraft() }
                        }
                    }
                }
            }
        }
    }
}
