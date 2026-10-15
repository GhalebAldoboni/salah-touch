<div align="center">

# Prayer Time for Pock

**Official UAE prayer times, iqama countdowns, and night calculations on the MacBook Touch Bar.**

[![macOS 10.15+](https://img.shields.io/badge/macOS-10.15%2B-111111?logo=apple&logoColor=white)](https://support.apple.com/macos)
[![Swift 5.5+](https://img.shields.io/badge/Swift-5.5%2B-F05138?logo=swift&logoColor=white)](https://www.swift.org/)
[![Pock Widget](https://img.shields.io/badge/Pock-widget-2F80ED)](https://pock.app/)
[![UAE Awqaf](https://img.shields.io/badge/timings-UAE%20Awqaf-00843D)](https://www.awqaf.gov.ae/prayer-times?lang=en)
[![MIT License](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

![Prayer Time for Pock overview](docs/overview.png)

</div>

Prayer Time for Pock keeps the next salah visible without opening an app. It uses your Mac's location to select the nearest official UAE Awqaf area, refreshes every six hours, and keeps a cached schedule available between network requests.

## Highlights

| | |
|---|---|
| **Official UAE timings** | Loads prayer schedules from the UAE General Authority of Islamic Affairs and Endowments. |
| **Native Touch Bar interaction** | Tap to expand the full schedule; tap anywhere to return with the native reverse animation. |
| **Arabic and English** | Localized labels with a consistent 12-hour clock and English digits. |
| **Automatic or manual location** | Uses CoreLocation, with latitude and longitude controls available in Pock settings. |
| **Iqama countdown** | Defaults to 20 minutes after each prayer and 5 minutes after Maghrib. |
| **Night calculations** | Shows Islamic midnight and the beginning of the last third of the night. |

## Touch Bar States

### Full schedule

The expanded view shows all five prayers, the calculated night times, your location, and a gray highlight on the upcoming prayer.

![Expanded Arabic prayer schedule showing Dubai](docs/expanded-schedule.png)

### Compact states

| Next prayer | Iqama countdown | Final five minutes |
|:---:|:---:|:---:|
| <img src="docs/next-prayer.png" alt="Next prayer displayed in Arabic" width="264"> | <img src="docs/iqama-countdown.png" alt="Iqama countdown" width="264"> | <img src="docs/critical-iqama.png" alt="Critical red iqama countdown" width="264"> |

## Install

### Download

1. Download `PrayerTimeWidget.pock` from the [latest release](https://github.com/GhalebAldoboni/pock-prayer-time-widget/releases/latest).
2. Quit Pock.
3. Double-click the widget, or place it in:

   ```text
   ~/Library/Application Support/Pock/Widgets/PrayerTimeWidget.pock
   ```

4. Start Pock and add **وقت الصلاة / Prayer Time** from the widget manager.
5. Allow location access when macOS asks, or select manual coordinates in the widget settings.

### Build from source

```bash
git clone https://github.com/GhalebAldoboni/pock-prayer-time-widget.git
cd pock-prayer-time-widget
./build-widget.sh
```

The signed development bundle is created at `build/PrayerTimeWidget.pock`.

## Configuration

Open Pock's widget manager and select **وقت الصلاة / Prayer Time**.

| Setting | Options |
|---|---|
| Language | Arabic or English |
| Location | Device location or manual coordinates |
| Coordinates | Latitude from -90 to 90; longitude from -180 to 180 |
| Default iqama | 0 to 120 minutes; default 20 |
| Maghrib iqama | 0 to 120 minutes; default 5 |

The widget displays times in 12-hour format, caches location and schedule data locally, and requests a fresh schedule every six hours.

## Night Calculation

The Islamic night is measured from Maghrib to the following Fajr. Its length changes throughout the year, so the widget calculates both values from each day's official schedule:

```text
Islamic midnight = Maghrib + (night duration / 2)
Last third starts = Maghrib + (night duration × 2 / 3)
```

For a night from `7:00 PM` to `4:00 AM`, Islamic midnight is `11:30 PM` and the last third starts at `1:00 AM`.

## Data Source

Prayer schedules come from the [official UAE Awqaf prayer-time service](https://www.awqaf.gov.ae/prayer-times?lang=en). The widget follows the public Awqaf web flow:

1. Request a short-lived client token.
2. Map the selected coordinates to the nearest official UAE area.
3. Load the prayer schedule for yesterday, today, and tomorrow.

The three-day window ensures the previous Maghrib and following Fajr are available for calculations around midnight.

## Privacy

- No analytics or advertising SDKs.
- No account is required.
- Automatic mode sends approximate coordinates to Awqaf only to select an official prayer-time area.
- Manual coordinates can be used instead of granting macOS location access.
- Cached schedules and settings remain in Pock's local preferences.

## Development

Requirements: macOS 10.15 or later, a Touch Bar-equipped MacBook Pro, Pock, and the Swift toolchain.

```bash
# Build and run the calculation tests
swift test

# Package and ad-hoc sign the widget
./build-widget.sh

# Regenerate README screenshots
swift scripts/render-screenshots.swift
```

The calculation suite covers variable-length nights, midnight, the last third, and invalid schedule boundaries.

## License

Released under the [MIT License](LICENSE).
