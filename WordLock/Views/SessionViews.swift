import SwiftUI

// MARK: - Контейнер сессии

struct SessionContainer: View {
    let kind: SessionKind
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var cards: [Card] = []
    @State private var loaded = false
    @State private var finished = false
    @State private var knownCount = 0
    @State private var total = 0

    private var title: LocalizedStringKey {
        switch kind {
        case .flashcards: return "Карточки"
        case .quiz: return "Тест"
        case .typing: return "Ввод слова"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if !loaded {
                    ProgressView()
                } else if cards.isEmpty {
                    ContentUnavailableView("Нет слов для повторения", systemImage: "tray",
                                           description: Text("Добавь слова в словарь."))
                } else if finished {
                    SummaryView(known: knownCount, total: total, onClose: close)
                } else {
                    switch kind {
                    case .flashcards:
                        FlashcardSession(cards: cards, onAnswer: record, onFinish: finish)
                    case .quiz:
                        QuizSession(cards: cards, translations: model.catalog.cards.map(\.translation),
                                    onAnswer: record, onFinish: finish)
                    case .typing:
                        TypingSession(cards: cards, onAnswer: record, onFinish: finish)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { close() }
                }
            }
        }
        .onAppear {
            if !loaded {
                cards = model.sessionCards()
                loaded = true
            }
        }
    }

    private func record(_ card: Card, _ known: Bool) {
        model.answer(card, known: known)
        total += 1
        if known { knownCount += 1 }
    }

    private func finish() {
        model.finishSession()
        finished = true
    }

    private func close() {
        model.finishSession()
        dismiss()
    }
}

struct SummaryView: View {
    let known: Int
    let total: Int
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "party.popper.fill").font(.system(size: 64)).foregroundStyle(.orange)
            Text("Отлично!").font(.largeTitle.bold())
            Text("Знал: \(known) из \(total)").font(.title3)
            Text("Слова, которые ты не знал, вернутся в повторение уже скоро.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: onClose) {
                Text("Готово").font(.headline).frame(maxWidth: .infinity).padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }
}

// MARK: - Карточки со свайпом

struct FlashcardSession: View {
    let cards: [Card]
    let onAnswer: (Card, Bool) -> Void
    let onFinish: () -> Void
    @EnvironmentObject var model: AppModel
    @State private var index = 0
    @State private var flipped = false
    @State private var drag: CGSize = .zero
    @State private var busy = false

