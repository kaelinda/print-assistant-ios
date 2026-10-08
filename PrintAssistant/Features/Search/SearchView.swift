import SwiftUI

struct SearchView: View {
    @Environment(AppModel.self) private var appModel
    @State private var query = ""

    var body: some View {
        Group {
            if normalizedQuery.isEmpty {
                ContentUnavailableView {
                    Label("搜索文件", systemImage: "magnifyingglass")
                } description: {
                    Text("搜索文件名；已建立 OCR 索引的文件也会搜索正文。")
                }
            } else if results.isEmpty {
                ContentUnavailableView.search(text: normalizedQuery)
            } else {
                List(results) { document in
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
        .navigationTitle("搜索")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "文件名或文字")
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var results: [DocumentRecord] {
        appModel.library.visibleDocuments(query: normalizedQuery)
    }
}
