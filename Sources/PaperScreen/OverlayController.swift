import AppKit

/// Borderless window that never takes focus and lets every click and key pass through.
private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class OverlayView: NSView {
    var veil = NSColor.clear { didSet { needsDisplay = true } }
    var tile: NSImage? { didSet { needsDisplay = true } }
    var grainOpacity: CGFloat = 1 { didSet { needsDisplay = true } }

    override var isOpaque: Bool { false }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        veil.setFill()
        dirtyRect.fill(using: .sourceOver)
        if let tile, let context = NSGraphicsContext.current?.cgContext {
            context.saveGState()
            context.setAlpha(grainOpacity)
            NSColor(patternImage: tile).setFill()
            dirtyRect.fill(using: .sourceOver)
            context.restoreGState()
        }
    }
}

/// Keeps one overlay window per display in sync with the settings.
final class OverlayController {
    private var windows: [CGDirectDisplayID: OverlayWindow] = [:]
    private var tileCache: [PaperTexture: CGImage] = [:]
    private let settings = Settings.shared

    /// The system screenshot tool treats our full-screen window as the window to capture, so we hide while it runs.
    private static let screenshotToolID = "com.apple.screencaptureui"
    private var screenshotToolRunning = false

    init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(self, selector: #selector(appsChanged(_:)), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        workspace.addObserver(self, selector: #selector(appsChanged(_:)), name: NSWorkspace.didTerminateApplicationNotification, object: nil)
        screenshotToolRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: Self.screenshotToolID).isEmpty
    }

    @objc private func screensChanged() { refresh() }

    @objc private func appsChanged(_ note: Notification) {
        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        guard app?.bundleIdentifier == Self.screenshotToolID else { return }
        screenshotToolRunning = note.name == NSWorkspace.didLaunchApplicationNotification
        refresh()
    }

    func refresh() {
        guard settings.enabled, !screenshotToolRunning else {
            windows.values.forEach { $0.orderOut(nil) }
            return
        }
        let screens = NSScreen.screens
        let live = Set(screens.compactMap(Self.displayID))
        for id in windows.keys where !live.contains(id) {
            windows[id]?.orderOut(nil)
            windows[id] = nil
        }
        for screen in screens {
            guard let id = Self.displayID(screen) else { continue }
            let window = windows[id] ?? makeWindow()
            windows[id] = window
            window.setFrame(screen.frame, display: false)
            apply(to: window, scale: screen.backingScaleFactor)
            window.orderFrontRegardless()
        }
    }

    private func makeWindow() -> OverlayWindow {
        let window = OverlayWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.contentView = OverlayView()
        return window
    }

    private func apply(to window: OverlayWindow, scale: CGFloat) {
        guard let view = window.contentView as? OverlayView else { return }
        let cg = tileCache[settings.texture] ?? {
            let made = TextureGenerator.tile(for: settings.texture)
            tileCache[settings.texture] = made
            return made
        }()
        // one texture pixel per screen pixel, so Retina displays get the same grain size
        let points = CGFloat(cg.width) / scale
        view.tile = NSImage(cgImage: cg, size: NSSize(width: points, height: points))
        view.veil = Self.veilColor(warmth: settings.warmth, level: settings.veil)
        view.grainOpacity = Self.grainOpacity(forIntensity: settings.intensity)
    }

    /// Grain opacity 2%...50%. The curve is quadratic, so the low end gets finer steps.
    static func grainOpacity(forIntensity intensity: Double) -> CGFloat {
        CGFloat(0.02 + 0.48 * intensity * intensity)
    }

    /// A mid-tone veil flattens contrast without lifting overall brightness: bright areas dim, dark areas lift.
    /// Grey at warmth 0, amber-brown at warmth 1. Veil opacity is 0...50%.
    static func veilColor(warmth: Double, level: Double) -> NSColor {
        let w = CGFloat(warmth)
        return NSColor(
            srgbRed: 0.55 + (0.65 - 0.55) * w,
            green: 0.55 + (0.50 - 0.55) * w,
            blue: 0.55 + (0.32 - 0.55) * w,
            alpha: CGFloat(0.5 * level))
    }

    private static func displayID(_ screen: NSScreen) -> CGDirectDisplayID? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
