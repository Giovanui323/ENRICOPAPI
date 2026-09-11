import SwiftUI
import AppKit

@main
struct EnricoPapiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 420, height: 580)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize singletons
        _ = CameraManager.shared
        _ = FaceTracker.shared
        _ = OverlayManager.shared
        
        setupDockIcon()
        setupStatusBarItem()
    }
    
    private func setupDockIcon() {
        if let icon = loadStatusBarIcon() {
            NSApp.applicationIconImage = icon
            NSApp.dockTile.display()
        }
    }
    
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            if let icon = loadStatusBarIcon() {
                icon.size = NSSize(width: 18, height: 18)
                button.image = icon
            } else {
                button.image = NSImage(systemSymbolName: "face.smiling.fill", accessibilityDescription: "Papi Focus")
            }
            button.action = #selector(statusBarClicked)
            button.target = self
        }
    }
    
    @objc private func statusBarClicked() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { !($0 is NSPanel) && $0.level == .normal }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    private func loadStatusBarIcon() -> NSImage? {
        let paths = [
            Bundle.main.resourcePath.map { $0 + "/papi_laser.png" } ?? "",
            FileManager.default.currentDirectoryPath + "/Assets/papi_laser.png",
            "/Users/lucasicignano/ENRICOPAPI/Assets/papi_laser.png",
            Bundle.main.resourcePath.map { $0 + "/enrico_papi.jpg" } ?? "",
            FileManager.default.currentDirectoryPath + "/Assets/enrico_papi.jpg",
            "/Users/lucasicignano/ENRICOPAPI/Assets/enrico_papi.jpg"
        ]
        for path in paths {
            if let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
