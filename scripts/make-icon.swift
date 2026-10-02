// Draws Resources/AppIcon.icns: a warm paper sheet on a rounded square.
import AppKit

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(px)
    let tile = NSRect(x: s * 0.06, y: s * 0.06, width: s * 0.88, height: s * 0.88)
    NSColor(red: 0.93, green: 0.88, blue: 0.78, alpha: 1).setFill()
    NSBezierPath(roundedRect: tile, xRadius: s * 0.2, yRadius: s * 0.2).fill()

    let page = NSRect(x: s * 0.28, y: s * 0.2, width: s * 0.44, height: s * 0.6)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(white: 0, alpha: 0.25)
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.015)
    shadow.shadowBlurRadius = s * 0.03
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSColor(red: 0.99, green: 0.97, blue: 0.92, alpha: 1).setFill()
    NSBezierPath(roundedRect: page, xRadius: s * 0.03, yRadius: s * 0.03).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSColor(red: 0.62, green: 0.55, blue: 0.45, alpha: 0.7).setFill()
    for i in 0..<4 {
        let y = page.maxY - s * 0.12 - CGFloat(i) * s * 0.095
        let w = page.width * (i == 3 ? 0.5 : 0.72)
        NSBezierPath(roundedRect: NSRect(x: page.minX + s * 0.05, y: y, width: w, height: s * 0.03),
                     xRadius: s * 0.015, yRadius: s * 0.015).fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let set = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: set, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try render(base).write(to: URL(fileURLWithPath: "\(set)/icon_\(base)x\(base).png"))
    try render(base * 2).write(to: URL(fileURLWithPath: "\(set)/icon_\(base)x\(base)@2x.png"))
}
