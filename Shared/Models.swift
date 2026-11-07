import Foundation

enum AppGroup {
    static let id = "group.com.dimash.wordlock"
}

// MARK: - Темы (колоды)

enum Topic: String, CaseIterable, Codable, Identifiable {
    case people, home, food, travel, work, health, nature, time, actions, qualities, general, custom

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Topic(rawValue: raw) ?? .general
    }

    /// Колоды, которые пользователь может включать/выключать (без «Мои слова»).
    static var selectable: [Topic] { allCases.filter { $0 != .custom } }

    var title: String {
        switch self {
        case .people: return String(localized: "Люди и семья")
        case .home: return String(localized: "Дом и вещи")
        case .food: return String(localized: "Еда и напитки")
        case .travel: return String(localized: "Путешествия и город")
        case .work: return String(localized: "Работа и учёба")
        case .health: return String(localized: "Здоровье и тело")
        case .nature: return String(localized: "Природа и погода")
        case .time: return String(localized: "Время")
        case .actions: return String(localized: "Глаголы")
        case .qualities: return String(localized: "Прилагательные")
        case .general: return String(localized: "Разное")
        case .custom: return String(localized: "Мои слова")
        }
    }

    var symbol: String {
        switch self {
        case .people: return "person.2.fill"
        case .home: return "house.fill"
        case .food: return "fork.knife"
        case .travel: return "airplane"
        case .work: return "briefcase.fill"
        case .health: return "heart.fill"
        case .nature: return "leaf.fill"
        case .time: return "clock.fill"
        case .actions: return "figure.walk"
        case .qualities: return "sparkles"
        case .general: return "square.grid.2x2.fill"
        case .custom: return "star.fill"
        }
    }
}

// MARK: - Карточка

struct Card: Identifiable, Codable, Hashable {
    var id: String
    var english: String
    var translation: String
    var ipa: String?
    var example: String?
    var topic: Topic
    var isCustom: Bool
    var addedAt: Date?
}

// MARK: - Прогресс (интервальные повторения)

struct CardProgress: Codable, Hashable {
    var box: Int          // 1...5 (коробки Лейтнера)
    var due: Date         // когда повторить
    var updated: Date
    var correct: Int
    var wrong: Int

    /// Слово считается выученным с 4-й коробки.
    var isLearned: Bool { box >= 4 }
}

struct DayStats: Codable, Hashable {
    var reviews = 0
    var correct = 0
}

// MARK: - Настройки

struct AppSettings: Codable, Equatable {
    var rotationMinutes = 60
    var dailyGoal = 10
    var accent = "en-US"
    var reminderEnabled = false
    var reminderHour = 19
    var reminderMinute = 0
    var enabledTopics: Set<Topic> = []   // пусто = все колоды
    var translateTo = "ru"

    static let rotationOptions = [15, 30, 60, 120, 240]

    enum CodingKeys: String, CodingKey {
        case rotationMinutes, dailyGoal, accent, reminderEnabled, reminderHour, reminderMinute, enabledTopics, translateTo
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rotationMinutes = try c.decodeIfPresent(Int.self, forKey: .rotationMinutes) ?? 60
        dailyGoal = try c.decodeIfPresent(Int.self, forKey: .dailyGoal) ?? 10
        accent = try c.decodeIfPresent(String.self, forKey: .accent) ?? "en-US"
        reminderEnabled = try c.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? false
        reminderHour = try c.decodeIfPresent(Int.self, forKey: .reminderHour) ?? 19
        reminderMinute = try c.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? 0
        enabledTopics = try c.decodeIfPresent(Set<Topic>.self, forKey: .enabledTopics) ?? []
        translateTo = try c.decodeIfPresent(String.self, forKey: .translateTo) ?? "ru"
    }
}

// MARK: - Состояние виджета

struct PlanItem: Codable, Hashable {
    var slot: Int
    var cardID: String
}

struct WidgetState: Codable, Equatable {
    var plans: [String: [PlanItem]] = [:]
    var revealedID: String?
    var revealedSlot: Int?
    var lastAnswered: String?
    var pendingRoute: String?

    enum CodingKeys: String, CodingKey { case plans, revealedID, revealedSlot, lastAnswered, pendingRoute }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        plans = try c.decodeIfPresent([String: [PlanItem]].self, forKey: .plans) ?? [:]
        revealedID = try c.decodeIfPresent(String.self, forKey: .revealedID)
        revealedSlot = try c.decodeIfPresent(Int.self, forKey: .revealedSlot)
        lastAnswered = try c.decodeIfPresent(String.self, forKey: .lastAnswered)
        pendingRoute = try c.decodeIfPresent(String.self, forKey: .pendingRoute)
    }
}

// MARK: - Вся библиотека пользователя (один файл в App Group)

struct Library: Codable {
    var schema = 2
    var customCards: [Card] = []
    var deletedIDs: Set<String> = []          // удалённые встроенные и свои слова
    var progress: [String: CardProgress] = [:]
    var progressResetAt: Date = .distantPast
    var days: [String: DayStats] = [:]
    var settings = AppSettings()
    var widget = WidgetState()
    var migratedV1 = false
    var updatedAt = Date()

    enum CodingKeys: String, CodingKey {
        case schema, customCards, deletedIDs, progress, progressResetAt, days, settings, widget, migratedV1, updatedAt
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schema = try c.decodeIfPresent(Int.self, forKey: .schema) ?? 2
        customCards = try c.decodeIfPresent([Card].self, forKey: .customCards) ?? []
        deletedIDs = try c.decodeIfPresent(Set<String>.self, forKey: .deletedIDs) ?? []
        progress = try c.decodeIfPresent([String: CardProgress].self, forKey: .progress) ?? [:]
        progressResetAt = try c.decodeIfPresent(Date.self, forKey: .progressResetAt) ?? .distantPast
        days = try c.decodeIfPresent([String: DayStats].self, forKey: .days) ?? [:]
        settings = try c.decodeIfPresent(AppSettings.self, forKey: .settings) ?? AppSettings()
        widget = try c.decodeIfPresent(WidgetState.self, forKey: .widget) ?? WidgetState()
        migratedV1 = try c.decodeIfPresent(Bool.self, forKey: .migratedV1) ?? false
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

// MARK: - Вспомогательное

/// Детерминированный генератор для стабильного порядка слов.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

enum DayKey {
    static func key(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
