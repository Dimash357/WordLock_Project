import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    introPage.tag(0)
                    demoPage.tag(1)
                    addWidgetPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if page < 2 { withAnimation { page += 1 } } else { onFinish() }
                } label: {
                    Text(page < 2 ? LocalizedStringKey("Дальше") : LocalizedStringKey("Начать"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)

                Button("Пропустить") { onFinish() }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)
                    .opacity(page < 2 ? 1 : 0)
            }
        }
    }

    // MARK: Страницы

    private var introPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "lock.rectangle.stack.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)
            Text("Английский на экране блокировки").font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text("Каждый раз, когда ты берёшь телефон, перед глазами новое слово. Пара секунд — и оно запомнится.")
                .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var demoPage: some View {
        VStack(spacing: 20) {
            Spacer()
            LockScreenDemo()
            Text("Учись прямо на виджете").font(.title.bold()).multilineTextAlignment(.center)
            Text("Посмотри на слово, вспомни перевод, нажми глаз и ответь: «Знал» или «Не знал». Приложение само вернёт слово тогда, когда пора его повторить.")
                .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var addWidgetPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Text("Как добавить виджет").font(.title.bold()).frame(maxWidth: .infinity, alignment: .center)
            step(1, "lock.iphone", "Заблокируй iPhone и разбуди его, не разблокируя")
            step(2, "hand.tap.fill", "Нажми и удерживай экран блокировки, затем «Настроить»")
            step(3, "plus.rectangle.on.rectangle", "Нажми на область под часами и выбери WordLock")
            step(4, "checkmark.circle.fill", "Выбери размер: прямоугольный лучше всего подходит для обучения")
            Text("Виджет также доступен на домашнем экране и в режиме StandBy.")
                .font(.footnote).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func step(_ number: Int, _ icon: String, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: icon).foregroundStyle(Color.accentColor)
            }
            Text(text).font(.subheadline)
            Spacer(minLength: 0)
        }
    }
}

/// Анимированная заглушка виджета: слово → перевод → ответ → следующее слово.
struct LockScreenDemo: View {
    @State private var phase = 0
    private let words = [("ability", "способность"), ("abroad", "за границей")]

    private var word: (String, String) { words[phase / 3 % words.count] }
    private var step: Int { phase % 3 }

    var body: some View {
        VStack(spacing: 10) {
            Text(verbatim: "9:41").font(.system(size: 54, weight: .thin, design: .rounded)).foregroundStyle(.white)
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(word.0).font(.headline).foregroundStyle(.white)
                    Text(step == 0 ? "• • •" : word.1).font(.caption).foregroundStyle(.white.opacity(0.8))
                }
                Spacer(minLength: 0)
                if step == 0 {
                    Image(systemName: "eye.fill").font(.title3).foregroundStyle(.white)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise.circle").font(.title3).foregroundStyle(.white.opacity(0.7))
                        Image(systemName: "checkmark.circle.fill").font(.title3)
                            .foregroundStyle(step == 2 ? Color.green : .white)
                            .scaleEffect(step == 2 ? 1.25 : 1)
                    }
                }
            }
            .padding(12)
            .frame(width: 200)
            .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 36)
        .background(
            LinearGradient(colors: [Color.indigo, Color.blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 28))
        .animation(.spring(duration: 0.4), value: phase)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                phase += 1
            }
        }
        .accessibilityHidden(true)
    }
}
