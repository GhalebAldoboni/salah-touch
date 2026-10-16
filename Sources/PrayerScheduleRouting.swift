import CoreLocation
import Foundation

enum PrayerScheduleSource: Equatable {
    case awqaf
    case alAdhan
}

enum PrayerAsrSchool: Int {
    case standard = 0
    case hanafi = 1
}

enum PrayerScheduleRouting {
    private static let uaeBoundary: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 22.63, longitude: 51.58),
        CLLocationCoordinate2D(latitude: 24.20, longitude: 51.58),
        CLLocationCoordinate2D(latitude: 24.45, longitude: 51.75),
        CLLocationCoordinate2D(latitude: 24.90, longitude: 53.10),
        CLLocationCoordinate2D(latitude: 25.28, longitude: 54.50),
        CLLocationCoordinate2D(latitude: 25.82, longitude: 55.80),
        CLLocationCoordinate2D(latitude: 26.10, longitude: 56.10),
        CLLocationCoordinate2D(latitude: 25.55, longitude: 56.42),
        CLLocationCoordinate2D(latitude: 24.85, longitude: 56.40),
        CLLocationCoordinate2D(latitude: 24.20, longitude: 55.90),
        CLLocationCoordinate2D(latitude: 22.63, longitude: 55.25)
    ]

    static func source(
        for coordinate: CLLocationCoordinate2D,
        countryCode: String? = nil
    ) -> PrayerScheduleSource {
        if let countryCode = countryCode?.uppercased(), countryCode.isEmpty == false {
            return countryCode == "AE" ? .awqaf : .alAdhan
        }
        return contains(coordinate, in: uaeBoundary) ? .awqaf : .alAdhan
    }

    private static func contains(
        _ point: CLLocationCoordinate2D,
        in polygon: [CLLocationCoordinate2D]
    ) -> Bool {
        guard polygon.count >= 3 else { return false }
        var isInside = false
        var previousIndex = polygon.count - 1
        for currentIndex in polygon.indices {
            let current = polygon[currentIndex]
            let previous = polygon[previousIndex]
            if (current.latitude > point.latitude) != (previous.latitude > point.latitude) {
                let crossingLongitude = (previous.longitude - current.longitude)
                    * (point.latitude - current.latitude)
                    / (previous.latitude - current.latitude)
                    + current.longitude
                if point.longitude < crossingLongitude {
                    isInside.toggle()
                }
            }
            previousIndex = currentIndex
        }
        return isInside
    }
}

struct DecodedPrayerMoment: Equatable {
    let key: String
    let date: Date
}

struct DecodedPrayerSchedule {
    let moments: [DecodedPrayerMoment]
    let timezone: TimeZone
}

enum AlAdhanScheduleDecoder {
    private struct Response: Decodable {
        let code: Int
        let data: Payload
    }

    private struct Payload: Decodable {
        let timings: [String: String]
        let meta: Metadata
    }

    private struct Metadata: Decodable {
        let timezone: String
    }

    private static let prayerKeys = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]

    static func decode(_ data: Data) -> DecodedPrayerSchedule? {
        guard let response = try? JSONDecoder().decode(Response.self, from: data),
              response.code == 200,
              let timezone = TimeZone(identifier: response.data.meta.timezone) else {
            return nil
        }
        let formatter = ISO8601DateFormatter()
        let moments = prayerKeys.compactMap { key -> DecodedPrayerMoment? in
            guard let value = response.data.timings[key],
                  let date = formatter.date(from: value) else {
                return nil
            }
            return DecodedPrayerMoment(key: key, date: date)
        }
        guard moments.count == prayerKeys.count else { return nil }
        return DecodedPrayerSchedule(
            moments: moments.sorted { $0.date < $1.date },
            timezone: timezone
        )
    }
}

final class AlAdhanScheduleClient {
    typealias Completion = (DecodedPrayerSchedule?) -> Void

    private let session: URLSession
    private let stateQueue = DispatchQueue(label: "SalahTouch.AlAdhanScheduleClient")

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch(
        around date: Date,
        coordinate: CLLocationCoordinate2D,
        school: PrayerAsrSchool,
        completion: @escaping Completion
    ) {
        let estimatedHours = min(14, max(-12, Int((coordinate.longitude / 15).rounded())))
        let estimatedTimezone = TimeZone(secondsFromGMT: estimatedHours * 3600) ?? .current
        let estimatedDates = Self.dateStrings(around: date, timezone: estimatedTimezone)
        guard estimatedDates.count == 3,
              let anchorURL = Self.requestURL(
                date: estimatedDates[1],
                coordinate: coordinate,
                school: school
              ) else {
            completion(nil)
            return
        }

        fetchOne(anchorURL) { [weak self] anchor in
            guard let self = self, let anchor = anchor else {
                completion(nil)
                return
            }
            self.fetch(
                dates: Self.dateStrings(around: date, timezone: anchor.timezone),
                coordinate: coordinate,
                school: school,
                completion: completion
            )
        }
    }

    private func fetch(
        dates: [String],
        coordinate: CLLocationCoordinate2D,
        school: PrayerAsrSchool,
        completion: @escaping Completion
    ) {
        let urls = dates.compactMap {
            Self.requestURL(date: $0, coordinate: coordinate, school: school)
        }
        guard urls.count == dates.count else {
            completion(nil)
            return
        }

        let group = DispatchGroup()
        var schedules: [DecodedPrayerSchedule] = []
        for url in urls {
            group.enter()
            fetchOne(url) { [stateQueue] schedule in
                stateQueue.async {
                    if let schedule = schedule {
                        schedules.append(schedule)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: stateQueue) {
            guard schedules.count == urls.count,
                  let timezone = schedules.first?.timezone,
                  schedules.allSatisfy({ $0.timezone.identifier == timezone.identifier }) else {
                completion(nil)
                return
            }
            completion(DecodedPrayerSchedule(
                moments: schedules.flatMap(\.moments).sorted { $0.date < $1.date },
                timezone: timezone
            ))
        }
    }

    private func fetchOne(_ url: URL, completion: @escaping Completion) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        session.dataTask(with: request) { data, response, error in
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            let schedule = error == nil && statusCode == 200
                ? data.flatMap(AlAdhanScheduleDecoder.decode)
                : nil
            completion(schedule)
        }.resume()
    }

    static func requestURL(
        date: String,
        coordinate: CLLocationCoordinate2D,
        school: PrayerAsrSchool = .standard
    ) -> URL? {
        guard coordinate.latitude.isFinite,
              coordinate.longitude.isFinite,
              (-90...90).contains(coordinate.latitude),
              (-180...180).contains(coordinate.longitude) else {
            return nil
        }
        var components = URLComponents(string: "https://api.aladhan.com/v1/timings/\(date)")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: coordinate.latitude.posixString),
            URLQueryItem(name: "longitude", value: coordinate.longitude.posixString),
            URLQueryItem(name: "school", value: String(school.rawValue)),
            URLQueryItem(name: "iso8601", value: "true")
        ]
        return components?.url
    }

    private static func dateStrings(around date: Date, timezone: TimeZone) -> [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = timezone
        formatter.dateFormat = "dd-MM-yyyy"
        return [-1, 0, 1].compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: date).map(formatter.string(from:))
        }
    }
}

private extension Double {
    var posixString: String {
        return String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"), self)
    }
}
