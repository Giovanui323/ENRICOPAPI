import Foundation
import AppKit
import SwiftUI

@MainActor
final class OverlayManager: ObservableObject {
    static let shared = OverlayManager()
    
    private var overlayWindows: [NSWindow] = []
    @Published var isShowing: Bool = false
    @Published var currentReason: String = "Distrazione rilevata!"
    
    private init() {
        setupBindings()
    }
    
    private func setupBindings() {
        FaceTracker.shared.onDistractionTriggered = { [weak self] reason in
            self?.triggerAlert(reason: reason)
        }
        
        FaceTracker.shared.onDistractionResolved = { [weak self] in
            self?.dismissAlert()
        }
    }
    
    func triggerAlert(reason: String) {
        guard !isShowing else { return }
        self.isShowing = true
        self.currentReason = reason
        
        SoundManager.shared.playDistractionAlert(reason: reason)
        
        // Show fullscreen overlay on all active screens
        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen, reason: reason)
            overlayWindows.append(window)
            window.makeKeyAndOrderFront(nil)
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func dismissAlert() {
        guard isShowing else { return }
        self.isShowing = false
        
        for window in overlayWindows {
            window.animator().alphaValue = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            for window in self?.overlayWindows ?? [] {
                window.orderOut(nil)
                window.close()
            }
            self?.overlayWindows.removeAll()
        }
    }
    
    private func createOverlayWindow(for screen: NSScreen, reason: String) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        
        let overlayView = PapiOverlayView(reason: reason) { [weak self] in
            self?.dismissAlert()
        }
        
        window.contentView = NSHostingView(rootView: overlayView)
        return window
    }
}
