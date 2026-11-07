import Foundation

/// Упрощённая система Лейтнера: 5 коробок, интервалы 1 / 3 / 7 / 14 / 30 дней.
enum SRS {
    /// Индекс = номер коробки (0 не используется).
    static let intervalDays: [Double] = [0, 1, 3, 7, 14, 30]
    /// Через сколько вернуть слово, если ответ «Не знал».
    static let retryDelay: TimeInterval = 10 * 60

    static func apply(known: Bool, to existing: CardProgress?, now: Date) -> CardProgress {
        var p = existing ?? CardProgress(box: 0, due: now, updated: now, correct: 0, wrong: 0)
        if known {
            // Если пользователь сразу знает новое слово — пропускаем первую коробку.
            let newBox = (existing == nil) ? 2 : min(p.box + 1, 5)
            p.box = newBox
            p.due = now.addingTimeInterval(intervalDays[newBox] * 86_400)
            p.correct += 1
        } else {
            p.box = 1
            p.due = now.addingTimeInterval(retryDelay)
            p.wrong += 1
        }
        p.updated = now
        return p
    }

    /// Ручная отметка «выучено».
    static func markLearned(now: Date) -> CardProgress {
        CardProgress(box: 5, due: now.addingTimeInterval(intervalDays[5] * 86_400), updated: now, correct: 1, wrong: 0)
    }
}

enum Review {
    /// Единая точка записи ответа: прогресс, статистика дня, сброс состояния виджета.
    static func answer(cardID: String, known: Bool, lib: inout Library, now: Date) {
        lib.progress[cardID] = SRS.apply(known: known, to: lib.progress[cardID], now: now)

        let key = DayKey.key(now)
        var day = lib.days[key] ?? DayStats()
        day.reviews += 1
        if known { day.correct += 1 }
        lib.days[key] = day
        if lib.days.count > 400 {
            for k in lib.days.keys.sorted().prefix(lib.days.count - 400) { lib.days[k] = nil }
        }

        lib.widget.lastAnswered = cardID
        lib.widget.revealedID = nil
        lib.widget.revealedSlot = nil
        lib.widget.plans = [:]
    }
}

enum Stats {
    static func streak(_ lib: Library, now: Date) -> Int {
        let cal = Calendar.current
        var day = now
        if (lib.days[DayKey.key(day)]?.reviews ?? 0) == 0 {
            guard let y = cal.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = y
        }
        var count = 0
        while (lib.days[DayKey.key(day)]?.reviews ?? 0) > 0 {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    static func lastDays(_ lib: Library, count: Int, now: Date) -> [(date: Date, reviews: Int)] {
        let cal = Calendar.current
        return (0..<count).reversed().compactMap { offset in
            guard let d = cal.date(byAdding: .day, value: -offset, to: now) else { return nil }
            return (d, lib.days[DayKey.key(d)]?.reviews ?? 0)
        }
    }
}
