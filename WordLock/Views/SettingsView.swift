import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @State private var confirmReset = false
    @State private var confirmRestore = false
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var exportDocument = CSVDocument(text: "")
    @State private var importedCount: Int?
    @State private var notificationsDenied = false

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents()
                c.hour = model.lib.settings.reminderHour
                c.minute = model.lib.settings.reminderMinute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                model.mutate(widgets: false) {
                    $0.settings.reminderHour = c.hour ?? 19
                    $0.settings.reminderMinute = c.minute ?? 0
                }
                Reminders.reschedule(model.lib)
            })
    }

    private var reminderToggle: Binding<Bool> {
        Binding(
            get: { model.lib.settings.reminderEnabled },
            set: { on in
                if on {
                    Task { @MainActor in
                        let granted = await Reminders.requestAuthorization()
                        notificationsDenied = !granted
                        model.mutate(widgets: false) { $0.settings.reminderEnabled = granted }
                        Reminders.reschedule(model.lib)
                    }
                } else {
                    model.mutate(widgets: false) { $0.settings.reminderEnabled = false }
                    Reminders.reschedule(model.lib)
                }
            })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Смена карточки", selection: model.binding(\.rotationMinutes)) {
                        Text("15 минут").tag(15)
                        Text("30 минут").tag(30)
                        Text("1 час").tag(60)
                        Text("2 часа").tag(120)
                        Text("4 часа").tag(240)
                    }
                    Button { model.showOnboarding = true } label: {
                        Label("Как добавить виджет", systemImage: "lock.iphone")
                    }
                } header: {
                    Text("Виджет")
                } footer: {
                    Text("Время обновления приблизительное: iOS сама решает, когда перерисовывать виджеты. Режим и колоду можно выбрать для каждого виджета отдельно: удерживай виджет → «Изменить».")
                }

                Section {
                    ForEach(Topic.selectable) { topic in
                        Toggle(isOn: Binding(get: { model.isTopicEnabled(topic) },
                                             set: { model.toggleTopic(topic, enabled: $0) })) {
                            Label(topic.title, systemImage: topic.symbol)
                        }
                    }
                } header: {
                    Text("Колоды")
                } footer: {
                    Text("Выбранные колоды используются в тренировке и в виджетах с режимом «Все включённые колоды».")
                }

                Section("Обучение") {
                    Stepper(value: model.binding(\.dailyGoal), in: 5...100, step: 5) {
                        Text("Цель на день: \(model.lib.settings.dailyGoal)")
                    }
                    Picker("Произношение", selection: model.binding(\.accent)) {
                        Text("Американское").tag("en-US")
                        Text("Британское").tag("en-GB")
                    }
                    Picker("Автоперевод на", selection: model.binding(\.translateTo)) {
                        Text("Русский").tag("ru")
                        Text("Українська").tag("uk")
                        Text("English").tag("en")
                        Text("Español").tag("es")
                        Text("Türkçe").tag("tr")
                        Text("Deutsch").tag("de")
                    }
                }

                Section {
                    Toggle("Ежедневное напоминание", isOn: reminderToggle)
                    if model.lib.settings.reminderEnabled {
                        DatePicker("Время", selection: reminderTime, displayedComponents: .hourAndMinute)
                    }
                    if notificationsDenied {
                        Text("Уведомления выключены в настройках iPhone.").font(.footnote).foregroundStyle(.red)
                    }
                } header: {
                    Text("Напоминания")
                } footer: {
                    Text("Если за день ты уже повторял слова, напоминание в этот день не придёт.")
                }

                Section {
                    Button { showImporter = true } label: { Label("Импорт из CSV / Anki", systemImage: "square.and.arrow.down") }
                    Button {
                        exportDocument = CSVDocument(text: model.exportCSV())
                        showExporter = true
                    } label: { Label("Экспорт в CSV", systemImage: "square.and.arrow.up") }
                } header: {
                    Text("Данные")
                } footer: {
                    Text("Формат: английское слово, перевод, пример (по желанию). Разделитель — запятая, точка с запятой или табуляция. Файлы из Anki («Notes in Plain Text») подходят.")
                }

                Section {
                    Button("Сбросить прогресс", role: .destructive) { confirmReset = true }
                    Button("Вернуть удалённые слова") { confirmRestore = true }
                } footer: {
                    Text("Прогресс и свои слова синхронизируются через iCloud, если ты вошёл в него на устройстве.")
                }

                Section("О приложении") {
                    LabeledContent("Версия") {
                        Text(verbatim: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                    }
                    Text("WordLock не собирает персональные данные и не содержит рекламы.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Настройки")
            .confirmationDialog("Сбросить весь прогресс?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Сбросить", role: .destructive) { model.resetProgress() }
            } message: {
                Text("Все слова снова станут новыми. Отменить это нельзя.")
            }
            .confirmationDialog("Вернуть удалённые слова?", isPresented: $confirmRestore, titleVisibility: .visible) {
                Button("Вернуть") { model.restoreDefaultWords() }
            } message: {
                Text("Встроенные слова, которые ты удалил, снова появятся в словаре.")
            }
            .fileImporter(isPresented: $showImporter,
                          allowedContentTypes: [.commaSeparatedText, .tabSeparatedText, .plainText]) { result in
                guard case .success(let url) = result else { return }
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                guard let data = try? Data(contentsOf: url) else { return }
                let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .windowsCP1251) ?? ""
                importedCount = model.importCSV(text)
            }
            .fileExporter(isPresented: $showExporter, document: exportDocument,
                          contentType: .commaSeparatedText, defaultFilename: "WordLock") { _ in }
            .alert("Импорт завершён", isPresented: Binding(get: { importedCount != nil },
                                                          set: { if !$0 { importedCount = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Добавлено слов: \(importedCount ?? 0)")
            }
        }
    }
}
