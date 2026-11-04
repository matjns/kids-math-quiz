#if os(macOS)
import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = MathQuizModel()

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        // NSApp is optional. A plain `let app = NSApp` drops the implicit unwrap and will not compile.
        let app = NSApplication.shared
        _ = app.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let process = ProcessInfo.processInfo
        process.disableSuddenTermination()
        process.disableAutomaticTermination("Math Quiz saves progress when you quit.")
        NSApplication.shared.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        model.persist()
        return .terminateNow
    }
}

@main
struct MathQuizApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Math Quiz", id: "math-quiz") {
            RootView(model: appDelegate.model)
        }
        .defaultSize(width: 1100, height: 780)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
#else
import Glibc

@main
enum MathQuizMain {
    static func main() {
        let message = "Math Quiz runs on macOS 14 or later. See README.md.\n"
        _ = message.withCString { fputs($0, stderr) }
        exit(1)
    }
}
#endif
