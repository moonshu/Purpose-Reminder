import AppIntents
import Foundation

struct PurposeReminderShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickStartIntent(),
            phrases: [
                "\(.applicationName)에서 빠른 목표 시작",
                "빠른 목표 시작 \(.applicationName)"
            ],
            shortTitle: "빠른 목표 시작",
            systemImageName: "bolt.fill"
        )
        AppShortcut(
            intent: FavoriteStartIntent(),
            phrases: [
                "\(.applicationName)에서 즐겨찾기 목표 시작",
                "즐겨찾기 목표 시작 \(.applicationName)"
            ],
            shortTitle: "즐겨찾기 목표 시작",
            systemImageName: "star.fill"
        )
    }
}
