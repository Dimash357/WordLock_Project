import Foundation

/// Лёгкая синхронизация прогресса и своих слов через iCloud Key-Value Store (лимит 1 МБ).
/// Работает, если пользователь вошёл в iCloud; иначе тихо ничего не делает.
final class CloudSync {
    private let kvs = NSUbiquitousKeyValueStore.default
    private let key = "wordlock.payload.v1"
    var onRemoteChange: (() -> Void)?

    func start() {
        NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: kvs, queue: .main) { [weak self] _ in
            self?.onRemoteChange?()
        }
        kvs.synchronize()
    }

    func pull() -> CloudPayload? {
        guard let data = kvs.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CloudPayload.self, from: data)
    }

    func push(_ lib: Library) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]   // стабильные байты → нет «пинг-понга» между устройствами
        guard let data = try? encoder.encode(lib.cloudPayload), data.count < 900_000 else { return }
        if kvs.data(forKey: key) == data { return }
        kvs.set(data, forKey: key)
        kvs.synchronize()
    }
}
