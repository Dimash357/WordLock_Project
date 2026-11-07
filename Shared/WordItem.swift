import AppIntents
import CryptoKit
import Foundation
import WidgetKit

struct WordItem: Identifiable, Codable, Hashable {
    var id: UUID
    var english: String
    var translation: String
    var deck: String
    var example: String
    var phonetic: String

    init(english: String, translation: String, id: UUID? = nil, deck: String = "General", example: String = "", phonetic: String = "") {
        self.english = english
        self.translation = translation
        self.id = id ?? Self.stableID(english: english, translation: translation)
        self.deck = deck
        self.example = example
        self.phonetic = phonetic
    }

    static func stableID(english: String, translation: String) -> UUID {
        let digest = SHA256.hash(data: Data("wordlock|\(english.lowercased())|\(translation.lowercased())".utf8))
        let b = Array(digest.prefix(16))
        return UUID(uuid: (b[0],b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8],b[9],b[10],b[11],b[12],b[13],b[14],b[15]))
    }

    enum CodingKeys: String, CodingKey { case id, english, translation, deck, example, phonetic }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        english = try c.decode(String.self, forKey: .english)
        translation = try c.decode(String.self, forKey: .translation)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? Self.stableID(english: english, translation: translation)
        deck = (try? c.decode(String.self, forKey: .deck)) ?? "General"
        example = (try? c.decode(String.self, forKey: .example)) ?? ""
        phonetic = (try? c.decode(String.self, forKey: .phonetic)) ?? ""
    }
}

struct WordProgress: Codable {
    var box: Int = 0
    var nextReview: Date = .distantPast
    var attempts: Int = 0
    var correct: Int = 0
    var lastReviewed: Date? = nil
}

enum WordDefaults {
    static let appGroup = "group.com.dimash.wordlock"
    static let storageKey = "savedWords"
    static let learnedKey = "learnedWords"
    static let vocabularyVersionKey = "vocabularyVersion"
    static let vocabularyVersion = 3
    static let intervalKey = "rotationMinutes"
    static let words = PreIntermediateVocabulary.words
}

enum SharedWordStorage {
    private static var defaults: UserDefaults? { UserDefaults(suiteName: WordDefaults.appGroup) }
    private static let progressKey = "reviewProgressV3"
    private static let deletedKey = "deletedDefaultIDsV3"
    private static let selectedDeckKey = "selectedDeckV3"
    private static let queueSeedKey = "queueSeedV3"
    private static let dayKey = "studyDaysV3"
    private static let revealKey = "revealedWordV3"
    private static let hiddenLegacyKey = "legacyMigrationV3"

    static func load() -> [WordItem] {
        guard let defaults else { return WordDefaults.words }
        let saved = defaults.data(forKey: WordDefaults.storageKey).flatMap { try? JSONDecoder().decode([WordItem].self, from: $0) } ?? []
        let deleted = Set(defaults.stringArray(forKey: deletedKey) ?? [])
        var seen = Set<UUID>()
        let result = (WordDefaults.words + saved).filter { !deleted.contains($0.id.uuidString) && seen.insert($0.id).inserted }
        if !defaults.bool(forKey: hiddenLegacyKey) {
            var progress = progressMap()
            let old = Set(defaults.stringArray(forKey: WordDefaults.learnedKey) ?? [])
            for word in result where old.contains(word.english.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) {
                progress[word.id.uuidString] = WordProgress(box: 5, nextReview: Date().addingTimeInterval(30 * 86400), attempts: 1, correct: 1, lastReviewed: .now)
            }
            saveProgress(progress)
            defaults.set(true, forKey: hiddenLegacyKey)
        }
        if defaults.integer(forKey: WordDefaults.vocabularyVersionKey) < WordDefaults.vocabularyVersion {
            save(result)
            defaults.set(WordDefaults.vocabularyVersion, forKey: WordDefaults.vocabularyVersionKey)
        }
        return result
    }

