import SwiftUI

struct TodayView: View {
    @EnvironmentObject var model: AppModel

    private var goal: Int { max(model.lib.settings.dailyGoal, 1) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    startCard
                    modes
                    weekChart
                    deckProgress
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Сегодня")
        }
    }

    // MARK: Блоки

    private var header: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle().stroke(Color.accentColor.opacity(0.15), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: min(Double(model.todayReviews) / Double(goal), 1))
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: model.todayReviews)
                VStack(spacing: 0) {
                    Text(verbatim: "\(model.todayReviews)").font(.title.bold().monospacedDigit())
                    Text(verbatim: "/ \(goal)").font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Цель на сегодня")
            .accessibilityValue("\(model.todayReviews) из \(goal)")

            VStack(alignment: .leading, spacing: 10) {
                Label {
                    Text("Серия: \(model.streak)")
                } icon: {
                    Image(systemName: "flame.fill").foregroundStyle(.orange)
                }
                .font(.headline)
                Label {
                    Text("К повторению: \(model.dueCount)")
                } icon: {
                    Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(Color.accentColor)
                }
                Label {
                    Text("Выучено: \(model.learnedCount)")
                } icon: {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                }
            }
            .font(.subheadline)
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var startCard: some View {
        Button {
            model.session = .flashcards
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.dueCount > 0 ? LocalizedStringKey("Начать повторение") : LocalizedStringKey("Учить новые слова"))
                        .font(.headline)
                    Text(model.dueCount > 0 ? LocalizedStringKey("Слова, которые пора повторить") : LocalizedStringKey("На сегодня повторов нет"))
                        .font(.caption)
                        .opacity(0.85)
                }
                Spacer()
                Image(systemName: "play.fill").font(.title2)
            }
            .foregroundStyle(.white)
            .padding()
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .disabled(model.catalog.cards.isEmpty)
    }

    private var modes: some View {
        HStack(spacing: 12) {
            modeButton("Карточки", "rectangle.on.rectangle.angled", .flashcards)
            modeButton("Тест", "list.bullet.rectangle", .quiz)
            modeButton("Ввод", "keyboard", .typing)
        }
    }

    private func modeButton(_ title: LocalizedStringKey, _ icon: String, _ kind: SessionKind) -> some View {
        Button {
            model.session = kind
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(model.catalog.cards.isEmpty)
    }

    private var weekChart: some View {
        let days = model.week
        let maxValue = max(days.map { $0.reviews }.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Неделя").font(.headline)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 6) {
                        Text(verbatim: "\(day.reviews)").font(.caption2).foregroundStyle(.secondary)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(day.reviews > 0 ? Color.accentColor : Color.secondary.opacity(0.2))
                            .frame(height: max(6, CGFloat(day.reviews) / CGFloat(maxValue) * 70))
                        Text(day.date.formatted(.dateTime.weekday(.narrow))).font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110, alignment: .bottom)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var deckProgress: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Общий прогресс").font(.headline)
                Spacer()
                Text(verbatim: "\(model.learnedCount) / \(model.totalCount)").font(.subheadline.monospacedDigit())
            }
            ProgressView(value: Double(model.learnedCount), total: Double(max(model.totalCount, 1)))
            Button {
                model.showOnboarding = true
            } label: {
                Label("Как добавить виджет на экран блокировки", systemImage: "lock.iphone")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}
