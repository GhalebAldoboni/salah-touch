#!/usr/bin/env swift

import AppKit

private enum Palette {
    static let black = NSColor(calibratedWhite: 0.015, alpha: 1)
    static let canvas = NSColor(calibratedRed: 0.055, green: 0.06, blue: 0.07, alpha: 1)
    static let panel = NSColor(calibratedRed: 0.09, green: 0.095, blue: 0.105, alpha: 1)
    static let white = NSColor.white
    static let secondary = NSColor(calibratedWhite: 0.72, alpha: 1)
    static let highlight = NSColor(calibratedWhite: 0.38, alpha: 0.82)
    static let red = NSColor.systemRed
}

private struct PrayerPreviewEntry {
    let name: String
    let time: String
    let width: CGFloat
    let highlighted: Bool
    let secondary: Bool
}

private final class DrawingView: NSView {
    let drawing: (NSRect) -> Void

    init(size: NSSize, drawing: @escaping (NSRect) -> Void) {
        self.drawing = drawing
        super.init(frame: NSRect(origin: .zero, size: size))
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        drawing(bounds)
    }
}

private func drawText(
    _ text: String,
    in rect: NSRect,
    font: NSFont,
    color: NSColor = Palette.white,
    alignment: NSTextAlignment = .center
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byTruncatingTail
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    NSAttributedString(string: text, attributes: attributes).draw(in: rect)
}

private func fillRounded(_ rect: NSRect, color: NSColor, radius: CGFloat) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

private func collapsedView(state: String) -> NSView {
    return DrawingView(size: NSSize(width: 132, height: 30)) { bounds in
        fillRounded(bounds, color: Palette.black, radius: 5)

        switch state {
        case "iqama":
            drawText("الإقامة:", in: NSRect(x: 8, y: 4, width: 56, height: 16), font: .systemFont(ofSize: 12, weight: .medium), alignment: .right)
            drawText("14:32", in: NSRect(x: 68, y: 4, width: 56, height: 16), font: .monospacedDigitSystemFont(ofSize: 12, weight: .semibold), alignment: .left)
        case "critical":
            drawText("04:32", in: NSRect(x: 0, y: 3, width: 132, height: 25), font: .monospacedDigitSystemFont(ofSize: 20, weight: .bold), color: Palette.red)
        default:
            drawText("العصر", in: NSRect(x: 8, y: 2, width: 48, height: 15), font: .systemFont(ofSize: 12, weight: .medium), alignment: .right)
            drawText("3:23 PM", in: NSRect(x: 62, y: 2, width: 62, height: 15), font: .monospacedDigitSystemFont(ofSize: 12, weight: .semibold), alignment: .left)
            drawText("بعد 1س 17د", in: NSRect(x: 8, y: 16, width: 116, height: 11), font: .systemFont(ofSize: 8), alignment: .right)
        }
    }
}

private func expandedView() -> NSView {
    let entries = [
        PrayerPreviewEntry(name: "الثلث الأخير من الليل", time: "1:18 AM", width: 134, highlighted: false, secondary: true),
        PrayerPreviewEntry(name: "منتصف الليل", time: "11:27 PM", width: 134, highlighted: false, secondary: true),
        PrayerPreviewEntry(name: "العشاء", time: "7:07 PM", width: 70, highlighted: false, secondary: false),
        PrayerPreviewEntry(name: "المغرب", time: "5:53 PM", width: 70, highlighted: false, secondary: false),
        PrayerPreviewEntry(name: "العصر", time: "3:23 PM", width: 70, highlighted: true, secondary: false),
        PrayerPreviewEntry(name: "الظهر", time: "12:06 PM", width: 70, highlighted: false, secondary: false),
        PrayerPreviewEntry(name: "الفجر", time: "5:00 AM", width: 70, highlighted: false, secondary: false)
    ]

    return DrawingView(size: NSSize(width: 1085, height: 30)) { bounds in
        Palette.black.setFill()
        bounds.fill()

        fillRounded(NSRect(x: 4, y: 0, width: 38, height: 30), color: Palette.highlight, radius: 5)
        drawText("×", in: NSRect(x: 4, y: 2, width: 38, height: 25), font: .systemFont(ofSize: 17, weight: .medium))

        let totalWidth = entries.reduce(0) { $0 + $1.width } + CGFloat(entries.count - 1) * 5
        var x = (bounds.width - totalWidth) / 2
        for entry in entries {
            let rect = NSRect(x: x, y: 0, width: entry.width, height: 30)
            if entry.highlighted {
                fillRounded(rect, color: Palette.highlight, radius: 5)
            }
            drawText(
                entry.name,
                in: NSRect(x: x + 4, y: 2, width: entry.width - 8, height: 13),
                font: .systemFont(ofSize: entry.secondary ? 9 : 10, weight: .medium),
                color: entry.secondary ? Palette.secondary : Palette.white
            )
            drawText(
                entry.time,
                in: NSRect(x: x + 4, y: 15, width: entry.width - 8, height: 13),
                font: .monospacedDigitSystemFont(ofSize: 10, weight: .semibold)
            )
            x += entry.width + 5
        }

        drawText("دبي", in: NSRect(x: x + 3, y: 8, width: 125, height: 15), font: .systemFont(ofSize: 10, weight: .medium), color: NSColor.white.withAlphaComponent(0.75), alignment: .right)
    }
}

