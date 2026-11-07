import SwiftUI
import UIKit
import UniformTypeIdentifiers
import WidgetKit

/// «Поделиться» → WordLock: добавляет выделенное слово в «Мои слова» из Safari и других приложений.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSharedText { [weak self] text in
            guard let self else { return }
            let root = ShareView(initialText: text) { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            }
            let host = UIHostingController(rootView: root)
            self.addChild(host)
            host.view.frame = self.view.bounds
            host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(host.view)
            host.didMove(toParent: self)
        }
    }

    private func loadSharedText(_ done: @escaping (String) -> Void) {
        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        let providers = items.flatMap { $0.attachments ?? [] }
        let type = UTType.plainText.identifier
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(type) }) else {
            done("")
            return
        }
        provider.loadItem(forTypeIdentifier: type, options: nil) { item, _ in
            DispatchQueue.main.async { done((item as? String) ?? "") }
        }
    }
}

struct ShareView: View {
    let initialText: String
    let onClose: () -> Void
    @State private var english: String
    @State private var translation = ""
    @State private var example = ""

    init(initialText: String, onClose: @escaping () -> Void) {
        self.initialText = initialText
        self.onClose = onClose
        let firstLine = initialText.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        _english = State(initialValue: String(firstLine.trimmed.prefix(60)))
    }

    private var duplicate: Bool {
        Catalog(LibraryStore.shared.read()).contains(english: english) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("English", text: $english).autocorrectionDisabled().textInputAutocapitalization(.never)
                    TextField("Перевод", text: $translation)
                    TextField("Пример (необязательно)", text: $example)
                }
                if duplicate {
                    Text("Такое слово уже есть в словаре.").font(.footnote).foregroundStyle(.orange)
                }
            }
            .navigationTitle("Добавить в WordLock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена", action: onClose) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") { save() }
                        .disabled(english.trimmed.isEmpty || translation.trimmed.isEmpty || duplicate)
                }
            }
        }
    }

    private func save() {
        let card = Card(id: "c:" + UUID().uuidString, english: english.trimmed, translation: translation.trimmed,
                        ipa: nil, example: example.trimmed.isEmpty ? nil : example.trimmed,
                        topic: .custom, isCustom: true, addedAt: Date())
        LibraryStore.shared.update { $0.customCards.append(card) }
        WidgetCenter.shared.reloadAllTimelines()
        onClose()
    }
}