    static func save(_ words: [WordItem]) {
        guard let data = try? JSONEncoder().encode(words) else { return }
        defaults?.set(data, forKey: WordDefaults.storageKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func delete(_ words: [WordItem]) {
        var deleted = Set(defaults?.stringArray(forKey: deletedKey) ?? [])
        for word in words { deleted.insert(word.id.uuidString) }
        defaults?.set(Array(deleted), forKey: deletedKey)
        save(load().filter { !deleted.contains($0.id.uuidString) })
    }

    static func restoreDefaults() {
        defaults?.removeObject(forKey: deletedKey)
        save(WordDefaults.words)
    }

    static func progressMap() -> [String: WordProgress] {
        guard let data = defaults?.data(forKey: progressKey) else { return [:] }
        return (try? JSONDecoder().decode([String: WordProgress].self, from: data)) ?? [:]
    }
    private static func saveProgress(_ map: [String: WordProgress]) {
        if let data = try? JSONEncoder().encode(map) { defaults?.set(data, forKey: progressKey) }
        WidgetCenter.shared.reloadAllTimelines()
    }
    static func progress(for id: UUID) -> WordProgress { progressMap()[id.uuidString] ?? WordProgress() }
    static func learnedIDs() -> Set<UUID> { Set(progressMap().compactMap { pair in pair.value.box >= 5 ? UUID(uuidString: pair.key) : nil }) }
    static func resetProgress() { saveProgress([:]) }
    static func review(_ id: UUID, knew: Bool) {
        var map = progressMap()
        var p = map[id.uuidString] ?? WordProgress()
        p.attempts += 1
        if knew { p.correct += 1; p.box = min(5, p.box + 1) }
        else { p.box = 0 }
        let days = [0, 1, 3, 7, 14, 30][p.box]
        p.nextReview = knew ? Date().addingTimeInterval(TimeInterval(days * 86400)) : .now
        p.lastReviewed = .now
        map[id.uuidString] = p
        saveProgress(map)
        var daysStudied = Set(defaults?.stringArray(forKey: dayKey) ?? [])
        daysStudied.insert(ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: .now)).prefix(10).description)
        defaults?.set(Array(daysStudied), forKey: dayKey)
        defaults?.removeObject(forKey: revealKey)
    }
    static func studyDays() -> Set<String> { Set(defaults?.stringArray(forKey: dayKey) ?? []) }
    static func rotationMinutes() -> Int {
        let v = defaults?.integer(forKey: WordDefaults.intervalKey) ?? 60
        return [15,30,60,120,240].contains(v) ? v : 60
    }
    static func setRotationMinutes(_ minutes: Int) {
        defaults?.set(minutes, forKey: WordDefaults.intervalKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
    static func selectedDeck() -> String { defaults?.string(forKey: selectedDeckKey) ?? "All" }
    static func setSelectedDeck(_ deck: String) { defaults?.set(deck, forKey: selectedDeckKey); WidgetCenter.shared.reloadAllTimelines() }
    static func revealedID() -> String? { defaults?.string(forKey: revealKey) }
    static func reveal(_ id: UUID) { defaults?.set(id.uuidString, forKey: revealKey); WidgetCenter.shared.reloadAllTimelines() }

    static func ordered(_ words: [WordItem]) -> [WordItem] {
        // Deterministic pseudo-random ordering, stable across app and widget processes.
        words.sorted { a, b in
            let seed = defaults?.integer(forKey: queueSeedKey) ?? 2026
            func score(_ id: UUID) -> String {
                SHA256.hash(data: Data("\(seed)|\(id.uuidString)".utf8)).map { String(format: "%02x", $0) }.joined()
            }
            return score(a.id) < score(b.id)
        }
    }
    static func candidates(_ words: [WordItem], at date: Date) -> [WordItem] {
        let deck = selectedDeck()
        let filtered = words.filter { deck == "All" || $0.deck == deck }
        let source = filtered.isEmpty ? words : filtered
        let progress = progressMap()
        let due = source.filter { item in
            guard let p = progress[item.id.uuidString] else { return false }
            return p.attempts > 0 && p.nextReview <= date
        }
        let new = source.filter { progress[$0.id.uuidString] == nil }
        return ordered(due) + ordered(new) + ordered(source.filter { item in
            guard let p = progress[item.id.uuidString] else { return false }
            return p.attempts > 0 && p.nextReview > date
        })
    }
    static func word(at date: Date, from words: [WordItem]? = nil) -> WordItem {
        let queue = candidates(words ?? load(), at: date)
        guard !queue.isEmpty else { return WordItem(english: "Hello", translation: "Привет") }
        let slot = Int(floor(date.timeIntervalSince1970 / Double(rotationMinutes() * 60)))
        return queue[(slot % queue.count + queue.count) % queue.count]
    }
}

struct ReviewWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Review word"
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    @Parameter(title: "Word ID") var wordID: String
    @Parameter(title: "Knew it") var knew: Bool
    init() {}
    init(wordID: String, knew: Bool) { self.wordID = wordID; self.knew = knew }
    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: wordID) { SharedWordStorage.review(id, knew: knew) }
        return .result()
    }
}

struct RevealWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Reveal translation"
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    @Parameter(title: "Word ID") var wordID: String
    init() {}
    init(wordID: String) { self.wordID = wordID }
    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: wordID) { SharedWordStorage.reveal(id) }
        return .result()
    }
}
