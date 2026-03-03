import AppIntents
import Foundation

struct FavoriteStartIntent: AppIntent {
    static var title: LocalizedStringResource = "즐겨찾기 목표 시작"
    static var description = IntentDescription("즐겨찾기 목표로 세션을 바로 시작합니다.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let starter = IntentSessionStarter()
        let result = await starter.startFavorite()
        return .result(dialog: IntentDialog(stringLiteral: result.message))
    }
}
