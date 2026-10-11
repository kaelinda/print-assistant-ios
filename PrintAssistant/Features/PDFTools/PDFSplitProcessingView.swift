import Foundation
import SwiftUI

struct PDFSplitProcessingView: View {
    @Environment(AppModel.self) private var appModel
    let draft: PDFSplitDraft

    @State private var errorMessage: String?
    @State private var attempt = 0
    @State private var completed = false

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()

            if let errorMessage {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignTokens.Color.warning)
                    .accessibilityHidden(true)
                Text("拆分失败")
                    .font(.title2.bold())
                Text(errorMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                PrimaryActionButton(title: "重试", state: .enabled) {
                    self.errorMessage = nil
                    attempt += 1
                }
            } else {
                ProgressView()
                    .controlSize(.large)
                    .accessibilityLabel("正在拆分 PDF")
                Text("正在拆分 PDF")
                    .font(.title2.bold())
                Text("\(draft.ranges.count) 个输出文件")
                    .foregroundStyle(.secondary)
                Text("源文件不会被修改。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .navigationTitle("拆分 PDF")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(errorMessage == nil)
        .task(id: attempt) {
            guard errorMessage == nil else { return }
            await split()
        }
        .onDisappear {
            if !completed && errorMessage != nil && draft.source.isTemporary {
                appModel.pdfImportService.cleanup([draft.source])
            }
        }
    }

    @MainActor
    private func split() async {
        do {
            let prefix = "拆分文件-\(Int(Date.now.timeIntervalSince1970))"
            let urls = try await appModel.pdfOperationService.split(
                url: draft.source.url,
                ranges: draft.ranges,
                filenamePrefix: prefix
            )

            var ids: [DocumentRecord.ID] = []
            do {
                for (index, url) in urls.enumerated() {
                    let values = try url.resourceValues(forKeys: [.fileSizeKey])
                    let record = DocumentRecord(
                        name: url.lastPathComponent,
                        pageCount: draft.ranges[index].pageCount,
                        byteCount: Int64(values.fileSize ?? 0),
                        source: .generated,
                        localURL: url
                    )
                    try appModel.library.add(record)
                    ids.append(record.id)
                }
            } catch {
                for id in ids {
                    try? appModel.library.delete(id: id)
                }
                for url in urls where FileManager.default.fileExists(atPath: url.path) {
                    try? FileManager.default.removeItem(at: url)
                }
                throw error
            }

            if draft.source.isTemporary {
                appModel.pdfImportService.cleanup([draft.source])
            }
            completed = true
            appModel.replaceTop(with: .pdfSplitSuccess(ids))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
