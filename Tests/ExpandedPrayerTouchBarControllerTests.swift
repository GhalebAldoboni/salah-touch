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
}
