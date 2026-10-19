import AppKit
import Foundation

struct ApplicationLauncherService {
    func launch(_ application: ApplicationItem) async throws {
        guard FileManager.default.fileExists(atPath: application.path) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: application.path])
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NSWorkspace.shared.openApplication(at: application.url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
