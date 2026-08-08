// 生成 App 图标 PNG（1024x1024）。由 build.sh 调用。
//
// 符号是 Lucide 的 arrow-up-from-line（箭头 + 底部横线，全描边）。
// 同一套几何也用在菜单栏图标上，改这里请同步 Sources/Dropline/TrayIcon.swift。
import AppKit

let size = 1024.0
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let rect = NSRect(x: 0, y: 0, width: size, height: size)
let inset = rect.insetBy(dx: size * 0.09, dy: size * 0.09)
let path = NSBezierPath(roundedRect: inset, xRadius: size * 0.22, yRadius: size * 0.22)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.30, green: 0.55, blue: 1.00, alpha: 1),
    NSColor(calibratedRed: 0.11, green: 0.28, blue: 0.85, alpha: 1),
])!
gradient.draw(in: path, angle: -90)

/// Lucide arrow-up-from-line，原始 viewBox 24×24、stroke-width 2、圆头圆角：
///     m18 9-6-6-6 6 / M12 3v14 / M5 21h14
/// SVG 的 y 轴朝下，这里换算成 AppKit 的 y 轴朝上（y' = 24 - y）：
///     箭头 (6,15)→(12,21)→(18,15)   竖杆 (12,21)→(12,7)   底线 (5,3)→(19,3)
/// 含描边后的包围盒：带底线 x∈[4,20] y∈[2,22]；不带底线 x∈[5,19] y∈[6,22]。
func drawUploadGlyph(centeredIn box: NSRect, height: CGFloat, baseline: Bool) {
    let unitH: CGFloat = baseline ? 20 : 16
    let unitCenterY: CGFloat = baseline ? 12 : 14      // 包围盒中心在 24 单位坐标里的 y
    let s = height / unitH
    func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
        NSPoint(x: box.midX + (x - 12) * s, y: box.midY + (y - unitCenterY) * s)
    }

    let lineWidth = 2 * s
    func stroke(_ make: (NSBezierPath) -> Void) {
        let path = NSBezierPath()
        make(path)
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }

    // 竖杆先画，箭头压在上面，接缝被圆角盖住
    stroke { $0.move(to: p(12, 21)); $0.line(to: p(12, 7)) }
    stroke { $0.move(to: p(6, 15)); $0.line(to: p(12, 21)); $0.line(to: p(18, 15)) }
    if baseline {
        stroke { $0.move(to: p(5, 3)); $0.line(to: p(19, 3)) }
    }
}

NSColor.white.setStroke()
drawUploadGlyph(centeredIn: rect, height: size * 0.44, baseline: true)

NSGraphicsContext.restoreGraphicsState()

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
