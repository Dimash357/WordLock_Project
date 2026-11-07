import AppIntents

/// «Покажи слово» для Siri и Shortcuts.
struct ShowWordIntent: AppIntent {
    static let title: LocalizedStringResource = "Показать слово"
    static let description = IntentDescription("Называет следующее слово для повторения.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let lib = LibraryStore.shared.read()
        guard let card = Catalog(lib).queue(topic: nil, now: Date()).first else {
            return .result(dialog: IntentDialog(stringLiteral: String(localized: "В словаре нет слов.")))
        }
        return .result(dialog: IntentDialog(stringLiteral: "\(card.english) — \(card.translation)"))
    }
}

struct WordLockShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: ShowWordIntent(),
                    phrases: ["Show a word in \(.applicationName)", "Покажи слово в \(.applicationName)"],
                    shortTitle: "Показать слово",
                    systemImageName: "text.book.closed")
        AppShortcut(intent: OpenTrainingIntent(),
                    phrases: ["Start training in \(.applicationName)", "Начать тренировку в \(.applicationName)"],
                    shortTitle: "Начать тренировку",
                    systemImageName: "rectangle.on.rectangle.angled")
    }
}
