import Foundation
import WidgetKit

@MainActor
final class WordStore: ObservableObject {
    @Published private(set) var words: [WordItem] = []

    init() {
        words = SharedWordStorage.load()
    }

    func add(english: String, translation: String) {
        let cleanEnglish = english.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTranslation = translation.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanEnglish.isEmpty, !cleanTranslation.isEmpty else { return }
        words.append(WordItem(english: cleanEnglish, translation: cleanTranslation))
        persist()
    }

    func delete(at offsets: IndexSet) {
        words.remove(atOffsets: offsets)
        if words.isEmpty {
            words = WordDefaults.words
        }
        persist()
    }

    func restoreDefaults() {
        words = WordDefaults.words
        persist()
    }

    private func persist() {
        SharedWordStorage.save(words)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
