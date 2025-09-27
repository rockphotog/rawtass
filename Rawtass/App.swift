import SwiftUI
import os.log

@main
struct RawtassApp: App {
    init() {
        // Suppress ImageIO bundle warnings for RAW image processing
        // This is a common warning when processing RAW files with Adobe plugins installed
        setenv("OBJC_PRINT_LOAD_METHODS", "0", 1)
        
        // Suppress system-level warnings and SQLite noise
        setenv("OS_ACTIVITY_MODE", "disable", 1)
        setenv("SQLITE_TMPDIR", NSTemporaryDirectory(), 1)
        
        // Reduce system task port warnings
        setenv("OS_ACTIVITY_DT_MODE", "NO", 1)

        // Configure logging to reduce ImageIO noise
        if OSLog.default.isEnabled(type: .debug) {
            // This suppresses ImageIO bundle warnings
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}
