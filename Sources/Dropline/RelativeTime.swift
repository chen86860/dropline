import Foundation

/// 历史记录的时间显示：越近越省略。
///
/// - 今天    → `15:04`
/// - 昨天    → `昨天 15:04`
/// - 本周内  → `周三 15:04`
/// - 更早    → `2026年8月3日 15:04`
///
/// 语言跟 App 内的设置走（`L10n.resolved`），不是系统区域。
enum RelativeTime {

    static func label(for date: Date,
                      now: Date = Date(),
                      calendar: Calendar = .current) -> String {
        let f = formatters()
        let time = f.time.string(from: date)

        if calendar.isDateInToday(date) { return time }
        if calendar.isDateInYesterday(date) { return "Yesterday %@".t(time) }
        // 未来的时间（改过系统时钟等）没有「本周」的说法，直接走完整格式
        if date < now, calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return "\(f.weekday.string(from: date)) \(time)"
        }
        return f.full.string(from: date)
    }

    // MARK: 格式化器

    private struct Formatters {
        let time: DateFormatter
        let weekday: DateFormatter
        let full: DateFormatter
    }

    /// DateFormatter 建一次不便宜，按语言缓存；语言一变就重建
    private static var cached: (language: L10n.Resolved, set: Formatters)?

    private static func formatters() -> Formatters {
        let language = L10n.resolved
        if let cached, cached.language == language { return cached.set }

        let locale = Locale(identifier: language == .zh ? "zh_Hans_CN" : "en_US")

        let time = DateFormatter()
        time.locale = locale
        time.dateFormat = "HH:mm"          // 两种语言都用 24 小时，列表里对齐好看

        let weekday = DateFormatter()
        weekday.locale = locale
        weekday.dateFormat = "EEE"         // zh → 周三；en → Wed

        let full = DateFormatter()
        full.locale = locale
        full.dateFormat = language == .zh ? "yyyy年M月d日 HH:mm" : "MMM d, yyyy HH:mm"

        let set = Formatters(time: time, weekday: weekday, full: full)
        cached = (language, set)
        return set
    }
}
