import AppIntents
import Foundation
import WidgetKit

// MARK: - Кнопки виджета

struct RevealCardIntent: AppIntent {
    static let title: LocalizedStringResource = "Показать перевод"
    static let isDiscoverable = false
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @Parameter(title: "Карточка") var cardID: String

    init() {}
    init(cardID: String) { self.cardID = cardID }

    func perform() async throws -> some IntentResult {
        LibraryStore.shared.update { lib in
            lib.widget.revealedID = cardID
            lib.widget.revealedSlot = WidgetPlanner.slot(for: Date(), rotationMinutes: lib.settings.rotationMinutes)
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct AnswerCardIntent: AppIntent {
    static let title: LocalizedStringResource = "Ответить на карточку"
    static let isDiscoverable = false
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @Parameter(title: "Карточка") var cardID: String
    @Parameter(title: "Знал") var known: Bool

    init() {}
    init(cardID: String, known: Bool) {
        self.cardID = cardID
        self.known = known
    }

    func perform() async throws -> some IntentResult {
        LibraryStore.shared.update { lib in
            Review.answer(cardID: cardID, known: known, lib: &lib, now: Date())
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Открыть тренировку (Пункт управления, Action Button, Siri)

struct OpenTrainingIntent: AppIntent {
    static let title: LocalizedStringResource = "Начать тренировку"
    static let description = IntentDescription("Открывает WordLock и запускает повторение слов.")
    static let openAppWhenRun = true

    init() {}

    func perform() async throws -> some IntentResult {
        LibraryStore.shared.update { $0.widget.pendingRoute = "train" }
        return .result()
    }
}

// MARK: - Настройка виджета

enum WidgetMode: String, AppEnum {
    case reveal, always

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Режим"
    static let caseDisplayRepresentations: [WidgetMode: DisplayRepresentation] = [
        .reveal: "Викторина: перевод по нажатию",
        .always: "Слово и перевод сразу"
    ]
}

enum DeckChoice: String, AppEnum {
    case all, people, home, food, travel, work, health, nature, time, actions, qualities, general, custom

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Колода"
    static let caseDisplayRepresentations: [DeckChoice: DisplayRepresentation] = [
        .all: "Все включённые колоды",
        .people: "Люди и семья",
        .home: "Дом и вещи",
        .food: "Еда и напитки",
        .travel: "Путешествия и город",
        .work: "Работа и учёба",
        .health: "Здоровье и тело",
        .nature: "Природа и погода",
        .time: "Время",
        .actions: "Глаголы",
        .qualities: "Прилагательные",
        .general: "Разное",
        .custom: "Мои слова"
    ]

    var topic: Topic? { Topic(rawValue: rawValue) }
}

// MARK: - Ссылки

enum DeepLink {
    static func card(_ id: String) -> URL? {
        var c = URLComponents()
        c.scheme = "wordlock"
        c.host = "card"
        c.queryItems = [URLQueryItem(name: "id", value: id)]
        return c.url
    }
}
