import CoreGraphics
import Foundation

/// Builds seamless RGBA paper tiles from seeded noise. Nothing is loaded from disk.
enum TextureGenerator {
    static let tileSize = 256

    private struct SplitMix64: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }

    /// Grey field in roughly -1...1. Positive pixels draw light specks, negative draw dark ones.
    private typealias Field = [Float]

    static func tile(for texture: PaperTexture) -> CGImage {
        let n = tileSize
        var rng = SplitMix64(state: 0x5041_5045_52 &+ UInt64(PaperTexture.allCases.firstIndex(of: texture)!))
        let field: Field
        let strength: Float
        switch texture {
        case .softGrain:
            field = softGrain(n, &rng); strength = 0.35
        case .woven:
            field = woven(n, &rng); strength = 0.4
        case .blotter:
            field = blotter(n, &rng); strength = 0.4
        case .coldTooth:
            field = coldTooth(n, &rng); strength = 0.2
        }
        return image(from: field, n: n, strength: strength)
    }

    // MARK: - Textures

    private static func softGrain(_ n: Int, _ rng: inout SplitMix64) -> Field {
        var f = whiteNoise(n, &rng)
        f = blur(f, n)
        f = f.map { $0 * 2.2 }
        // sparse paper fibres: short random strokes
        for _ in 0..<260 {
            let x0 = Float.random(in: 0..<Float(n), using: &rng)
            let y0 = Float.random(in: 0..<Float(n), using: &rng)
            let angle = Float.random(in: 0..<(2 * .pi), using: &rng)
            let len = Float.random(in: 4...12, using: &rng)
            let sign: Float = Bool.random(using: &rng) ? 0.7 : -0.7
            for s in 0..<Int(len) {
                let x = (Int(x0 + cos(angle) * Float(s)) % n + n) % n
                let y = (Int(y0 + sin(angle) * Float(s)) % n + n) % n
                f[y * n + x] += sign * 0.5
            }
        }
        return clamp(f)
    }

    private static func woven(_ n: Int, _ rng: inout SplitMix64) -> Field {
        let pitch = 4
        let threads = n / pitch
        // per-thread brightness variation, so the weave looks hand-made
        let warp = (0..<threads).map { _ in Float.random(in: -0.35...0.35, using: &rng) }
        let weft = (0..<threads).map { _ in Float.random(in: -0.35...0.35, using: &rng) }
        let slub = periodicNoise(n, cells: 8, &rng)
        var f = Field(repeating: 0, count: n * n)
        for y in 0..<n {
            for x in 0..<n {
                let cx = x / pitch, cy = y / pitch
                let over = (cx + cy) % 2 == 0
                // rounded thread profile across its width
                let px = Float(x % pitch) + 0.5 - Float(pitch) / 2
                let py = Float(y % pitch) + 0.5 - Float(pitch) / 2
                let profile: Float
                let base: Float
                if over {
                    profile = 1 - abs(px) / (Float(pitch) / 2)
                    base = warp[cx]
                } else {
                    profile = 1 - abs(py) / (Float(pitch) / 2)
                    base = weft[cy]
                }
                f[y * n + x] = (profile - 0.5) * 1.1 + base + slub[y * n + x] * 0.4
            }
        }
        let grain = whiteNoise(n, &rng)
        for i in 0..<f.count { f[i] += grain[i] * 0.25 }
        return clamp(f)
    }

    private static func blotter(_ n: Int, _ rng: inout SplitMix64) -> Field {
        let coarse = periodicNoise(n, cells: 4, &rng)
        let mid = periodicNoise(n, cells: 16, &rng)
        let fine = periodicNoise(n, cells: 64, &rng)
        let grain = blur(whiteNoise(n, &rng), n)
        var f = Field(repeating: 0, count: n * n)
        for i in 0..<f.count {
            f[i] = coarse[i] * 0.7 + mid[i] * 0.55 + fine[i] * 0.4 + grain[i] * 1.2
        }
        // scattered dark flecks
        for _ in 0..<70 {
            let x = Int.random(in: 0..<n, using: &rng)
            let y = Int.random(in: 0..<n, using: &rng)
            f[y * n + x] -= 1.0
            f[y * n + (x + 1) % n] -= 0.5
        }
        return clamp(f)
    }

    private static func coldTooth(_ n: Int, _ rng: inout SplitMix64) -> Field {
        // height field from blurred noise, lit from the top-left with an emboss kernel
        var height = periodicNoise(n, cells: 48, &rng)
        let extra = blur(blur(whiteNoise(n, &rng), n), n)
        for i in 0..<height.count { height[i] += extra[i] * 2.0 }
        var f = Field(repeating: 0, count: n * n)
        for y in 0..<n {
            for x in 0..<n {
                let a = height[((y + 1) % n) * n + (x + 1) % n]
                let b = height[((y - 1 + n) % n) * n + (x - 1 + n) % n]
                f[y * n + x] = (b - a) * 2.6
            }
        }
        return clamp(f)
    }

    // MARK: - Noise helpers

    private static func whiteNoise(_ n: Int, _ rng: inout SplitMix64) -> Field {
        (0..<(n * n)).map { _ in Float.random(in: -1...1, using: &rng) }
    }

    /// 3x3 box blur that wraps around the edges, so tiles stay seamless.
    private static func blur(_ f: Field, _ n: Int) -> Field {
        var out = Field(repeating: 0, count: n * n)
        for y in 0..<n {
            for x in 0..<n {
                var sum: Float = 0
                for dy in -1...1 {
                    for dx in -1...1 {
                        sum += f[((y + dy + n) % n) * n + (x + dx + n) % n]
                    }
                }
                out[y * n + x] = sum / 9
            }
        }
        return out
    }

    /// Smooth value noise on a wrapping lattice of `cells` x `cells`.
    private static func periodicNoise(_ n: Int, cells: Int, _ rng: inout SplitMix64) -> Field {
        let lattice = (0..<(cells * cells)).map { _ in Float.random(in: -1...1, using: &rng) }
        let cell = Float(n) / Float(cells)
        func smooth(_ t: Float) -> Float { t * t * (3 - 2 * t) }
        var out = Field(repeating: 0, count: n * n)
        for y in 0..<n {
            let fy = Float(y) / cell
            let y0 = Int(fy) % cells, y1 = (y0 + 1) % cells
            let ty = smooth(fy - floor(fy))
            for x in 0..<n {
                let fx = Float(x) / cell
                let x0 = Int(fx) % cells, x1 = (x0 + 1) % cells
                let tx = smooth(fx - floor(fx))
                let top = lattice[y0 * cells + x0] * (1 - tx) + lattice[y0 * cells + x1] * tx
                let bottom = lattice[y1 * cells + x0] * (1 - tx) + lattice[y1 * cells + x1] * tx
                out[y * n + x] = top * (1 - ty) + bottom * ty
            }
        }
        return out
    }

    private static func clamp(_ f: Field) -> Field {
        f.map { min(max($0, -1), 1) }
    }

    // MARK: - Image

    private static func image(from field: Field, n: Int, strength: Float) -> CGImage {
        var bytes = [UInt8](repeating: 0, count: n * n * 4)
        for i in 0..<(n * n) {
            let v = field[i]
            let alpha = abs(v) * strength
            // light specks are near-white, dark specks are a warm dark brown
            let (r, g, b): (Float, Float, Float) = v >= 0 ? (1, 1, 0.98) : (0.22, 0.17, 0.12)
            bytes[i * 4 + 0] = UInt8(r * alpha * 255)
            bytes[i * 4 + 1] = UInt8(g * alpha * 255)
            bytes[i * 4 + 2] = UInt8(b * alpha * 255)
            bytes[i * 4 + 3] = UInt8(alpha * 255)
        }
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        return CGImage(
            width: n, height: n, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: n * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )!
    }
}