    var body: some View {
        let card = cards[min(index, cards.count - 1)]
        VStack(spacing: 20) {
            ProgressView(value: Double(index), total: Double(cards.count)).padding(.horizontal)
            Spacer(minLength: 0)

            cardFace(card)
                .offset(x: drag.width)
                .rotationEffect(.degrees(Double(drag.width) / 25))
                .gesture(
                    DragGesture()
                        .onChanged { drag = CGSize(width: $0.translation.width, height: 0) }
                        .onEnded { value in
                            if value.translation.width > 110 { answer(true) }
                            else if value.translation.width < -110 { answer(false) }
                            else { withAnimation(.spring()) { drag = .zero } }
                        }
                )
                .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { flipped.toggle() } }

            Text("Нажми на карточку, чтобы увидеть перевод. Свайп вправо — знаю, влево — повторить.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer(minLength: 0)

            HStack(spacing: 16) {
                answerButton("Повторить", "arrow.counterclockwise", .orange) { answer(false) }
                answerButton("Знаю", "checkmark", .green) { answer(true) }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func cardFace(_ card: Card) -> some View {
        let tint: Color = drag.width > 0 ? .green : .orange
        return VStack(spacing: 14) {
            if !flipped {
                Text(card.english).font(.system(size: 40, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5).lineLimit(1)
                if let ipa = card.ipa {
                    Text(verbatim: "/\(ipa)/").font(.title3).foregroundStyle(.secondary)
                }
                speakButton(card.english)
            } else {
                Text(card.english).font(.title3).foregroundStyle(.secondary)
                Text(card.translation).font(.system(size: 34, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center).minimumScaleFactor(0.5)
                if let example = card.example {
                    Text(example).font(.body).italic().multilineTextAlignment(.center)
                        .foregroundStyle(.secondary).padding(.top, 6)
                    speakButton(example)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).fill(tint.opacity(min(Double(abs(drag.width)) / 400, 0.35))))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Нажми дважды, чтобы перевернуть")
    }

    private func speakButton(_ text: String) -> some View {
        Button { model.speak(text) } label: {
            Image(systemName: "speaker.wave.2.fill").font(.title2).padding(10)
        }
        .accessibilityLabel("Произнести")
    }

    private func answerButton(_ title: LocalizedStringKey, _ icon: String, _ color: Color,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon).font(.headline)
                .frame(maxWidth: .infinity).padding()
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(color)
        }
        .disabled(busy)
    }

    private func answer(_ known: Bool) {
        guard !busy else { return }
        busy = true
        let card = cards[index]
        withAnimation(.easeIn(duration: 0.15)) { drag = CGSize(width: known ? 600 : -600, height: 0) }
        onAnswer(card, known)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 160_000_000)
            flipped = false
            drag = .zero
            if index + 1 < cards.count { index += 1; busy = false } else { onFinish() }
        }
    }
}

// MARK: - Тест с вариантами

struct QuizSession: View {
    let cards: [Card]
    let translations: [String]
    let onAnswer: (Card, Bool) -> Void
    let onFinish: () -> Void
    @EnvironmentObject var model: AppModel
    @State private var index = 0
    @State private var options: [String] = []
    @State private var selected: String?

    var body: some View {
        let card = cards[min(index, cards.count - 1)]
        VStack(spacing: 18) {
            ProgressView(value: Double(index), total: Double(cards.count)).padding(.horizontal)
            VStack(spacing: 8) {
                Text(card.english).font(.system(size: 38, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5).lineLimit(1)
                if let ipa = card.ipa { Text(verbatim: "/\(ipa)/").foregroundStyle(.secondary) }
                Button { model.speak(card.english) } label: {
                    Image(systemName: "speaker.wave.2.fill").font(.title3)
                }
                .accessibilityLabel("Произнести")
            }
            .padding(.top, 8)

            VStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    Button { choose(option, card) } label: {
                        HStack {
                            Text(option).font(.headline).multilineTextAlignment(.leading)
                            Spacer()
                            if let selected {
                                if option == card.translation {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                } else if option == selected {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(background(for: option, card), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(selected != nil)
                }
            }
            .padding(.horizontal)
            Spacer()
        }
        .onAppear { makeOptions() }
        .onChange(of: index) { _, _ in makeOptions() }
    }

    private func background(for option: String, _ card: Card) -> Color {
        guard let selected else { return Color(uiColor: .secondarySystemGroupedBackground) }
        if option == card.translation { return Color.green.opacity(0.25) }
        if option == selected { return Color.red.opacity(0.25) }
        return Color(uiColor: .secondarySystemGroupedBackground)
    }

    private func makeOptions() {
        let card = cards[min(index, cards.count - 1)]
        var set = [card.translation]
        for t in translations.shuffled() where !set.contains(t) {
            set.append(t)
            if set.count == 4 { break }
        }
        options = set.shuffled()
        selected = nil
    }

    private func choose(_ option: String, _ card: Card) {
        selected = option
        let correct = option == card.translation
        onAnswer(card, correct)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: correct ? 700_000_000 : 1_400_000_000)
            if index + 1 < cards.count { index += 1 } else { onFinish() }
        }
    }
}

// MARK: - Ввод слова с клавиатуры

struct TypingSession: View {
    enum Phase { case asking, correct, wrong }

    let cards: [Card]
    let onAnswer: (Card, Bool) -> Void
    let onFinish: () -> Void
    @EnvironmentObject var model: AppModel
    @State private var index = 0
    @State private var input = ""
    @State private var phase: Phase = .asking
    @FocusState private var focused: Bool

    var body: some View {
        let card = cards[min(index, cards.count - 1)]
        VStack(spacing: 18) {
            ProgressView(value: Double(index), total: Double(cards.count)).padding(.horizontal)
            Text("Напиши по-английски").font(.subheadline).foregroundStyle(.secondary)
            Text(card.translation).font(.system(size: 34, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center).minimumScaleFactor(0.5).padding(.horizontal)

            if let example = card.example {
                Text(blanked(example, word: card.english))
                    .font(.callout).italic().foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }

            TextField("English", text: $input)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .focused($focused)
                .disabled(phase != .asking)
                .submitLabel(.done)
                .onSubmit { check(card) }
                .padding(.horizontal, 32)

            switch phase {
            case .asking:
                HStack(spacing: 12) {
                    Button("Не помню") { reveal(card) }.buttonStyle(.bordered)
                    Button("Проверить") { check(card) }
                        .buttonStyle(.borderedProminent)
                        .disabled(input.trimmed.isEmpty)
                }
            case .correct:
                resultView(card, correct: true)
            case .wrong:
                resultView(card, correct: false)
            }
            Spacer()
        }
        .onAppear { focused = true }
    }

    private func resultView(_ card: Card, correct: Bool) -> some View {
        VStack(spacing: 10) {
            Label(correct ? LocalizedStringKey("Верно!") : LocalizedStringKey("Правильный ответ:"),
                  systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline)
                .foregroundStyle(correct ? .green : .red)
            if !correct {
                Text(card.english).font(.title2.bold())
                if let ipa = card.ipa { Text(verbatim: "/\(ipa)/").foregroundStyle(.secondary) }
            }
            HStack(spacing: 12) {
                Button { model.speak(card.english) } label: { Image(systemName: "speaker.wave.2.fill") }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Произнести")
                Button("Дальше") { next() }.buttonStyle(.borderedProminent)
            }
        }
    }

    private func blanked(_ example: String, word: String) -> String {
        example.replacingOccurrences(of: word, with: "_____", options: .caseInsensitive)
    }

    private func check(_ card: Card) {
        guard phase == .asking, !input.trimmed.isEmpty else { return }
        let ok = input.trimmed.lowercased() == card.english.trimmed.lowercased()
        phase = ok ? .correct : .wrong
        onAnswer(card, ok)
        focused = false
    }

    private func reveal(_ card: Card) {
        guard phase == .asking else { return }
        phase = .wrong
        onAnswer(card, false)
        focused = false
    }

    private func next() {
        if index + 1 < cards.count {
            index += 1
            input = ""
            phase = .asking
            focused = true
        } else {
            onFinish()
        }
    }
}
