import Foundation

// MARK: - Каталог: активные карточки + очередь повторений

struct Catalog {
    let cards: [Card]
    let byID: [String: Card]
    let progress: [String: CardProgress]
    private let enabledTopics: Set<Topic>

    init(_ lib: Library) {
        let custom = lib.customCards
            .filter { !lib.deletedIDs.contains($0.id) }
            .sorted { ($0.addedAt ?? .distantPast) > ($1.addedAt ?? .distantPast) }
        let builtIn = BuiltInVocabulary.ordered.filter { !lib.deletedIDs.contains($0.id) }
        cards = custom + builtIn
        byID = Dictionary(cards.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        progress = lib.progress
        enabledTopics = lib.settings.enabledTopics
    }

    func contains(english: String) -> Card? {
        let key = english.trimmed.lowercased()
        return cards.first { $0.english.lowercased() == key }
    }

    /// Карточки выбранной колоды; если колода не задана — по включённым в настройках.
    func pool(topic: Topic?) -> [Card] {
        if let topic { return cards.filter { $0.topic == topic } }
        if enabledTopics.isEmpty { return cards }
        return cards.filter { $0.isCustom || enabledTopics.contains($0.topic) }
    }

    /// Очередь: 1) просроченные повторы, 2) новые слова, 3) всё остальное по близости срока.
    func queue(topic: Topic?, now: Date) -> [Card] {
        var due: [(Card, Date)] = []
        var fresh: [Card] = []
        var later: [(Card, Date)] = []
        for card in pool(topic: topic) {
            if let p = progress[card.id] {
                if p.due <= now { due.append((card, p.due)) } else { later.append((card, p.due)) }
            } else {
                fresh.append(card)
            }
        }
        return due.sorted { $0.1 < $1.1 }.map { $0.0 }
            + fresh
            + later.sorted { $0.1 < $1.1 }.map { $0.0 }
    }

    func dueCount(now: Date) -> Int {
        pool(topic: nil).filter { (progress[$0.id]?.due ?? .distantFuture) <= now }.count
    }

    var learnedCount: Int { pool(topic: nil).filter { progress[$0.id]?.isLearned ?? false }.count }
    var totalCount: Int { pool(topic: nil).count }
}

// MARK: - Планировщик виджета

struct WidgetPick {
    let date: Date
    let card: Card
    let revealed: Bool
}

enum WidgetPlanner {
    static func slot(for date: Date, rotationMinutes: Int) -> Int {
        let interval = Double(max(rotationMinutes, 15) * 60)
        return Int(floor(date.timeIntervalSince1970 / interval))
    }

    /// Строит расписание карточек. Текущая карточка закрепляется в плане и не «прыгает»,
    /// пока слот не закончится или пользователь не ответит.
    static func plan(lib: inout Library, deckKey: String, topic: Topic?, now: Date, count: Int) -> [WidgetPick] {
        let interval = Double(max(lib.settings.rotationMinutes, 15) * 60)
        let slot0 = slot(for: now, rotationMinutes: lib.settings.rotationMinutes)
        let catalog = Catalog(lib)
        let queue = catalog.queue(topic: topic, now: now)
        guard !queue.isEmpty else {
            lib.widget.plans[deckKey] = nil
            return []
        }

        let poolIDs = Set(queue.map(\.id))
        var current: Card?
        if let item = lib.widget.plans[deckKey]?.first(where: { $0.slot == slot0 }),
           let card = catalog.byID[item.cardID], poolIDs.contains(card.id) {
            current = card
        }
        let last = lib.widget.lastAnswered
        let cur = current ?? queue.first(where: { $0.id != last }) ?? queue[0]
        let rest = queue.filter { $0.id != cur.id }

        let revealed = lib.widget.revealedID == cur.id && lib.widget.revealedSlot == slot0
        var picks = [WidgetPick(date: now, card: cur, revealed: revealed)]
        var items = [PlanItem(slot: slot0, cardID: cur.id)]

        for i in 1...max(count, 1) {
            let slot = slot0 + i
            let card = rest.isEmpty ? cur : rest[(i - 1) % rest.count]
            picks.append(WidgetPick(date: Date(timeIntervalSince1970: Double(slot) * interval), card: card, revealed: false))
            items.append(PlanItem(slot: slot, cardID: card.id))
        }
        lib.widget.plans[deckKey] = items
        return picks
    }
}

// MARK: - Слияние с iCloud

struct CloudPayload: Codable {
    var customCards: [Card]
    var deletedIDs: Set<String>
    var progress: [String: CardProgress]
    var progressResetAt: Date
    var days: [String: DayStats]
}

extension Library {
    var cloudPayload: CloudPayload {
        CloudPayload(customCards: customCards, deletedIDs: deletedIDs, progress: progress,
                     progressResetAt: progressResetAt, days: days)
    }

    /// Объединяет данные другого устройства: побеждает более свежий ответ.
    mutating func merge(_ remote: CloudPayload) {
        deletedIDs.formUnion(remote.deletedIDs)
        progressResetAt = max(progressResetAt, remote.progressResetAt)

        let known = Set(customCards.map(\.id))
        for card in remote.customCards where !known.contains(card.id) { customCards.append(card) }
        customCards.removeAll { deletedIDs.contains($0.id) }

        for (id, theirs) in remote.progress {
            if let mine = progress[id], mine.updated >= theirs.updated { continue }
            progress[id] = theirs
        }
        progress = progress.filter { $0.value.updated > progressResetAt && !deletedIDs.contains($0.key) }

        for (key, theirs) in remote.days {
            var mine = days[key] ?? DayStats()
            mine.reviews = max(mine.reviews, theirs.reviews)
            mine.correct = max(mine.correct, theirs.correct)
            days[key] = mine
        }
    }
}
