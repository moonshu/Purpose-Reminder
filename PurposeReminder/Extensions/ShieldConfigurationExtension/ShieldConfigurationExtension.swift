import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration(
            titleText: "지금 목표를 먼저 정해요",
            subtitleText: "목표를 선택하면 계획한 시간만 사용할 수 있어요."
        )
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        makeConfiguration(
            titleText: "이 카테고리 앱은 목표 선택 후 사용할 수 있어요",
            subtitleText: "빠른 목표를 탭해서 바로 시작해 보세요."
        )
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration(
            titleText: "웹 사용 전에 목표를 확인해요",
            subtitleText: "목표를 정하면 불필요한 탐색을 줄일 수 있어요."
        )
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        makeConfiguration(
            titleText: "목표 기반으로 사용을 시작해요",
            subtitleText: "목표를 고른 뒤 필요한 만큼만 사용해 보세요."
        )
    }

    private func makeConfiguration(titleText: String, subtitleText: String) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .light,
            backgroundColor: UIColor(red: 0.94, green: 0.97, blue: 1.0, alpha: 1.0),
            icon: UIImage(systemName: "target"),
            title: ShieldConfiguration.Label(
                text: titleText,
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "목표 선택",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(
                red: 0.1,
                green: 0.25,
                blue: 0.55,
                alpha: 1.0
            ),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "지금은 닫기",
                color: .secondaryLabel
            )
        )
    }
}
