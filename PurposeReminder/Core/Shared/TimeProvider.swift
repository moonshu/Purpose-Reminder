import Foundation

/// 테스트 주입을 위한 시간 제공 추상화
protocol TimeProviderProtocol {
    var now: Date { get }
}

struct SystemTimeProvider: TimeProviderProtocol {
    var now: Date { Date() }
}
