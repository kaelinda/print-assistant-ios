import Foundation
import Testing
@testable import PrintAssistant

@MainActor
struct AppModelWorkTests {
    @Test
    @MainActor
    func startsOnToolsAndCanPushTheToolOrderEditor() {
        let model = AppModel()

        #expect(model.selectedTab == .tools)
        model.push(.toolOrderEditor)
        #expect(model.path == [.toolOrderEditor])
    }

    @Test
    func exclusiveWorkRejectsASecondOperationUntilTheFirstFinishes() async throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "AppModelWorkTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let model = AppModel(library: DocumentLibrary(baseURL: root))
        defer { try? FileManager.default.removeItem(at: root) }

        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        let first = Task { @MainActor in
            try await model.runExclusive {
                continuation.yield(())
                try await Task.sleep(for: .milliseconds(400))
            }
        }

        var iterator = stream.makeAsyncIterator()
        await iterator.next()
        #expect(model.isWorking)

        await #expect(throws: AppModel.WorkError.self) {
            try await model.runExclusive { }
        }
        #expect(model.isWorking)

        first.cancel()
        _ = try? await first.value
        #expect(model.isWorking == false)

        try await model.runExclusive { }
        #expect(model.isWorking == false)
    }
}
