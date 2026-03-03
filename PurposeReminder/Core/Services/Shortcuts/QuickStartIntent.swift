import AppIntents
import Foundation

struct QuickStartIntent: AppIntent {
    static var title: LocalizedStringResource = "빠른 목표 시작"
    static var description = IntentDescription("목표와 시간을 지정해 세션을 바로 시작합니다.")
    static var openAppWhenRun = true

    @Parameter(title: "목표")
    var goalText: String

    @Parameter(title: "시간(분)", default: 20)
    var durationMinutes: Int

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let starter = IntentSessionStarter()
        let result = await starter.startQuick(
            goalText: goalText,
            durationMinutes: durationMinutes
        )

        return .result(dialog: IntentDialog(stringLiteral: result.message))
    }
}
