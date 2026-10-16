import Testing
@testable import PrayerTimeWidget

@MainActor
struct ExpandedPrayerTouchBarControllerTests {
    @Test func closeNotificationIsIdempotent() {
        let controller = ExpandedPrayerTouchBarController()
        var closeCount = 0
        controller.onClose = {
            closeCount += 1
        }

        controller.dismiss()
        controller.dismiss()

        #expect(closeCount == 1)
    }

    @Test func repeatedMinimizeRequestsFinishOnlyOnce() {
        let controller = ExpandedPrayerTouchBarController()
        var closeCount = 0
        controller.onClose = {
            closeCount += 1
        }
        controller.isVisible = true

        controller.minimize()
        controller.minimize()

        #expect(controller.isVisible == false)
        #expect(closeCount == 1)
    }

    @Test func minimizingStopsCountdownUpdates() {
        let controller = ExpandedPrayerTouchBarController()
        controller.isVisible = true
        controller.startCountdownTimerIfNeeded()

        #expect(controller.hasActiveCountdownTimer)

        controller.minimize()

        #expect(controller.hasActiveCountdownTimer == false)
    }

    @Test func renderedScheduleAlwaysFinishesAnimatedClose() async throws {
        let controller = ExpandedPrayerTouchBarController()
        guard let touchBar = controller.makeTouchBar(),
              let identifier = touchBar.defaultItemIdentifiers.first else {
            Issue.record("Expanded Touch Bar could not be created")
            return
        }
        _ = controller.touchBar(touchBar, makeItemForIdentifier: identifier)
        controller.isVisible = true

        controller.minimize()
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(controller.isVisible == false)
    }
}
