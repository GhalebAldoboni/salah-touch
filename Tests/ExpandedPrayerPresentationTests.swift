import Foundation
import Testing
@testable import PrayerTimeWidget

struct ExpandedPrayerPresentationTests {
    @Test func activeIqamaPrayerTakesPriorityOverNextPrayer() {
        let iqamaPrayer = Date(timeIntervalSince1970: 1_000)
        let nextPrayer = Date(timeIntervalSince1970: 2_000)

        #expect(ExpandedPrayerPresentation.highlightedPrayerDate(
            nextPrayer: nextPrayer,
            activeIqamaPrayer: iqamaPrayer
        ) == iqamaPrayer)
    }

    @Test func entryShowsLiveIqamaRemainingTime() {
        let now = Date(timeIntervalSince1970: 1_000)
        let entry = PrayerTouchBarEntry(
            name: "Asr",
            time: "3:23 PM",
            isUpcomingPrayer: true,
            isNightMarker: false,
            countdownTarget: now.addingTimeInterval(19 * 60)
        )

        #expect(entry.displayedTime(at: now) == "19:00")
        #expect(entry.displayedTime(at: now.addingTimeInterval(30)) == "18:30")
    }
}
