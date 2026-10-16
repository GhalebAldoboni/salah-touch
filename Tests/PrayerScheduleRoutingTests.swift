import CoreLocation
import Foundation
import Testing
@testable import PrayerTimeWidget

struct PrayerScheduleRoutingTests {
    @Test func routesUaeCoordinatesToAwqaf() {
        #expect(PrayerScheduleRouting.source(for: coordinate(25.2048, 55.2708)) == .awqaf)
        #expect(PrayerScheduleRouting.source(for: coordinate(24.4539, 54.3773)) == .awqaf)
        #expect(PrayerScheduleRouting.source(for: coordinate(25.1288, 56.3265)) == .awqaf)
    }

    @Test func routesOtherCountriesToAlAdhan() {
        #expect(PrayerScheduleRouting.source(for: coordinate(51.5074, -0.1278)) == .alAdhan)
        #expect(PrayerScheduleRouting.source(for: coordinate(25.2854, 51.5310)) == .alAdhan)
        #expect(PrayerScheduleRouting.source(for: coordinate(-33.8688, 151.2093)) == .alAdhan)
    }

    @Test func prefersResolvedCountry() {
        let border = coordinate(24.25, 55.75)
        #expect(PrayerScheduleRouting.source(for: border, countryCode: "OM") == .alAdhan)
        #expect(PrayerScheduleRouting.source(for: border, countryCode: "ae") == .awqaf)
    }

    @Test func decodesAlAdhanSchedule() throws {
        let schedule = try #require(AlAdhanScheduleDecoder.decode(Data(fixture.utf8)))
        #expect(schedule.timezone.identifier == "Europe/London")
        #expect(schedule.moments.map(\.key) == ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"])
    }

    @Test func rejectsIncompleteSchedule() {
        let incomplete = fixture.replacingOccurrences(
            of: "\"Isha\":\"2026-10-16T19:50:00+01:00\"",
            with: ""
        )
        #expect(AlAdhanScheduleDecoder.decode(Data(incomplete.utf8)) == nil)
    }

    @Test func buildsValidatedGlobalRequest() throws {
        let url = try #require(AlAdhanScheduleClient.requestURL(
            date: "16-10-2026",
            coordinate: coordinate(51.5074, -0.1278),
            school: .hanafi
        ))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
        #expect(query["latitude"] == "51.507")
        #expect(query["longitude"] == "-0.128")
        #expect(query["school"] == "1")
        #expect(query["iso8601"] == "true")
        #expect(query["method"] == nil)
    }

    @Test func rejectsInvalidCoordinates() {
        #expect(AlAdhanScheduleClient.requestURL(
            date: "16-10-2026",
            coordinate: coordinate(91, 0)
        ) == nil)
    }

    private func coordinate(_ latitude: Double, _ longitude: Double) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private var fixture: String {
        return """
        {"code":200,"data":{"timings":{"Fajr":"2026-10-16T05:35:00+01:00","Dhuhr":"2026-10-16T12:46:00+01:00","Asr":"2026-10-16T15:33:00+01:00","Maghrib":"2026-10-16T18:05:00+01:00","Isha":"2026-10-16T19:50:00+01:00"},"meta":{"timezone":"Europe/London"}}}
        """
    }
}