private func overviewView() -> NSView {
    let size = NSSize(width: 1400, height: 640)
    return DrawingView(size: size) { bounds in
        Palette.canvas.setFill()
        bounds.fill()

        drawText("SalahTouch", in: NSRect(x: 90, y: 530, width: 1220, height: 54), font: .systemFont(ofSize: 38, weight: .bold))
        drawText("Prayer times, at your fingertips", in: NSRect(x: 90, y: 498, width: 1220, height: 30), font: .systemFont(ofSize: 18, weight: .medium), color: Palette.secondary)

        fillRounded(NSRect(x: 88, y: 346, width: 1224, height: 104), color: Palette.panel, radius: 8)
        drawText("NEXT PRAYER", in: NSRect(x: 116, y: 406, width: 170, height: 20), font: .systemFont(ofSize: 12, weight: .semibold), color: Palette.secondary, alignment: .left)
        let collapsed = collapsedView(state: "next")
        NSGraphicsContext.saveGraphicsState()
        let collapsedTransform = NSAffineTransform()
        collapsedTransform.translateX(by: 304, yBy: 338)
        collapsedTransform.scale(by: 3)
        collapsedTransform.concat()
        collapsed.draw(collapsed.bounds)
        NSGraphicsContext.restoreGraphicsState()

        fillRounded(NSRect(x: 88, y: 164, width: 1224, height: 154), color: Palette.panel, radius: 8)
        drawText("EXPANDED SCHEDULE", in: NSRect(x: 116, y: 272, width: 210, height: 20), font: .systemFont(ofSize: 12, weight: .semibold), color: Palette.secondary, alignment: .left)

        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: 116, yBy: 219)
        transform.scale(by: 1.08)
        transform.concat()
        expandedView().draw(NSRect(x: 0, y: 0, width: 1085, height: 30))
        NSGraphicsContext.restoreGraphicsState()

        drawText("Arabic and English · 12-hour time · Iqama countdown · Last third of night", in: NSRect(x: 90, y: 90, width: 1220, height: 28), font: .systemFont(ofSize: 15, weight: .medium), color: Palette.secondary)
        drawText("Tap once to expand. Tap anywhere to return.", in: NSRect(x: 90, y: 54, width: 1220, height: 28), font: .systemFont(ofSize: 15, weight: .semibold))
    }
}

private func writePNG(_ view: NSView, to path: String, scale: CGFloat = 2) throws {
    view.layoutSubtreeIfNeeded()
    let width = Int(view.bounds.width * scale)
    let height = Int(view.bounds.height * scale)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "ScreenshotRenderer", code: 1)
    }

    bitmap.size = view.bounds.size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    view.draw(view.bounds)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "ScreenshotRenderer", code: 2)
    }
    try data.write(to: URL(fileURLWithPath: path), options: .atomic)
}

let fileManager = FileManager.default
let root = fileManager.currentDirectoryPath
let docs = root + "/docs"
try fileManager.createDirectory(atPath: docs, withIntermediateDirectories: true)

try writePNG(collapsedView(state: "next"), to: docs + "/next-prayer.png")
try writePNG(collapsedView(state: "iqama"), to: docs + "/iqama-countdown.png")
try writePNG(collapsedView(state: "critical"), to: docs + "/critical-iqama.png")
try writePNG(expandedView(), to: docs + "/expanded-schedule.png")
try writePNG(overviewView(), to: docs + "/overview.png", scale: 1)

print("Rendered screenshots in \(docs)")
