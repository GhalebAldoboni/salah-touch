import Foundation

struct NightPeriod: Equatable {
    let maghrib: Date
    let nextFajr: Date
    let midnight: Date
    let lastThirdStart: Date
}

enum NightTimeCalculator {
    static func period(maghrib: Date, nextFajr: Date) -> NightPeriod? {
        let duration = nextFajr.timeIntervalSince(maghrib)
        guard duration > 0, duration <= 24 * 60 * 60 else {
            return nil
        }

        return NightPeriod(
            maghrib: maghrib,
            nextFajr: nextFajr,
            midnight: maghrib.addingTimeInterval(duration / 2),
            lastThirdStart: maghrib.addingTimeInterval(duration * 2 / 3)
        )
    }
}
