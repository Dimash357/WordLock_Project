import SwiftUI

struct ContentView: View {
    @StateObject private var store = WordStore()
    @State private var english = ""
    @State private var translation = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Добавить слово") {
                    TextField("English word", text: $english)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Перевод", text: $translation)

                    Button("Добавить") {
                        store.add(english: english, translation: translation)
                        english = ""
                        translation = ""
                    }
                    .disabled(
                        english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }

                Section("Мои слова") {
                    ForEach(store.words) { word in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(word.english)
                                .font(.headline)
                            Text(word.translation)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: store.delete)
                }

                Section {
                    Button("Вернуть стандартные слова") {
                        store.restoreDefaults()
                    }
                }
            }
            .navigationTitle("WordLock")
            .toolbar { EditButton() }
        }
    }
}

#Preview {
    ContentView()
}
