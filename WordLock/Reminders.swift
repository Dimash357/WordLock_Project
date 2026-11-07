import Foundation
import UserNotifications

enum Reminders {
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Планирует напоминания на ближайшие 7 дней. Если сегодня уже были повторения — сегодняшнее пропускается.
    static func reschedule(_ lib: Library, now: Date = Date()) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (0..<7).map { "daily-\($0)" })
        guard lib.settings.reminderEnabled else { return }

        let cal = Calendar.current
        let doneToday = (lib.days[DayKey.key(now)]?.reviews ?? 0) > 0
        for offset in 0..<7 {
            if offset == 0 && doneToday { continue }
            guard let day = cal.date(byAdding: .day, value: offset, to: now) else { continue }
            var comps = cal.dateComponents([.year, .month, .day], from: day)
            comps.hour = lib.settings.reminderHour
            comps.minute = lib.settings.reminderMinute
            guard let fire = cal.date(from: comps), fire > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = String(localized: "Пора повторить слова")
            content.body = String(localized: "Пара минут сегодня — и слова запомнятся надолго.")
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: "daily-\(offset)", content: content, trigger: trigger))
        }
    }
}
