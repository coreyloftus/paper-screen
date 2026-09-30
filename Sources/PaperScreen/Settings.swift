import Foundation

enum PaperTexture: String, CaseIterable {
    case softGrain, woven, blotter, coldTooth

    var title: String {
        switch self {
        case .softGrain: return "Soft Grain"
        case .woven: return "Woven"
        case .blotter: return "Blotter"
        case .coldTooth: return "Cold Tooth"
        }
    }
}

/// User settings, persisted in UserDefaults. `intensity` is a 0...1 slider position. Launch args like `-enabled YES` override stored values.
final class Settings {
    static let shared = Settings()

    var onChange: (() -> Void)?

    private let defaults = UserDefaults.standard

    var enabled: Bool { didSet { save() } }
    var intensity: Double { didSet { save() } }
    var warmth: Double { didSet { save() } }
    var texture: PaperTexture { didSet { save() } }

    private init() {
        defaults.register(defaults: [
            "enabled": true,
            "intensity": 0.35,
            "warmth": 0.35,
            "texture": PaperTexture.softGrain.rawValue,
        ])
        enabled = defaults.bool(forKey: "enabled")
        intensity = min(max(defaults.double(forKey: "intensity"), 0), 1)
        warmth = min(max(defaults.double(forKey: "warmth"), 0), 1)
        texture = PaperTexture(rawValue: defaults.string(forKey: "texture") ?? "") ?? .softGrain
    }

    private func save() {
        defaults.set(enabled, forKey: "enabled")
        defaults.set(intensity, forKey: "intensity")
        defaults.set(warmth, forKey: "warmth")
        defaults.set(texture.rawValue, forKey: "texture")
        onChange?()
    }
}
