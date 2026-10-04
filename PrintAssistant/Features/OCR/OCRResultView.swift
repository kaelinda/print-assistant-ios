import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct OCRResultView: View {
    @Environment(AppModel.self) private var appModel
    let result: OCRResult

    @State private var isExporting = false

    var body: some View {
        Group {
            if result.isEmpty {
                ContentUnavailableView {
                    Label("没有识别到文字", systemImage: "text.magnifyingglass")
                } description: {
                    Text("可以返回重新拍摄，尽量让文字清晰、完整并减少反光。")
                } actions: {
                    Button("重新选择来源") {
                        appModel.replaceTop(with: .ocrSource)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                            Text(result.sourceName)
                                .font(.headline)
                            Text("\(result.pageCount) 页 · 已完成文字识别")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(result.text)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DesignTokens.Spacing.md)
                            .background(
                                Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                            )

                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Button {
                                UIPasteboard.general.string = result.text
                                appModel.transientMessage = "文字已复制"
                            } label: {
                                Label("复制", systemImage: "doc.on.doc")
                                    .frame(maxWidth: .infinity, minHeight: DesignTokens.minimumHitTarget)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                isExporting = true
                            } label: {
                                Label("TXT", systemImage: "doc.text")
                                    .frame(maxWidth: .infinity, minHeight: DesignTokens.minimumHitTarget)
                            }
                            .buttonStyle(.bordered)

                            ShareLink(item: result.text) {
                                Label("分享", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity, minHeight: DesignTokens.minimumHitTarget)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(DesignTokens.Spacing.lg)
                }
            }
        }
        .navigationTitle("识别结果")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $isExporting,
            document: PlainTextDocument(text: result.text),
            contentType: .plainText,
            defaultFilename: exportFilename
        ) { exportResult in
            if case .failure(let error) = exportResult {
                appModel.transientMessage = error.localizedDescription
            }
        }
    }

    private var exportFilename: String {
        let base = (result.sourceName as NSString).deletingPathExtension
        return base.isEmpty ? "识别文字" : base
    }
}

private struct PlainTextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    let text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        text = configuration.file.regularFileContents
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
