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
        .windowToolbarStyle(.unified)
        .defaultSize(width: 820, height: 640)
        
        // Menu Bar Item
        MenuBarExtra("Papi Focus", systemImage: "eye.trianglebadge.exclamationmark") {
            MenuBarView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure app activates properly
        NSApp.setActivationPolicy(.regular)
        
        // Initialize singletons
        _ = CameraManager.shared
        _ = FaceTracker.shared
        _ = OverlayManager.shared
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running in menu bar if main window is closed
    }
}

struct MenuBarView: View {
    @ObservedObject var tracker = FaceTracker.shared
    @ObservedObject var overlay = OverlayManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Enrico Papi Anti-Distrazione")
                .font(.headline)
            
            Text("Stato: \(tracker.isDistractionAlertActive ? "🚨 ALLARME ATTIVO" : (tracker.currentStatus.isDistracted ? "Attenzione" : "Concentrato"))")
                .font(.subheadline)
            
            Text("Volte beccato: \(tracker.distractionCount)")
                .font(.caption)
            
            Divider()
            
            Button("🚨 Prova Jumpscare Papi") {
                OverlayManager.shared.triggerAlert(reason: "Test Menu Bar!")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    OverlayManager.shared.dismissAlert()
                }
            }
            
            Toggle("Monitoraggio attivo", isOn: $tracker.isTrackingActive)
            
            Divider()
            
            Button("Apri Finestra Principale") {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { !($0 is NSPanel) && $0.level == .normal }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            
            Button("Esci da Papi Focus") {
                NSApp.terminate(nil)
            }
        }
        .padding(8)
    }
}
