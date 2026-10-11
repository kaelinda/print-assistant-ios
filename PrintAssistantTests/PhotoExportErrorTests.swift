import Photos
import Testing
@testable import PrintAssistant

struct PhotoExportErrorTests {
    @Test
    func authorizedPhotoAccessIsNotAnError() {
        #expect(PhotoExportError.authorizationFailure(for: .authorized) == nil)
        #expect(PhotoExportError.authorizationFailure(for: .limited) == nil)
    }

    @Test
    func deniedPhotoAccessExplainsTheMissingPermission() {
        #expect(PhotoExportError.authorizationFailure(for: .denied) == .notAuthorized)
        #expect(PhotoExportError.authorizationFailure(for: .restricted) == .notAuthorized)
        let description = PhotoExportError.notAuthorized.errorDescription ?? ""
        let mentionsPermission = description.contains("权限") || description.localizedCaseInsensitiveContains("permission")
        #expect(mentionsPermission)
    }
}
