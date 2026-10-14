import SwiftUI
import UniformTypeIdentifiers

extension View {
    /// Copies picked files into the persistent library. Security-scoped access starts
    /// synchronously inside the picker callback, before this closure returns.
    func libraryFileImporter(
        isPresented: Binding<Bool>,
        allowedContentTypes: [UTType],
        allowsMultipleSelection: Bool = false,
        importer: PDFImportService,
        onStart: @escaping @MainActor () -> Void,
        onFailure: @escaping @MainActor (String) -> Void,
        onFiles: @escaping @MainActor ([PDFSourceItem]) -> Void
    ) -> some View {
        fileImporter(
            isPresented: isPresented,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: allowsMultipleSelection
        ) { result in
            let access: SecurityScopedAccess
            do {
                access = try SecurityScopedAccess(result: result)
            } catch {
                let message = error.localizedDescription
                Task { @MainActor in
                    onFailure(message)
                }
                return
            }

            Task { @MainActor in
                defer { access.stop() }
                onStart()
                do {
                    let files = try await importer.copyIntoLibrary(urls: access.urls)
                    onFiles(files)
                } catch {
                    onFailure(error.localizedDescription)
                }
            }
        }
    }
}
