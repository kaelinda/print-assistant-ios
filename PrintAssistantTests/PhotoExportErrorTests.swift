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
        #expect(PhotoExportError.notAuthorized.errorDescription?.contains("权限") == true)
    }
}
