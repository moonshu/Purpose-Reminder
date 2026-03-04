import Foundation

enum SessionCoordinatorState: Equatable {
    case idle
    case pendingGoal
    case active(sessionId: UUID)
    case reminded(sessionId: UUID)
}

enum SessionCoordinatorError: LocalizedError, Equatable {
    case invalidTransition(from: SessionCoordinatorState, event: String)
    case activeSessionMissing
    case sessionNotActive

    var errorDescription: String? {
        switch self {
        case let .invalidTransition(from, event):
            return "허용되지 않은 상태 전이입니다. state=\(from), event=\(event)"
        case .activeSessionMissing:
            return "활성 세션을 찾을 수 없습니다."
        case .sessionNotActive:
            return "세션이 active 상태가 아닙니다."
        }
    }
}

@MainActor
final class SessionCoordinator {
    private(set) var state: SessionCoordinatorState = .idle

    private let repository: GoalSessionRepository
    private let timeProvider: TimeProviderProtocol

    init(
        repository: GoalSessionRepository,
        timeProvider: TimeProviderProtocol = SystemTimeProvider()
    ) {
        self.repository = repository
        self.timeProvider = timeProvider
    }

    func beginGoalSelection() throws {
        guard state == .idle else {
            throw SessionCoordinatorError.invalidTransition(from: state, event: "beginGoalSelection")
        }
        state = .pendingGoal
    }

    func startSession(
        targetAppTokenData: Data,
        templateId: UUID?,
        goalText: String,
        plannedDurationMinutes: Int
    ) async throws -> GoalSession {
        guard case .pendingGoal = state else {
            throw SessionCoordinatorError.invalidTransition(from: state, event: "startSession")
        }

        let session = GoalSession(
            targetAppTokenData: targetAppTokenData,
            templateId: templateId,
            goalTextSnapshot: goalText,
            startedAt: timeProvider.now,
            endedAt: nil,
            status: .active,
            plannedDurationMinutes: plannedDurationMinutes
        )

        try await repository.save(session)
        state = .active(sessionId: session.id)
        return session
    }

    func markReminded() throws {
        guard case let .active(sessionId) = state else {
            throw SessionCoordinatorError.invalidTransition(from: state, event: "markReminded")
        }
        state = .reminded(sessionId: sessionId)
    }

    func completeSession() async throws -> GoalSession {
        let session = try await updateCurrentSession(status: .completed, durationDeltaMinutes: 0)
        state = .idle
        return session
    }

    func extendSession(by minutes: Int = Constants.Session.extensionDurationMinutes) async throws -> GoalSession {
        guard minutes > 0 else {
            throw SessionCoordinatorError.invalidTransition(from: state, event: "extendSession")
        }

        let session = try await updateCurrentSession(status: .extended, durationDeltaMinutes: minutes)
        state = .idle
        return session
    }

    func abandonSession() async throws -> GoalSession {
        let session = try await updateCurrentSession(status: .abandoned, durationDeltaMinutes: 0)
        state = .idle
        return session
    }

    func timeoutSession() async throws -> GoalSession {
        let session = try await updateCurrentSession(status: .timedOut, durationDeltaMinutes: 0)
        state = .idle
        return session
    }

    func attachToActiveSessionIfNeeded(sessionId: UUID) async throws {
        switch state {
        case let .active(id), let .reminded(id):
            if id == sessionId {
                return
            }
            throw SessionCoordinatorError.invalidTransition(
                from: state,
                event: "attachToActiveSessionIfNeeded"
            )
        case .pendingGoal:
            throw SessionCoordinatorError.invalidTransition(
                from: state,
                event: "attachToActiveSessionIfNeeded"
            )
        case .idle:
            break
        }

        guard let session = try await repository.fetch(id: sessionId) else {
            throw SessionCoordinatorError.activeSessionMissing
        }

        guard session.status == .active, session.endedAt == nil else {
            throw SessionCoordinatorError.sessionNotActive
        }

        state = .active(sessionId: session.id)
    }

    private func updateCurrentSession(
        status: SessionStatus,
        durationDeltaMinutes: Int
    ) async throws -> GoalSession {
        let sessionId: UUID
        switch state {
        case let .active(id), let .reminded(id):
            sessionId = id
        default:
            throw SessionCoordinatorError.invalidTransition(from: state, event: "updateSession")
        }

        guard var session = try await repository.fetch(id: sessionId) else {
            throw SessionCoordinatorError.activeSessionMissing
        }

        session.status = status
        session.endedAt = timeProvider.now
        session.plannedDurationMinutes += durationDeltaMinutes
        try await repository.save(session)
        return session
    }
}
