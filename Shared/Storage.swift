import Foundation

/// Хранилище: один JSON-файл в контейнере App Group.
/// Общий для приложения, виджета и Share Extension.
final class LibraryStore {
    static let shared = LibraryStore()

    private let lock = NSLock()
    private var cached: Library?
    private var cachedStamp: Date?

    private var fileURL: URL {
        let fm = FileManager.default
        if let base = fm.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.id) {
            return base.appendingPathComponent("library.json")
        }
        // Запасной вариант (например, при неверной подписи) — приложение не падает.
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("library.json")
    }

    func read() -> Library {
        lock.lock(); defer { lock.unlock() }
        return loadLocked()
    }

    /// Прочитать → изменить → записать. Возвращает новое состояние.
    @discardableResult
    func update(_ body: (inout Library) -> Void) -> Library {
        lock.lock(); defer { lock.unlock() }
        var lib = loadLocked()
        body(&lib)
        lib.updatedAt = Date()
        saveLocked(lib)
        return lib
    }

    // MARK: Private

    private func modificationDate(_ url: URL) -> Date? {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attrs?[.modificationDate] as? Date
    }

    private func loadLocked() -> Library {
        let url = fileURL
        let stamp = modificationDate(url)
        if let cached, let stamp, stamp == cachedStamp { return cached }

        let decoder = JSONDecoder()
        if let data = try? Data(contentsOf: url), let lib = try? decoder.decode(Library.self, from: data) {
            cached = lib
            cachedStamp = stamp
            return lib
        }
        // Файл повреждён — пробуем резервную копию.
        let backup = url.appendingPathExtension("bak")
        if let data = try? Data(contentsOf: backup), let lib = try? decoder.decode(Library.self, from: data) {
            saveLocked(lib)
            return lib
        }
        // Первый запуск (или обновление со старой версии): переносим старые данные.
        var lib = Library()
        LegacyMigration.apply(to: &lib)
        saveLocked(lib)
        return lib
    }

    private func saveLocked(_ lib: Library) {
        let url = fileURL
        let fm = FileManager.default
        guard let data = try? JSONEncoder().encode(lib) else { return }
        if fm.fileExists(atPath: url.path) {
            let backup = url.appendingPathExtension("bak")
            try? fm.removeItem(at: backup)
            try? fm.copyItem(at: url, to: backup)
        }
        do {
            try data.write(to: url, options: .atomic)
            cached = lib
            cachedStamp = modificationDate(url)
        } catch {
            cached = nil
            cachedStamp = nil
        }
    }
}

// MARK: - Перенос данных из версии 1 (UserDefaults)

enum LegacyMigration {
    private struct LegacyWord: Codable {
        var english: String
        var translation: String
    }

    static func apply(to lib: inout Library) {
        lib.migratedV1 = true
        guard let d = UserDefaults(suiteName: AppGroup.id) else { return }
        let now = Date()

        // Настройки
        let minutes = d.integer(forKey: "rotationMinutes")
        if AppSettings.rotationOptions.contains(minutes) { lib.settings.rotationMinutes = minutes }

        // Слова
        let saved: [LegacyWord] = d.data(forKey: "savedWords")
            .flatMap { try? JSONDecoder().decode([LegacyWord].self, from: $0) } ?? []
        let builtIn = BuiltInVocabulary.all
        let builtInByKey = Dictionary(builtIn.map { ($0.english.lowercased(), $0) }, uniquingKeysWith: { a, _ in a })

        if !saved.isEmpty {
            let savedKeys = Set(saved.map { $0.english.trimmed.lowercased() })
            // Удалённые пользователем встроенные слова считаем только если старый словарь уже был полным.
            if d.integer(forKey: "vocabularyVersion") >= 2 {
                for card in builtIn where !savedKeys.contains(card.english.lowercased()) {
                    lib.deletedIDs.insert(card.id)
                }
            }
            for (index, word) in saved.enumerated() {
                let key = word.english.trimmed.lowercased()
                guard !key.isEmpty, builtInByKey[key] == nil else { continue }
                lib.customCards.append(Card(id: "c:" + UUID().uuidString,
                                            english: word.english.trimmed,
                                            translation: word.translation.trimmed,
                                            ipa: nil, example: nil, topic: .custom, isCustom: true,
                                            addedAt: now.addingTimeInterval(Double(index))))
            }
        }

        // Выученные слова → 4-я коробка (повтор через 14 дней)
        let customByKey = Dictionary(lib.customCards.map { ($0.english.lowercased(), $0) }, uniquingKeysWith: { a, _ in a })
        for key in d.stringArray(forKey: "learnedWords") ?? [] {
            let card = builtInByKey[key] ?? customByKey[key]
            guard let card else { continue }
            lib.progress[card.id] = CardProgress(box: 4, due: now.addingTimeInterval(14 * 86_400),
                                             updated: now, correct: 1, wrong: 0)
        }
    }
}
