import SwiftUI
import WidgetKit

struct WordEntry: TimelineEntry {
    let date: Date
    let word: WordItem
}

struct WordProvider: TimelineProvider {
    func placeholder(in context: Context) -> WordEntry {
        WordEntry(date: .now, word: WordDefaults.words[0])
    }

    func getSnapshot(in context: Context, completion: @escaping (WordEntry) -> Void) {
        completion(WordEntry(date: .now, word: SharedWordStorage.currentWord()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> Void) {
        let entry = WordEntry(date: .now, word: SharedWordStorage.currentWord())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct WordLockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WordEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("\(entry.word.english) — \(entry.word.translation)")

        case .accessoryCircular:
            VStack(spacing: 0) {
                Text(entry.word.english.prefix(3).uppercased())
                    .font(.headline)
                Text(entry.word.translation.prefix(3))
                    .font(.caption2)
            }

        default:
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.word.english)
                        .font(.headline)
                        .lineLimit(1)
                    Text(entry.word.translation)
                        .font(.caption)
                        .lineLimit(1)
                }

                Spacer(minLength: 2)

                Button(intent: LearnWordIntent()) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Отметить как выученное")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct WordLockWidget: Widget {
    let kind = "WordLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordProvider()) { entry in
            WordLockWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Английское слово")
        .description("Показывает английское слово и его перевод.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

#Preview(as: .accessoryRectangular) {
    WordLockWidget()
} timeline: {
    WordEntry(date: .now, word: WordDefaults.words[0])
}
