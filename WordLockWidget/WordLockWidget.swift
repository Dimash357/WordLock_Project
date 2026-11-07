import AppIntents
import SwiftUI
import UIKit
import WidgetKit

// MARK: - Конфигурация виджета

struct WordWidgetConfig: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Настройки виджета"
    static let description = IntentDescription("Выбери колоду и режим карточки.")

    @Parameter(title: "Колода", default: .all) var deck: DeckChoice
    @Parameter(title: "Режим", default: .reveal) var mode: WidgetMode
}

// MARK: - Запись таймлайна

struct WordEntry: TimelineEntry {
    let date: Date
    let card: Card?
    let revealed: Bool
    let mode: WidgetMode
    let reviewsToday: Int
    let goal: Int

    var goalProgress: Double { min(Double(reviewsToday) / Double(max(goal, 1)), 1) }

    static var sample: WordEntry {
        WordEntry(date: Date(), card: BuiltInVocabulary.all.first, revealed: false, mode: .reveal, reviewsToday: 3, goal: 10)
    }
}

// MARK: - Провайдер

struct WordProvider: AppIntentTimelineProvider {
    typealias Entry = WordEntry
    typealias Intent = WordWidgetConfig

    func placeholder(in context: Context) -> WordEntry { .sample }

    func snapshot(for configuration: WordWidgetConfig, in context: Context) async -> WordEntry {
        if context.isPreview { return .sample }
        return build(configuration, now: Date()).first ?? .sample
    }

    func timeline(for configuration: WordWidgetConfig, in context: Context) async -> Timeline<WordEntry> {
        let now = Date()
        let entries = build(configuration, now: now)
        if entries.isEmpty {
            let empty = WordEntry(date: now, card: nil, revealed: false, mode: configuration.mode, reviewsToday: 0, goal: 10)
            return Timeline(entries: [empty], policy: .after(now.addingTimeInterval(3600)))
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    /// Библиотека читается и план обновляется один раз на весь таймлайн.
    private func build(_ configuration: WordWidgetConfig, now: Date) -> [WordEntry] {
        var picks: [WidgetPick] = []
        let lib = LibraryStore.shared.update { current in
            picks = WidgetPlanner.plan(lib: &current, deckKey: configuration.deck.rawValue,
                                       topic: configuration.deck.topic, now: now, count: 48)
        }
        let reviews = lib.days[DayKey.key(now)]?.reviews ?? 0
        return picks.map {
            WordEntry(date: $0.date, card: $0.card, revealed: $0.revealed, mode: configuration.mode,
                      reviewsToday: reviews, goal: lib.settings.dailyGoal)
        }
    }
}

// MARK: - Представление

struct WordLockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WordEntry

    private var showTranslation: Bool { entry.mode == .always || entry.revealed }

    var body: some View {
        Group {
            if let card = entry.card {
                content(card)
                    .widgetURL(DeepLink.card(card.id))
            } else {
                emptyView
            }
        }
        .containerBackground(for: .widget) { background }
    }

    @ViewBuilder
    private var background: some View {
        switch family {
        case .systemSmall, .systemMedium:
            Color(uiColor: .secondarySystemBackground)
        default:
            Rectangle().fill(.fill.tertiary)
        }
    }

    @ViewBuilder
    private func content(_ card: Card) -> some View {
        switch family {
        case .accessoryInline: inline(card)
        case .accessoryCircular: circular(card)
        case .accessoryRectangular: rectangular(card)
        case .systemMedium: medium(card)
        default: small(card)
        }
    }

    private var emptyView: some View {
        Text("Добавьте слова в приложении")
            .font(.caption)
            .multilineTextAlignment(.center)
    }

    // MARK: Экран блокировки

    private func inline(_ card: Card) -> some View {
        Text(verbatim: showTranslation ? "\(card.english) · \(card.translation)" : card.english)
    }

    private func circular(_ card: Card) -> some View {
        Gauge(value: entry.goalProgress) {
            EmptyView()
        } currentValueLabel: {
            Text(card.english)
                .font(.system(size: 12, weight: .semibold))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    private func rectangular(_ card: Card) -> some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(card.english).font(.headline).lineLimit(1).minimumScaleFactor(0.6)
                if showTranslation {
                    Text(card.translation).font(.caption).lineLimit(2).minimumScaleFactor(0.7)
                } else if let ipa = card.ipa {
                    Text(verbatim: "/\(ipa)/").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            controls(card, size: 22)
        }
    }

    // MARK: Домашний экран и StandBy

    private func small(_ card: Card) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.topic.title).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            Spacer(minLength: 0)
            Text(card.english).font(.title2.bold()).lineLimit(1).minimumScaleFactor(0.5)
            if let ipa = card.ipa {
                Text(verbatim: "/\(ipa)/").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Text(verbatim: showTranslation ? card.translation : " ")
                .font(.subheadline).lineLimit(2).minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            controls(card, size: 26)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func medium(_ card: Card) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.topic.title).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                Spacer(minLength: 0)
                Text(card.english).font(.largeTitle.bold()).lineLimit(1).minimumScaleFactor(0.5)
                if let ipa = card.ipa {
                    Text(verbatim: "/\(ipa)/").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                if showTranslation {
                    Text(card.translation).font(.title3).lineLimit(2).minimumScaleFactor(0.7)
                    if let example = card.example {
                        Text(example).font(.caption).italic().foregroundStyle(.secondary).lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            controls(card, size: 30)
        }
    }

    // MARK: Кнопки

    @ViewBuilder
    private func controls(_ card: Card, size: CGFloat) -> some View {
        if entry.mode == .reveal && !entry.revealed {
            Button(intent: RevealCardIntent(cardID: card.id)) {
                Image(systemName: "eye.fill").font(.system(size: size))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Показать перевод")
        } else {
            HStack(spacing: size * 0.5) {
                Button(intent: AnswerCardIntent(cardID: card.id, known: false)) {
                    Image(systemName: "arrow.counterclockwise.circle").font(.system(size: size))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Не знал")
                Button(intent: AnswerCardIntent(cardID: card.id, known: true)) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: size))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Знал")
            }
        }
    }
}

// MARK: - Виджет и пакет

struct WordLockWidget: Widget {
    let kind = "WordLockWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WordWidgetConfig.self, provider: WordProvider()) { entry in
            WordLockWidgetView(entry: entry)
        }
        .configurationDisplayName("Слово")
        .description("Карточка с английским словом: смотри, вспоминай, отвечай прямо на экране.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular, .systemSmall, .systemMedium])
    }
}

@available(iOS 18.0, *)
struct TrainingControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.katsuro.WordLock.training") {
            ControlWidgetButton(action: OpenTrainingIntent()) {
                Label("Тренировка", systemImage: "rectangle.on.rectangle.angled")
            }
        }
        .displayName("Тренировка WordLock")
        .description("Открыть повторение слов.")
    }
}

@main
struct WordLockWidgetBundle: WidgetBundle {
    var body: some Widget {
        WordLockWidget()
        if #available(iOS 18.0, *) {
            TrainingControl()
        }
    }
}
