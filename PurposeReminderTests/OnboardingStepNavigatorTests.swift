import XCTest
@testable import PurposeReminder

final class OnboardingStepNavigatorTests: XCTestCase {
    func testMoveNextRequiresScreenTimePermissionFromPermissionStep() {
        var navigator = OnboardingStepNavigator()

        XCTAssertTrue(navigator.moveNext(hasScreenTimeAccess: false, hasSavedPolicy: false))
        XCTAssertEqual(navigator.currentStep, .explain)

        XCTAssertTrue(navigator.moveNext(hasScreenTimeAccess: false, hasSavedPolicy: false))
        XCTAssertEqual(navigator.currentStep, .screenTimePermission)

        XCTAssertFalse(navigator.moveNext(hasScreenTimeAccess: false, hasSavedPolicy: false))
        XCTAssertEqual(navigator.currentStep, .screenTimePermission)

        XCTAssertTrue(navigator.moveNext(hasScreenTimeAccess: true, hasSavedPolicy: false))
        XCTAssertEqual(navigator.currentStep, .initialSetup)
    }

    func testMoveNextRequiresPolicySaveFromInitialSetupStep() {
        var navigator = OnboardingStepNavigator()

        _ = navigator.moveNext(hasScreenTimeAccess: true, hasSavedPolicy: true)
        _ = navigator.moveNext(hasScreenTimeAccess: true, hasSavedPolicy: true)
        _ = navigator.moveNext(hasScreenTimeAccess: true, hasSavedPolicy: true)

        XCTAssertEqual(navigator.currentStep, .initialSetup)
        XCTAssertFalse(navigator.moveNext(hasScreenTimeAccess: true, hasSavedPolicy: false))
        XCTAssertEqual(navigator.currentStep, .initialSetup)

        XCTAssertTrue(navigator.moveNext(hasScreenTimeAccess: true, hasSavedPolicy: true))
        XCTAssertEqual(navigator.currentStep, .notificationPermission)
    }

    func testMoveBackReturnsPreviousStep() {
        var navigator = OnboardingStepNavigator()

        _ = navigator.moveNext(hasScreenTimeAccess: true, hasSavedPolicy: true)
        _ = navigator.moveNext(hasScreenTimeAccess: true, hasSavedPolicy: true)
        XCTAssertEqual(navigator.currentStep, .screenTimePermission)

        XCTAssertTrue(navigator.moveBack())
        XCTAssertEqual(navigator.currentStep, .explain)

        XCTAssertTrue(navigator.moveBack())
        XCTAssertEqual(navigator.currentStep, .landing)

        XCTAssertFalse(navigator.moveBack())
        XCTAssertEqual(navigator.currentStep, .landing)
    }
}
