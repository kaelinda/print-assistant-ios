import SwiftUI

struct FilesView: View {
    @Environment(AppModel.self) private var appModel

    @State private var sort: DocumentLibrary.Sort = .modified
    @State private var source: DocumentLibrary.SourceFilter = .all

    var body: some View {
        Group {
            if let error = appModel.library.persistenceError, appModel.library.documents.isEmpty {
                ContentUnavailableView {
                    Label("无法读取文件库", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                }
            } else if visibleDocuments.isEmpty {
                ContentUnavailableView {
                    Label(source == .all ? "还没有文件" : "没有符合条件的文件", systemImage: "folder")
                } description: {
                    Text(source == .all ? "扫描或生成 PDF 后会出现在这里。" : "可以切换到其他来源查看文件。")
                }
            } else {
                List(visibleDocuments) { document in
                    Button {
                        appModel.push(.document(document.id))
                    } label: {
                        DocumentRow(document: document)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("文件")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("来源", selection: $source) {
                        ForEach(DocumentLibrary.SourceFilter.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }

                    Divider()

                    Picker("排序", selection: $sort) {
                        ForEach(DocumentLibrary.Sort.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("筛选与排序")
            }
        }
    }

    private var visibleDocuments: [DocumentRecord] {
        appModel.library.visibleDocuments(sort: sort, source: source)
    }
}
