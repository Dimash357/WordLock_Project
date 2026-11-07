import SwiftUI
import Translation

/// Автоперевод на устройстве (Apple Translation, iOS 18+). Языковые модели система скачает по запросу.
@available(iOS 18.0, *)
struct AutoTranslateButton: View {
    let english: String
    let targetLanguage: String
    @Binding var result: String
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        Button {
            if configuration == nil {
                configuration = TranslationSession.Configuration(
                    source: Locale.Language(identifier: "en"),
                    target: Locale.Language(identifier: targetLanguage))
            } else {
                configuration?.invalidate()
            }
        } label: {
            Label("Перевести автоматически", systemImage: "translate")
        }
        .disabled(english.isEmpty)
        .translationTask(configuration) { session in
            do {
                let response = try await session.translate(english)
                result = response.targetText
            } catch {
                // Пользователь отменил загрузку модели или язык не поддерживается — ничего не делаем.
            }
        }
    }
}
