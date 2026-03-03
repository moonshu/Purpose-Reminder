import Foundation

enum OnboardingStep: Int, CaseIterable {
    case landing
    case explain
    case screenTimePermission
    case initialSetup
    case notificationPermission
    case done

    var title: String {
        switch self {
        case .landing:
            return "앱을 열기 전에, 목적부터 정하세요"
        case .explain:
            return "Purpose Reminder는 이렇게 동작합니다"
        case .screenTimePermission:
            return "먼저 Screen Time 권한이 필요합니다"
        case .initialSetup:
            return "최소 설정을 완료해 주세요"
        case .notificationPermission:
            return "리마인드 알림을 설정하세요"
        case .done:
            return "온보딩이 완료되었습니다"
        }
    }

    var subtitle: String {
        switch self {
        case .landing:
            return "무의식 진입을 줄이고 필요한 행동만 끝내도록 도와줍니다."
        case .explain:
            return "등록 앱 진입 전 목표를 고르고, 제한 시간 동안만 사용합니다."
        case .screenTimePermission:
            return "핵심 개입 기능을 위해 필수 권한이 필요합니다."
        case .initialSetup:
            return "대상 앱 1개와 기본 사용 시간을 설정하면 바로 시작할 수 있습니다."
        case .notificationPermission:
            return "종료 시점 리마인드를 받으려면 알림 권한을 켜 주세요."
        case .done:
            return "이제 첫 목표를 선택하고 세션을 시작할 수 있습니다."
        }
    }

    var progressText: String {
        "\(rawValue + 1)/\(Self.allCases.count)"
    }

    var analyticsName: String {
        switch self {
        case .landing:
            return "landing"
        case .explain:
            return "explain"
        case .screenTimePermission:
            return "screen_time_permission"
        case .initialSetup:
            return "initial_setup"
        case .notificationPermission:
            return "notification_permission"
        case .done:
            return "done"
        }
    }
}

struct OnboardingStepNavigator {
    private(set) var currentStep: OnboardingStep = .landing

    mutating func moveNext(
        hasScreenTimeAccess: Bool,
        hasSavedPolicy: Bool
    ) -> Bool {
        switch currentStep {
        case .landing:
            currentStep = .explain
            return true
        case .explain:
            currentStep = .screenTimePermission
            return true
        case .screenTimePermission:
            guard hasScreenTimeAccess else {
                return false
            }
            currentStep = .initialSetup
            return true
        case .initialSetup:
            guard hasSavedPolicy else {
                return false
            }
            currentStep = .notificationPermission
            return true
        case .notificationPermission:
            currentStep = .done
            return true
        case .done:
            return false
        }
    }

    mutating func moveBack() -> Bool {
        switch currentStep {
        case .landing:
            return false
        case .explain:
            currentStep = .landing
            return true
        case .screenTimePermission:
            currentStep = .explain
            return true
        case .initialSetup:
            currentStep = .screenTimePermission
            return true
        case .notificationPermission:
            currentStep = .initialSetup
            return true
        case .done:
            currentStep = .notificationPermission
            return true
        }
    }
}
