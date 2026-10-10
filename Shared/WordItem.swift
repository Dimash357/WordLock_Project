import AppIntents
import Foundation
import WidgetKit

struct WordItem: Identifiable, Codable, Hashable {
    var english: String
    var translation: String
    var id: String { english.lowercased() }
}

enum WordDefaults {
    static let appGroup = "group.com.example.WordLock"
    static let storageKey = "savedWords"
    static let learnedKey = "learnedWords"
    static let currentWordKey = "currentWord"
    static let vocabularyVersionKey = "vocabularyVersion"
    static let vocabularyVersion = 2
    static let words = PreIntermediateVocabulary.words
}

enum SharedWordStorage {
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: WordDefaults.appGroup)
    }

    static func load() -> [WordItem] {
        guard let defaults else { return WordDefaults.words }
        let saved = defaults.data(forKey: WordDefaults.storageKey)
            .flatMap { try? JSONDecoder().decode([WordItem].self, from: $0) } ?? []

        if defaults.integer(forKey: WordDefaults.vocabularyVersionKey) < WordDefaults.vocabularyVersion {
            var seen = Set<String>()
            let merged = (WordDefaults.words + saved).filter { seen.insert($0.id).inserted }
            save(merged)
            defaults.set(WordDefaults.vocabularyVersion, forKey: WordDefaults.vocabularyVersionKey)
            return merged
        }

        return saved.isEmpty ? WordDefaults.words : saved
    }

    static func save(_ words: [WordItem]) {
        guard
            let defaults,
            let data = try? JSONEncoder().encode(words)
        else { return }

        defaults.set(data, forKey: WordDefaults.storageKey)
    }

    static func learnedIDs() -> Set<String> {
        Set(defaults?.stringArray(forKey: WordDefaults.learnedKey) ?? [])
    }

    static func currentWord() -> WordItem {
        let words = load()
        let learned = learnedIDs()
        let available = words.filter { !learned.contains($0.id) }
        let candidates = available.isEmpty ? words : available

        if let currentID = defaults?.string(forKey: WordDefaults.currentWordKey),
           let current = candidates.first(where: { $0.id == currentID }) {
            return current
        }

        let first = candidates[0]
        defaults?.set(first.id, forKey: WordDefaults.currentWordKey)
        return first
    }

    static func learnCurrentAndAdvance() {
        let words = load()
        guard !words.isEmpty else { return }

        let current = currentWord()
        var learned = learnedIDs()
        learned.insert(current.id)
        var available = words.filter { !learned.contains($0.id) }

        if available.isEmpty {
            learned.removeAll()
            available = words.filter { $0.id != current.id }
            if available.isEmpty { available = words }
        }

        defaults?.set(Array(learned), forKey: WordDefaults.learnedKey)
        defaults?.set(available[0].id, forKey: WordDefaults.currentWordKey)
    }
}

struct LearnWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Слово выучено"
    static var description = IntentDescription("Отмечает слово как выученное и показывает следующее.")

    func perform() async throws -> some IntentResult {
        SharedWordStorage.learnCurrentAndAdvance()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
