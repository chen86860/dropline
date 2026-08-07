// 生成 App 图标 PNG（1024x1024）。由 build.sh 调用。
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

// 上传箭头
let arrow = NSBezierPath()
let cx = size / 2
let stemW = size * 0.11
let top = size * 0.72
let bottom = size * 0.28
let headW = size * 0.30
let headH = size * 0.20
arrow.move(to: NSPoint(x: cx, y: top))
arrow.line(to: NSPoint(x: cx + headW / 2, y: top - headH))
arrow.line(to: NSPoint(x: cx + stemW / 2, y: top - headH))
arrow.line(to: NSPoint(x: cx + stemW / 2, y: bottom))
arrow.line(to: NSPoint(x: cx - stemW / 2, y: bottom))
arrow.line(to: NSPoint(x: cx - stemW / 2, y: top - headH))
arrow.line(to: NSPoint(x: cx - headW / 2, y: top - headH))
arrow.close()
NSColor.white.setFill()
arrow.fill()

// 底部托盘线
let tray = NSBezierPath(roundedRect: NSRect(x: cx - size * 0.20, y: size * 0.19,
                                            width: size * 0.40, height: size * 0.045),
                        xRadius: size * 0.022, yRadius: size * 0.022)
NSColor(white: 1, alpha: 0.85).setFill()
tray.fill()

NSGraphicsContext.restoreGraphicsState()

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
