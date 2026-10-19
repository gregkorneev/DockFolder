import Carbon
import Foundation

@MainActor
final class GlobalShortcutService {
    static let shared = GlobalShortcutService()

    var onShortcut: (() -> Void)?
    private var eventHandler: EventHandlerRef?
    private var hotKey: EventHotKeyRef?

    func enable() throws {
        guard hotKey == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let service = Unmanaged<GlobalShortcutService>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in service.onShortcut?() }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        guard handlerStatus == noErr else { throw ShortcutError.registrationFailed(handlerStatus) }

        let identifier = EventHotKeyID(signature: OSType(0x444F434B), id: 1)
        let status = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(controlKey | optionKey),
            identifier,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
        guard status == noErr else {
            RemoveEventHandler(eventHandler!)
            eventHandler = nil
            throw ShortcutError.registrationFailed(status)
        }
    }

    func disable() {
        if let hotKey { UnregisterEventHotKey(hotKey); self.hotKey = nil }
        if let eventHandler { RemoveEventHandler(eventHandler); self.eventHandler = nil }
    }
}

enum ShortcutError: LocalizedError {
    case registrationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .registrationFailed(let status): AppLocalization.format("The global shortcut Control–Option–Space could not be registered (%d). It may already be in use.", status)
        }
    }
}
