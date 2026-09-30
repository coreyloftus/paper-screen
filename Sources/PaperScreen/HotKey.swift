import Carbon.HIToolbox

/// System-wide hotkey through Carbon. It needs no Accessibility or Input Monitoring permission.
final class HotKey {
    private static var action: (() -> Void)?
    private var ref: EventHotKeyRef?

    /// Returns nil when another app already owns the key combination.
    init?(keyCode: Int, modifiers: Int, action: @escaping () -> Void) {
        HotKey.action = action
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            HotKey.action?()
            return noErr
        }, 1, &spec, nil, nil)
        let id = EventHotKeyID(signature: OSType(0x5053_4352), id: 1)
        let status = RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), id, GetApplicationEventTarget(), 0, &ref)
        if status != noErr { return nil }
    }
}
