// 生成 DMG 背景图。由 tools/dmg.sh 调用：makedmgbg.swift <输出路径> <缩放倍数>
import AppKit

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dmg-bg.png"
let scale = CommandLine.arguments.count > 2 ? (Double(CommandLine.arguments[2]) ?? 1) : 1

let w = 540.0, h = 380.0
let pw = Int(w * scale), ph = Int(h * scale)

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pw, pixelsHigh: ph,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: w, height: h)   // 让 1x/2x 拥有相同的点尺寸

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// 背景渐变
let bg = NSGradient(colors: [
    NSColor(calibratedRed: 0.97, green: 0.98, blue: 1.00, alpha: 1),
    NSColor(calibratedRed: 0.91, green: 0.94, blue: 0.99, alpha: 1),
])!
bg.draw(in: NSRect(x: 0, y: 0, width: w, height: h), angle: -90)

// 标题
let title = "Dropline"
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 26, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.12, alpha: 1),
]
let ts = title.size(withAttributes: titleAttrs)
title.draw(at: NSPoint(x: (w - ts.width) / 2, y: h - 66), withAttributes: titleAttrs)

// 安装器面向所有用户，统一用英文（和 App 内「兜底英文」的取向一致）
let sub = "Drag Dropline to the Applications folder to install"
let subAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 12, weight: .regular),
    .foregroundColor: NSColor(calibratedWhite: 0.42, alpha: 1),
]
let ss = sub.size(withAttributes: subAttrs)
sub.draw(at: NSPoint(x: (w - ss.width) / 2, y: h - 92), withAttributes: subAttrs)

// 两个图标位置之间的箭头（图标中心在 y=180，DMG 坐标自上而下，这里换算为自下而上）
let arrowY = h - 180.0
let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 232, y: arrowY))
arrow.line(to: NSPoint(x: 300, y: arrowY))
arrow.lineWidth = 2.5
arrow.lineCapStyle = .round
NSColor(calibratedWhite: 0.62, alpha: 1).setStroke()
arrow.stroke()

let head = NSBezierPath()
head.move(to: NSPoint(x: 312, y: arrowY))
head.line(to: NSPoint(x: 296, y: arrowY + 8))
head.line(to: NSPoint(x: 296, y: arrowY - 8))
head.close()
NSColor(calibratedWhite: 0.62, alpha: 1).setFill()
head.fill()

NSGraphicsContext.restoreGraphicsState()

try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
