import AppKit
import PockKit

struct PrayerTouchBarEntry {
    let name: String
    let time: String
    let isUpcomingPrayer: Bool
    let isNightMarker: Bool
}

final class ExpandedPrayerTouchBarController: PKTouchBarController {
    private static let contentIdentifier = NSTouchBarItem.Identifier("PrayerTimeWidget.expanded.content")
    private static let touchBarWidth: CGFloat = 1085

    private var entries: [PrayerTouchBarEntry] = []
    private var language = PrayerLanguage.arabic
    private var locationName = ""
    private var didNotifyClose = false
    private var isClosing = false
    private weak var scheduleView: NSView?
    private var closeFallback: DispatchWorkItem?
    var onClose: (() -> Void)?

    required init() {
        super.init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    convenience init(entries: [PrayerTouchBarEntry], language: PrayerLanguage, locationName: String) {
        self.init()
        self.entries = entries
        self.language = language
        self.locationName = locationName
    }

    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [Self.contentIdentifier]
        touchBar.principalItemIdentifier = Self.contentIdentifier

        return touchBar
    }

    func touchBar(
        _ touchBar: NSTouchBar,
        makeItemForIdentifier identifier: NSTouchBarItem.Identifier
    ) -> NSTouchBarItem? {
        switch identifier {
        case Self.contentIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = makeScheduleView()
            return item
        default:
            return nil
        }
    }

    override func dismiss() {
        closeFallback?.cancel()
        closeFallback = nil
        super.dismiss()
        notifyClosed()
    }

    override func minimize() {
        beginClose()
    }

    private func beginClose() {
        guard isVisible, isClosing == false else {
            return
        }
        isClosing = true

        let fallback = DispatchWorkItem { [weak self] in
            self?.finishClose()
        }
        closeFallback = fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24, execute: fallback)

        guard let layer = scheduleView?.layer else {
            finishClose()
            return
        }

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.18)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        CATransaction.setCompletionBlock { [weak self] in
            self?.finishClose()
        }
        let scale = CABasicAnimation(keyPath: "transform.scale.x")
        scale.fromValue = 1
        scale.toValue = 0.04
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0
        let collapse = CAAnimationGroup()
        collapse.animations = [scale, fade]
        collapse.duration = 0.18
        collapse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.opacity = 0
        layer.transform = CATransform3DMakeScale(0.04, 1, 1)
        layer.add(collapse, forKey: "PrayerTimeWidget.close")
        CATransaction.commit()
    }

    private func finishClose() {
        guard didNotifyClose == false else {
            return
        }
        closeFallback?.cancel()
        closeFallback = nil
        super.dismiss()
        notifyClosed()
    }

    private func notifyClosed() {
        guard didNotifyClose == false else {
            return
        }
        didNotifyClose = true
        onClose?()
    }

    private func makeScheduleView() -> NSView {
        let orderedEntries = language.isRightToLeft ? Array(entries.reversed()) : entries
        let entryViews = orderedEntries.map(makeEntryView)
        let stack = NSStackView(views: entryViews)
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.distribution = .fill
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.wantsLayer = true
        container.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scheduleView = container
        let closeButton = makeCloseButton()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        let locationLabel = makeLocationLabel()
        let dismissButton = makeDismissSurfaceButton()
        container.addSubview(stack)
        container.addSubview(closeButton)
        container.addSubview(locationLabel)
        container.addSubview(dismissButton)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: Self.touchBarWidth),
            container.heightAnchor.constraint(equalToConstant: 30),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            closeButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            closeButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            locationLabel.leadingAnchor.constraint(equalTo: stack.trailingAnchor, constant: 8),
            locationLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            locationLabel.widthAnchor.constraint(equalToConstant: 125),
            locationLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -8),

            dismissButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            dismissButton.topAnchor.constraint(equalTo: container.topAnchor),
            dismissButton.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func makeEntryView(_ entry: PrayerTouchBarEntry) -> NSView {
        let nameLabel = NSTextField(labelWithString: entry.name)
        nameLabel.font = NSFont.systemFont(ofSize: entry.isNightMarker ? 9 : 10, weight: .medium)
        nameLabel.textColor = entry.isNightMarker ? .secondaryLabelColor : .white
        nameLabel.alignment = .center
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.maximumNumberOfLines = 1

        let timeLabel = NSTextField(labelWithString: entry.time)
        timeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold)
        timeLabel.textColor = .white
        timeLabel.alignment = .center

        let stack = NSStackView(views: [nameLabel, timeLabel])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.distribution = .fill
        stack.spacing = -2
        stack.edgeInsets = NSEdgeInsets(top: 1, left: 6, bottom: 1, right: 6)
        stack.wantsLayer = true
        stack.layer?.cornerRadius = 5
        stack.layer?.backgroundColor = entry.isUpcomingPrayer
            ? NSColor.gray.withAlphaComponent(0.55).cgColor
            : NSColor.clear.cgColor

        let width: CGFloat = entry.isNightMarker ? 134 : 70
        NSLayoutConstraint.activate([
            stack.widthAnchor.constraint(equalToConstant: width),
            stack.heightAnchor.constraint(equalToConstant: 30)
        ])
        return stack
    }

    private func makeCloseButton() -> NSButton {
        let button = NSButton(title: "×", target: self, action: #selector(close))
        button.isBordered = true
        button.bezelStyle = .texturedRounded
        button.font = NSFont.systemFont(ofSize: 17, weight: .medium)
        button.contentTintColor = .white
        button.toolTip = language.isRightToLeft ? "إغلاق" : "Close"
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 38),
            button.heightAnchor.constraint(equalToConstant: 30)
        ])
        return button
    }

    private func makeLocationLabel() -> NSTextField {
        let label = NSTextField(labelWithString: locationName)
        label.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        label.textColor = NSColor.white.withAlphaComponent(0.75)
        label.alignment = language.isRightToLeft ? .right : .left
        label.baseWritingDirection = language.isRightToLeft ? .rightToLeft : .leftToRight
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func makeDismissSurfaceButton() -> NSButton {
        let button = NSButton(title: "", target: self, action: #selector(close))
        button.isBordered = false
        button.focusRingType = .none
        button.setAccessibilityLabel(
            language.isRightToLeft ? "إغلاق مواقيت الصلاة" : "Close prayer times"
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    @objc private func close() {
        beginClose()
    }
}
