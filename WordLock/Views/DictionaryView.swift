import SwiftUI

enum StatusFilter: String, CaseIterable, Identifiable {
    case all, new, learning, learned
    var id: String { rawValue }
    var title: LocalizedStringKey {
        switch self {
        case .all: return "Все"
        case .new: return "Новые"
        case .learning: return "В изучении"
        case .learned: return "Выученные"
        }
    }
}

struct DictionaryView: View {
    @EnvironmentObject var model: AppModel
    @State private var search = ""
    @State private var topicFilter: Topic?
    @State private var statusFilter: StatusFilter = .all
    @State private var showAdd = false

    private var filtered: [Card] {
        model.catalog.cards.filter { card in
            if let topicFilter, card.topic != topicFilter { return false }
            let progress = model.progress(for: card.id)
            switch statusFilter {
            case .all: break
            case .new: if progress != nil { return false }
            case .learning: if progress == nil || progress!.isLearned { return false }
            case .learned: if progress?.isLearned != true { return false }
            }
            if search.isEmpty { return true }
            return card.english.localizedCaseInsensitiveContains(search)
                || card.translation.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { card in
                    Button { model.cardRef = CardRef(id: card.id) } label: { row(card) }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { model.delete(card.id) } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button { model.toggleLearned(card.id) } label: {
                                Label(model.progress(for: card.id)?.isLearned == true ? LocalizedStringKey("В изучение") : LocalizedStringKey("Выучено"),
                                      systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                }
            }
            .listStyle(.plain)
            .overlay {
                if filtered.isEmpty {
                    ContentUnavailableView.search
                }
            }
            .searchable(text: $search, prompt: "Найти слово или перевод")
            .navigationTitle("Словарь")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { filterMenu }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Добавить слово")
                }
            }
            .sheet(isPresented: $showAdd) { AddWordView() }
        }
    }

    private var filterMenu: some View {
        Menu {
            Picker("Статус", selection: $statusFilter) {
                ForEach(StatusFilter.allCases) { Text($0.title).tag($0) }
            }
            Picker("Колода", selection: $topicFilter) {
                Text("Все колоды").tag(Topic?.none)
                ForEach(Topic.allCases) { topic in
                    Label(topic.title, systemImage: topic.symbol).tag(Topic?.some(topic))
                }
            }
        } label: {
            Image(systemName: (topicFilter != nil || statusFilter != .all)
                  ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Фильтры")
    }

    private func row(_ card: Card) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(card.english).font(.headline)
                Text(card.translation).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            statusIcon(model.progress(for: card.id))
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func statusIcon(_ progress: CardProgress?) -> some View {
        if let progress {
            if progress.isLearned {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            } else {
                Image(systemName: "circle.lefthalf.filled").foregroundStyle(.orange)
            }
        } else {
            Image(systemName: "circle").foregroundStyle(.secondary)
        }
    }
}

// MARK: - Детали карточки

struct CardDetailView: View {
    let cardID: String
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            if let card = model.catalog.byID[cardID] {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(card.english).font(.system(size: 36, weight: .bold, design: .rounded))
                            if let ipa = card.ipa { Text(verbatim: "/\(ipa)/").font(.title3).foregroundStyle(.secondary) }
                            Text(card.translation).font(.title2)
                        }
                        .padding(.vertical, 6)
                        HStack(spacing: 12) {
                            Button { model.speak(card.english) } label: { Label("Слово", systemImage: "speaker.wave.2.fill") }
                            if let example = card.example {
                                Button { model.speak(example) } label: { Label("Пример", systemImage: "text.bubble.fill") }
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    if let example = card.example {
                        Section("Пример") { Text(example).italic() }
                    }

                    Section("Прогресс") {
                        LabeledContent("Колода") { Label(card.topic.title, systemImage: card.topic.symbol) }
                        if let p = model.progress(for: card.id) {
                            LabeledContent("Коробка") {
                                HStack(spacing: 4) {
                                    ForEach(1...5, id: \.self) { i in
                                        Circle().fill(i <= p.box ? Color.accentColor : Color.secondary.opacity(0.25))
                                            .frame(width: 10, height: 10)
                                    }
                                }
                            }
                            LabeledContent("Следующее повторение") {
                                Text(p.due, format: .dateTime.day().month().hour().minute())
                            }
                            LabeledContent("Верно / ошибок") { Text(verbatim: "\(p.correct) / \(p.wrong)") }
                        } else {
                            Text("Слово ещё не изучалось").foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        Button {
                            model.toggleLearned(card.id)
                        } label: {
                            Label(model.progress(for: card.id)?.isLearned == true ? LocalizedStringKey("Вернуть в изучение") : LocalizedStringKey("Отметить выученным"),
                                  systemImage: "checkmark.circle")
                        }
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label("Удалить слово", systemImage: "trash")
                        }
                    }
                }
                .navigationTitle(card.english)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
                .confirmationDialog("Удалить слово?", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("Удалить", role: .destructive) { model.delete(card.id); dismiss() }
                } message: {
                    Text("Встроенные слова можно вернуть в настройках.")
                }
            } else {
                ContentUnavailableView("Слово не найдено", systemImage: "questionmark.circle")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
            }
        }
    }
}

// MARK: - Добавление слова

struct AddWordView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var english = ""
    @State private var translation = ""
    @State private var example = ""

    private var duplicate: Card? {
        english.trimmed.isEmpty ? nil : model.catalog.contains(english: english)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("English", text: $english)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if let duplicate {
                        Label {
                            Text("Уже есть: \(duplicate.translation)")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        }
                        .font(.footnote)
                    }
                    TextField("Перевод", text: $translation)
                    if #available(iOS 18.0, *) {
                        AutoTranslateButton(english: english.trimmed,
                                            targetLanguage: model.lib.settings.translateTo,
                                            result: $translation)
                    }
                }
                Section("Пример (необязательно)") {
                    TextField("Предложение с этим словом", text: $example, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                }
            }
            .navigationTitle("Новое слово")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        if model.addCard(english: english, translation: translation, example: example) { dismiss() }
                    }
                    .disabled(english.trimmed.isEmpty || translation.trimmed.isEmpty || duplicate != nil)
                }
            }
        }
    }
}
