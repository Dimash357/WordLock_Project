import SwiftUI
import WidgetKit

struct CardRef: Identifiable, Hashable { let id: String }

enum SessionKind: String, Identifiable {
    case flashcards, quiz, typing
    var id: String { rawValue }
}

final class AppModel: ObservableObject {
    @Published private(set) var lib: Library
    @Published private(set) var catalog: Catalog
    @Published var session: SessionKind?
    @Published var cardRef: CardRef?
    @Published var showOnboarding = false

    private let store = LibraryStore.shared
    private let cloud = CloudSync()

    init() {
        let l = LibraryStore.shared.read()
        lib = l
        catalog = Catalog(l)
        cloud.onRemoteChange = { [weak self] in self?.pullCloud() }
        cloud.start()
    }

    // MARK: Состояние

    func reload() {
        let l = store.read()
        lib = l
        catalog = Catalog(l)
    }

    @discardableResult
    func mutate(widgets: Bool = true, push: Bool = true, _ body: (inout Library) -> Void) -> Library {
        let l = store.update(body)
        lib = l
        catalog = Catalog(l)
        if widgets { WidgetCenter.shared.reloadAllTimelines() }
        if push { cloud.push(l) }
        return l
    }

    func didBecomeActive() {
        reload()
        pullCloud()
        if lib.widget.pendingRoute == "train" {
            mutate(widgets: false, push: false) { $0.widget.pendingRoute = nil }
            session = .flashcards
        }
        Reminders.reschedule(lib)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func handle(url: URL) {
        guard url.scheme == "wordlock" else { return }
        switch url.host {
        case "card":
            let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "id" })?.value
            if let id { cardRef = CardRef(id: id) }
        case "train":
            session = .flashcards
        default:
            break
        }
    }

    private func pullCloud() {
        guard let payload = cloud.pull() else { return }
        DispatchQueue.main.async {
            let before = self.lib.cloudPayload
            let after = self.store.update { $0.merge(payload) }
            self.lib = after
            self.catalog = Catalog(after)
            if after.cloudPayload.progress != before.progress || after.customCards != before.customCards {
                WidgetCenter.shared.reloadAllTimelines()
            }
            self.cloud.push(after)
        }
    }

    // MARK: Статистика

    var todayReviews: Int { lib.days[DayKey.key(Date())]?.reviews ?? 0 }
    var streak: Int { Stats.streak(lib, now: Date()) }
    var dueCount: Int { catalog.dueCount(now: Date()) }
    var learnedCount: Int { catalog.learnedCount }
    var totalCount: Int { catalog.totalCount }
    var week: [(date: Date, reviews: Int)] { Stats.lastDays(lib, count: 7, now: Date()) }

    func progress(for id: String) -> CardProgress? { lib.progress[id] }

    func binding<T>(_ keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(get: { self.lib.settings[keyPath: keyPath] },
                set: { value in self.mutate { $0.settings[keyPath: keyPath] = value } })
    }

    // MARK: Тренировка

    func sessionCards(limit: Int = 15) -> [Card] {
        Array(catalog.queue(topic: nil, now: Date()).prefix(limit))
    }

    func answer(_ card: Card, known: Bool) {
        mutate(widgets: false) { Review.answer(cardID: card.id, known: known, lib: &$0, now: Date()) }
    }

    func finishSession() {
        WidgetCenter.shared.reloadAllTimelines()
        Reminders.reschedule(lib)
    }

    func speak(_ text: String) {
        Speaker.shared.speak(text, accent: lib.settings.accent)
    }

    // MARK: Словарь

    @discardableResult
    func addCard(english: String, translation: String, example: String) -> Bool {
        let en = english.trimmed, tr = translation.trimmed, ex = example.trimmed
        guard !en.isEmpty, !tr.isEmpty, catalog.contains(english: en) == nil else { return false }
        let card = Card(id: "c:" + UUID().uuidString, english: en, translation: tr, ipa: nil,
                        example: ex.isEmpty ? nil : ex, topic: .custom, isCustom: true, addedAt: Date())
        mutate { $0.customCards.append(card) }
        return true
    }

    func delete(_ id: String) {
        mutate {
            $0.deletedIDs.insert(id)
            $0.customCards.removeAll { $0.id == id }
            $0.progress[id] = nil
            $0.widget.plans = [:]
        }
    }

    func toggleLearned(_ id: String) {
        mutate {
            if $0.progress[id]?.isLearned == true {
                $0.progress[id] = nil
            } else {
                $0.progress[id] = SRS.markLearned(now: Date())
            }
            $0.widget.plans = [:]
        }
    }

    func resetProgress() {
        mutate {
            $0.progress = [:]
            $0.progressResetAt = Date()
            $0.widget = WidgetState()
        }
    }

    func restoreDefaultWords() {
        mutate { lib in
            lib.deletedIDs = lib.deletedIDs.filter { !$0.hasPrefix("b:") }
            lib.widget.plans = [:]
        }
    }

    func toggleTopic(_ topic: Topic, enabled: Bool) {
        mutate { lib in
            var set = lib.settings.enabledTopics.isEmpty ? Set(Topic.selectable) : lib.settings.enabledTopics
            if enabled { set.insert(topic) } else if set.count > 1 { set.remove(topic) }
            lib.settings.enabledTopics = (set.count == Topic.selectable.count) ? [] : set
            lib.widget.plans = [:]
        }
    }

    func isTopicEnabled(_ topic: Topic) -> Bool {
        lib.settings.enabledTopics.isEmpty || lib.settings.enabledTopics.contains(topic)
    }

    // MARK: Импорт / экспорт

    func importCSV(_ text: String) -> Int {
        let rows = CSV.parse(text)
        var added = 0
        let headers: Set<String> = ["english", "word", "front", "английский", "слово"]
        mutate { lib in
            var existing = Set(Catalog(lib).cards.map { $0.english.lowercased() })
            for (index, row) in rows.enumerated() {
                guard row.count >= 2 else { continue }
                let en = row[0].trimmed, tr = row[1].trimmed
                if index == 0, headers.contains(en.lowercased()) { continue }
                guard !en.isEmpty, !tr.isEmpty, existing.insert(en.lowercased()).inserted else { continue }
                let ex = row.count > 2 ? row[2].trimmed : ""
                lib.customCards.append(Card(id: "c:" + UUID().uuidString, english: en, translation: tr, ipa: nil,
                                            example: ex.isEmpty ? nil : ex, topic: .custom, isCustom: true,
                                            addedAt: Date().addingTimeInterval(Double(added))))
                added += 1
            }
        }
        return added
    }

    func exportCSV() -> String {
        CSV.export(catalog.cards)
    }
}
