import Foundation

enum SystemSymbolCatalog {
    static func load(bundle: Bundle = .main) throws -> [String] {
        guard let url = bundle.url(forResource: "SF-Symbols-7.0", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([String].self, from: data)
    }

    enum Category: String, CaseIterable, Identifiable {
        case all, people, communication, devices, media, transport, nature, weather, tools, documents, numbers, arrows, shapes, other

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: NSLocalizedString("All symbols", comment: "")
            case .people: NSLocalizedString("People and activities", comment: "")
            case .communication: NSLocalizedString("Communication", comment: "")
            case .devices: NSLocalizedString("Devices", comment: "")
            case .media: NSLocalizedString("Media", comment: "")
            case .transport: NSLocalizedString("Transport", comment: "")
            case .nature: NSLocalizedString("Nature", comment: "")
            case .weather: NSLocalizedString("Weather", comment: "")
            case .tools: NSLocalizedString("Tools", comment: "")
            case .documents: NSLocalizedString("Documents", comment: "")
            case .numbers: NSLocalizedString("Numbers and letters", comment: "")
            case .arrows: NSLocalizedString("Arrows and controls", comment: "")
            case .shapes: NSLocalizedString("Shapes", comment: "")
            case .other: NSLocalizedString("Other", comment: "")
            }
        }
    }

    static func category(for symbol: String) -> Category {
        let first = symbol.split(separator: ".", maxSplits: 1).first.map(String.init) ?? symbol
        if first.first?.isNumber == true || (first.count == 1 && first.first?.isLetter == true) { return .numbers }
        if symbol.hasPrefix("figure.") || ["person", "hand", "face", "eye", "ear", "brain", "heart"].contains(first) { return .people }
        if ["message", "bubble", "phone", "envelope", "mail", "text", "quote", "at", "mic"].contains(first) { return .communication }
        if ["iphone", "ipad", "mac", "desktopcomputer", "laptopcomputer", "applewatch", "watch", "visionpro", "airpods", "homepod", "display", "keyboard", "computermouse", "gamecontroller", "printer", "server"].contains(first) { return .devices }
        if ["play", "pause", "stop", "music", "video", "film", "camera", "photo", "speaker", "headphones", "waveform", "tv", "radio"].contains(first) { return .media }
        if ["car", "suv", "truck", "bus", "tram", "train", "airplane", "ferry", "bicycle", "scooter", "fuelpump", "steeringwheel"].contains(first) { return .transport }
        if ["leaf", "tree", "flower", "pawprint", "bird", "fish", "tortoise", "hare", "ant", "ladybug", "mountain", "water", "drop"].contains(first) { return .nature }
        if ["sun", "moon", "cloud", "wind", "snowflake", "thermometer", "humidity", "rainbow", "bolt"].contains(first) { return .weather }
        if ["hammer", "wrench", "screwdriver", "paintbrush", "pencil", "scissors", "ruler", "gearshape", "key", "lock", "lightbulb", "magnifyingglass"].contains(first) { return .tools }
        if ["doc", "folder", "book", "books", "calendar", "bookmark", "archivebox", "tray", "list", "tablecells", "chart", "newspaper"].contains(first) { return .documents }
        if symbol.hasPrefix("arrow") || ["chevron", "plus", "minus", "xmark", "checkmark", "multiply", "divide", "ellipsis"].contains(first) { return .arrows }
        if ["circle", "square", "rectangle", "triangle", "diamond", "hexagon", "octagon", "oval", "capsule", "star", "seal"].contains(first) { return .shapes }
        return .other
    }
}
