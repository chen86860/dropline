import AppKit

/// 菜单栏图标：和 App 图标同一个符号（Lucide arrow-up-from-line，箭头 + 底部横线）。
/// 上传时收起底部横线，改在外围画一圈进度环。
enum TrayIcon {

    static func image(progress: Double?) -> NSImage {
        guard let progress else { return idle }
        return uploading(progress: max(0, min(1, progress)))
    }

    /// 两种状态必须画在完全相同尺寸的画布上，否则菜单栏图标宽度会变、
    /// 导致右侧图标整体横向跳动。
    private static let side: CGFloat = 18

    private static let idle: NSImage = render {
        NSColor.black.setStroke()
        drawGlyph(height: side * 0.80, baseline: true)
    }

    private static func uploading(progress: Double) -> NSImage {
        render {
            drawRing(progress: progress)
            NSColor.black.setStroke()
            // 去掉底线并缩小，整个符号落在进度环内侧
            drawGlyph(height: side * 0.52, baseline: false)
        }
    }

    // MARK: - 绘制

    private static func render(_ body: @escaping () -> Void) -> NSImage {
        let img = NSImage(size: NSSize(width: side, height: side), flipped: false) { _ in
            body()
            return true
        }
        img.isTemplate = true   // 单色模板，跟随菜单栏明暗自动反色
        return img
    }

    /// Lucide arrow-up-from-line，原始 viewBox 24×24、stroke-width 2、圆头圆角：
    ///     m18 9-6-6-6 6 / M12 3v14 / M5 21h14
    /// SVG 的 y 轴朝下，这里换算成 AppKit 的 y 轴朝上（y' = 24 - y）：
    ///     箭头 (6,15)→(12,21)→(18,15)   竖杆 (12,21)→(12,7)   底线 (5,3)→(19,3)
    /// 含描边后的包围盒：带底线 y∈[2,22]，不带底线 y∈[6,22]，中心随之不同。
    /// 与 tools/makeicon.swift 里的 App 图标共用这套几何，改一处要同步另一处。
    private static func drawGlyph(height: CGFloat, baseline: Bool) {
        let unitH: CGFloat = baseline ? 20 : 16
        let unitCenterY: CGFloat = baseline ? 12 : 14
        let s = height / unitH
        func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
            NSPoint(x: side / 2 + (x - 12) * s, y: side / 2 + (y - unitCenterY) * s)
        }

        func stroke(_ make: (NSBezierPath) -> Void) {
            let path = NSBezierPath()
            make(path)
            path.lineWidth = 2 * s
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()
        }

        stroke { $0.move(to: p(12, 21)); $0.line(to: p(12, 7)) }
        stroke { $0.move(to: p(6, 15)); $0.line(to: p(12, 21)); $0.line(to: p(18, 15)) }
        if baseline {
            stroke { $0.move(to: p(5, 3)); $0.line(to: p(19, 3)) }
        }
    }

    private static func drawRing(progress: Double) {
        let center = NSPoint(x: side / 2, y: side / 2)
        let radius = side / 2 - 1.5
        let lineWidth: CGFloat = 2

        let track = NSBezierPath()
        track.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
        track.lineWidth = lineWidth
        NSColor.black.withAlphaComponent(0.28).setStroke()
        track.stroke()

        // 进度弧：12 点方向顺时针
        guard progress > 0.001 else { return }
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
}
