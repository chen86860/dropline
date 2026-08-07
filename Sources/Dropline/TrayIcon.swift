import AppKit

/// 菜单栏图标：空闲时是上传箭头，上传中画成进度环。
enum TrayIcon {

    static func image(progress: Double?) -> NSImage {
        guard let progress else { return idle }
        return ring(progress: max(0, min(1, progress)))
    }

    /// 两种状态必须画在完全相同尺寸的画布上，否则菜单栏图标宽度会变、
    /// 导致右侧图标整体横向跳动。
    private static let side: CGFloat = 18

    private static let idle: NSImage = {
        let img = NSImage(size: NSSize(width: side, height: side), flipped: false) { _ in
            guard let symbol = NSImage(systemSymbolName: "arrow.up.circle",
                                       accessibilityDescription: "Dropline") else { return true }
            let configured = symbol.withSymbolConfiguration(
                NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)) ?? symbol
            let s = configured.size
            configured.draw(in: NSRect(x: (side - s.width) / 2,
                                       y: (side - s.height) / 2,
                                       width: s.width, height: s.height))
            return true
        }
        img.isTemplate = true
        return img
    }()

    private static func ring(progress: Double) -> NSImage {
        let img = NSImage(size: NSSize(width: side, height: side), flipped: false) { _ in
            let center = NSPoint(x: side / 2, y: side / 2)
            let radius = side / 2 - 2
            let lineWidth: CGFloat = 2

            // 底环
            let track = NSBezierPath()
            track.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
            track.lineWidth = lineWidth
            NSColor.black.withAlphaComponent(0.28).setStroke()
            track.stroke()

            // 进度弧：12 点方向顺时针
            if progress > 0.001 {
                let arc = NSBezierPath()
                arc.appendArc(withCenter: center, radius: radius,
                              startAngle: 90,
                              endAngle: 90 - 360 * CGFloat(progress),
                              clockwise: true)
                arc.lineWidth = lineWidth
                arc.lineCapStyle = .round
                NSColor.black.setStroke()
                arc.stroke()
            }

            // 中间的小箭头
            let arrow = NSBezierPath()
            arrow.move(to: NSPoint(x: center.x, y: center.y + 3.6))
            arrow.line(to: NSPoint(x: center.x - 2.6, y: center.y + 0.6))
            arrow.line(to: NSPoint(x: center.x + 2.6, y: center.y + 0.6))
            arrow.close()
            NSColor.black.setFill()
            arrow.fill()
            NSBezierPath(rect: NSRect(x: center.x - 0.9, y: center.y - 3.6, width: 1.8, height: 4.2)).fill()

            return true
        }
        img.isTemplate = true   // 跟随菜单栏明暗自动反色
        return img
    }
}
