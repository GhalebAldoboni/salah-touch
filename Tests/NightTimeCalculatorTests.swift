import Foundation
import Testing
@testable import PrayerTimeWidget

struct NightTimeCalculatorTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Dubai")!
        return calendar
    }()

    @Test func calculatesMidnightAndLastThirdForElevenHourNight() throws {
        let maghrib = date(year: 2026, month: 10, day: 16, hour: 18)
        let fajr = date(year: 2026, month: 10, day: 17, hour: 5)

        let period = try #require(NightTimeCalculator.period(maghrib: maghrib, nextFajr: fajr))

        #expect(period.midnight == date(year: 2026, month: 10, day: 16, hour: 23, minute: 30))
        #expect(period.lastThirdStart == date(year: 2026, month: 10, day: 17, hour: 1, minute: 20))
    }

    @Test func calculatesLastThirdForNineHourNight() throws {
        let maghrib = date(year: 2026, month: 10, day: 16, hour: 19)
        let fajr = date(year: 2026, month: 10, day: 17, hour: 4)

        let period = try #require(NightTimeCalculator.period(maghrib: maghrib, nextFajr: fajr))

        #expect(period.midnight == date(year: 2026, month: 10, day: 16, hour: 23, minute: 30))
        #expect(period.lastThirdStart == date(year: 2026, month: 10, day: 17, hour: 1))
    }

    @Test func rejectsFajrThatDoesNotFollowMaghrib() {
        let maghrib = date(year: 2026, month: 10, day: 16, hour: 19)
        let fajr = date(year: 2026, month: 10, day: 16, hour: 4)

        #expect(NightTimeCalculator.period(maghrib: maghrib, nextFajr: fajr) == nil)
    }

    @Test func rejectsNightLongerThanOneDay() {
        let maghrib = date(year: 2026, month: 10, day: 16, hour: 19)
        let fajr = date(year: 2026, month: 10, day: 17, hour: 20)

        #expect(NightTimeCalculator.period(maghrib: maghrib, nextFajr: fajr) == nil)
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int = 0
    ) -> Date {
        return calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }
}
