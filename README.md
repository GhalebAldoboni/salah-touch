# Pock Prayer Time Widget

Prayer Time Widget is a Touch Bar widget for [Pock](https://pock.app/) that shows the next Muslim prayer time, supports Arabic and English labels, and includes an iqama countdown with a red full-width warning state.

It uses the official UAE Awqaf prayer time service and can select the nearest official UAE area from either your Mac location or manually entered coordinates.

## Features

- Next prayer time directly on the MacBook Touch Bar
- Arabic and English display modes
- 12-hour time format with English digits
- Automatic device location with CoreLocation
- Manual latitude and longitude override for UAE areas
- Official UAE Awqaf prayer time source
- Iqama countdown after each prayer
- Default iqama duration: 20 minutes
- Maghrib iqama duration: 5 minutes
- Red full-box countdown when iqama is 5 minutes or less
- Calculated Islamic midnight and last third of the night
- Tap the widget for an animated full Touch Bar prayer schedule
- Current city or coordinates in the expanded schedule
- Gray highlight on the upcoming prayer in the expanded schedule
- Tap anywhere in the expanded schedule to close it with the native reverse animation
- Cached location and prayer schedule for faster startup
- Refreshes prayer times every 6 hours

## Screenshots

Add screenshots to `docs/` after installing the widget:

- Next prayer: `العصر 3:41 PM`
- Iqama countdown: `الإقامة: 19:00`
- Critical iqama warning: red `04:00` full-width countdown

## Requirements

- macOS 10.15 or later
- Pock installed
- Xcode command line tools or Swift toolchain
- Internet connection for Awqaf prayer time requests
- Location permission for automatic location mode

## Install

Download `PrayerTimeWidget.pock` from the latest GitHub release, then double-click it or copy it to:

```bash
~/Library/Application Support/Pock/Widgets/PrayerTimeWidget.pock
```

Restart Pock after installing the widget.

## Build From Source

```bash
git clone https://github.com/GhalebAldoboni/pock-prayer-time-widget.git
cd pock-prayer-time-widget
./build-widget.sh
```

The packaged widget will be created at:

```bash
build/PrayerTimeWidget.pock
```

If you clone this repository by itself, you can also build the Swift package directly:

```bash
swift build
```

## Configure In Pock

Open Pock's widget manager and select `وقت الصلاة` / `Prayer Time`.

Available settings:

- Language: Arabic or English
- Location: device location or manual coordinates
- Latitude and longitude for manual mode
- Default iqama minutes
- Maghrib iqama minutes

Changes are saved to Pock preferences and the widget refreshes after saving.

## Night Times

The widget calculates the night from Maghrib to the following Fajr:

- Islamic midnight: Maghrib plus one half of the night duration
- Last third start: Maghrib plus two thirds of the night duration

These values adjust automatically as the length of the night changes. Tap the Touch Bar widget to see both values alongside all five prayer times.

## Prayer Time Source

This widget uses the official UAE Awqaf prayer time service:

```text
https://www.awqaf.gov.ae/prayer-times?lang=en
```

Internally, the widget follows the same public Awqaf web flow: it requests a short-lived client token, maps coordinates to the nearest official UAE city/area, then loads the official prayer time schedule for that area.

## Privacy

The widget does not collect analytics. In automatic mode, your approximate latitude and longitude are sent to Awqaf only to find the nearest official UAE prayer time area.

Use manual coordinates if you do not want the widget to request macOS location permission.

## SEO Keywords

Pock prayer time widget, MacBook Touch Bar prayer times, UAE prayer times macOS, Awqaf prayer times widget, Muslim prayer Touch Bar, iqama countdown widget, Arabic prayer time widget for Mac.

## Development

The widget is written in Swift with AppKit and PockKit.

Useful commands:

```bash
swift build
./build-widget.sh
```

Do not commit local build output:

- `.build/`
- `build/`
- `*.pock/`

## License

MIT
