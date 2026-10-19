import Foundation

enum AppLocalization {
    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(
            format: NSLocalizedString(key, comment: ""),
            locale: Locale.current,
            arguments: arguments
        )
    }

    static func applicationCount(_ count: Int) -> String {
        let category: String
        if Bundle.main.preferredLocalizations.first?.hasPrefix("ru") == true {
            let lastTwoDigits = count % 100
            let lastDigit = count % 10
            if (11...14).contains(lastTwoDigits) {
                category = "many"
            } else if lastDigit == 1 {
                category = "one"
            } else if (2...4).contains(lastDigit) {
                category = "few"
            } else {
                category = "many"
            }
        } else {
            category = count == 1 ? "one" : "other"
        }
        return format("applicationCount.\(category)", count)
    }

    static func gridColumns(_ count: Int) -> String {
        count == 0
            ? NSLocalizedString("Grid columns: Automatic", comment: "")
            : format("Grid columns: %d", count)
    }

    static func layoutPresetName(_ preset: FolderLayoutPreset) -> String {
        let key: String
        switch preset.id {
        case FolderLayoutPreset.defaultID: key = "Layout preset 4 by 4"
        case "grid-3": key = "Layout preset 3 by 3"
        case "single-row": key = "Layout preset Single row"
        case "single-column": key = "Layout preset Single column"
        default: return preset.name
        }
        return NSLocalizedString(key, comment: "")
    }
}
