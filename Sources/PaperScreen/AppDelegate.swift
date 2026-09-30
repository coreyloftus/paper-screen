import AppKit
import Carbon.HIToolbox

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = Settings.shared
    private let overlay = OverlayController()
    private var statusItem: NSStatusItem!
    private var toggleItem: NSMenuItem!
    private var textureItems: [PaperTexture: NSMenuItem] = [:]
    private var intensitySlider: NSSlider!
    private var warmthSlider: NSSlider!
    private var veilSlider: NSSlider!
    private var veilLabel: NSTextField!
    private var intensityLabel: NSTextField!
    private var warmthLabel: NSTextField!
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.menu = buildMenu()

        hotKey = HotKey(keyCode: kVK_ANSI_P, modifiers: controlKey | optionKey) { [weak self] in
            self?.toggle()
        }
        if hotKey == nil {
            FileHandle.standardError.write(Data("PaperScreen: hotkey Ctrl+Opt+P is taken by another app\n".utf8))
        }

        settings.onChange = { [weak self] in self?.settingsChanged() }
        settingsChanged()
    }

    private func toggle() { settings.enabled.toggle() }

    private func settingsChanged() {
        overlay.refresh()
        toggleItem.state = settings.enabled ? .on : .off
        toggleItem.title = settings.enabled ? "Paper Overlay On" : "Paper Overlay Off"
        for (texture, item) in textureItems { item.state = texture == settings.texture ? .on : .off }
        intensitySlider.doubleValue = settings.intensity
        warmthSlider.doubleValue = settings.warmth
        veilSlider.doubleValue = settings.veil
        intensityLabel.stringValue = "Grain  \(Int((settings.intensity * 100).rounded()))%"
        veilLabel.stringValue = "Veil  \(Int((settings.veil * 100).rounded()))%"
        warmthLabel.stringValue = "Warmth  \(Int((settings.warmth * 100).rounded()))%"
        let symbol = settings.enabled ? "doc.text.fill" : "doc.text"
        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Paper overlay")
    }

    // MARK: - Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        toggleItem = NSMenuItem(title: "", action: #selector(toggleFromMenu), keyEquivalent: "p")
        toggleItem.keyEquivalentModifierMask = [.control, .option]
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        intensitySlider = NSSlider(value: settings.intensity, minValue: 0, maxValue: 1,
                                   target: self, action: #selector(intensityChanged(_:)))
        intensityLabel = NSTextField(labelWithString: "")
        menu.addItem(sliderItem(label: intensityLabel, slider: intensitySlider))

        veilSlider = NSSlider(value: settings.veil, minValue: 0, maxValue: 1,
                              target: self, action: #selector(veilChanged(_:)))
        veilLabel = NSTextField(labelWithString: "")
        menu.addItem(sliderItem(label: veilLabel, slider: veilSlider))

        warmthSlider = NSSlider(value: settings.warmth, minValue: 0, maxValue: 1,
                                target: self, action: #selector(warmthChanged(_:)))
        warmthLabel = NSTextField(labelWithString: "")
        menu.addItem(sliderItem(label: warmthLabel, slider: warmthSlider))
        menu.addItem(.separator())

        let header = NSMenuItem(title: "Texture", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        for texture in PaperTexture.allCases {
            let item = NSMenuItem(title: texture.title, action: #selector(textureChosen(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = texture.rawValue
            textureItems[texture] = item
            menu.addItem(item)
        }
        menu.addItem(.separator())

        menu.addItem(withTitle: "Quit PaperScreen", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return menu
    }

    private func sliderItem(label: NSTextField, slider: NSSlider) -> NSMenuItem {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 44))
        label.font = .menuFont(ofSize: 12)
        label.frame = NSRect(x: 14, y: 24, width: 200, height: 16)
        slider.frame = NSRect(x: 14, y: 4, width: 212, height: 20)
        view.addSubview(label)
        view.addSubview(slider)
        let item = NSMenuItem()
        item.view = view
        return item
    }

    @objc private func toggleFromMenu() { toggle() }
    @objc private func intensityChanged(_ sender: NSSlider) { settings.intensity = sender.doubleValue }
    @objc private func veilChanged(_ sender: NSSlider) { settings.veil = sender.doubleValue }
    @objc private func warmthChanged(_ sender: NSSlider) { settings.warmth = sender.doubleValue }

    @objc private func textureChosen(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let texture = PaperTexture(rawValue: raw) else { return }
        settings.texture = texture
    }
}
