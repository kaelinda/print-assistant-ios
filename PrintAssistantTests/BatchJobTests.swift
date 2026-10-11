import Foundation
import Testing
@testable import PrintAssistant

struct BatchJobTests {
    @Test
    func progressCountsFinishedItemsAndKeepsPartialSuccessOnCancel() {
        let first = UUID()
        let second = UUID()
        let third = UUID()
        var job = BatchJob(items: [
            .init(id: first, name: "a.pdf"),
            .init(id: second, name: "b.pdf"),
            .init(id: third, name: "c.pdf")
        ])
        #expect(job.progress == 0)

        let result = UUID()
        job.markRunning(first)
        job.markSucceeded(first, result: result)
        job.markFailed(second, message: "无法压缩")
        #expect(abs(job.progress - (2.0 / 3.0)) < 0.001)
        #expect(job.succeededIDs == [result])

        job.cancelRemaining()
        #expect(job.isCancelled)
        #expect(job.succeededIDs == [result])
        #expect(job.items[1].state == .failed("无法压缩"))
        #expect(job.items[2].state == .cancelled)
        #expect(job.progress == 1)
    }

    @Test
    func emptyJobHasZeroProgress() {
        let job = BatchJob(items: [])
        #expect(job.progress == 0)
        #expect(job.succeededIDs.isEmpty)
    }
}
