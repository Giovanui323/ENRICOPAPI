import Foundation
import AppKit
import SwiftUI

@MainActor
final class OverlayManager: ObservableObject {
    static let shared = OverlayManager()
    
    private var overlayWindow: NSWindow?
    @Published var isShowing: Bool = false
    @Published var currentReason: String = "Distrazione rilevata!"
    
    private init() {
        setupBindings()
    }
    
    private func setupBindings() {
        FaceTracker.shared.onDistractionTriggered = { [weak self] reason in
            Task { @MainActor in
                self?.triggerAlert(reason: reason)
            }
        }
        
        FaceTracker.shared.onDistractionResolved = { [weak self] in
            Task { @MainActor in
                self?.dismissAlert()
            }
        }
    }
    
    func triggerAlert(reason: String) {
        guard !isShowing else { return }
        self.isShowing = true
        self.currentReason = reason
        
        let videoURL = PapiAssetLoader.videoURL()
        if let videoURL = videoURL {
            let isMuted = !SoundManager.shared.isMoosecaAudioEnabled
            OverlayVideoController.shared.start(url: videoURL, isMuted: isMuted)
        } else {
            SoundManager.shared.playDistractionAlert(reason: reason)
        }
        
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let window = getOrCreateOverlayWindow(for: screen)
        window.setFrame(screen.frame, display: true)
        window.alphaValue = 1.0
        window.orderFrontRegardless()
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func dismissAlert() {
        guard isShowing else { return }
        self.isShowing = false
        
        // IMMEDIATELY CUT OFF ALL AUDIO AND VIDEO PLAYBACK
        SoundManager.shared.stopAudio()
        OverlayVideoController.shared.stop()
        
        if let window = overlayWindow {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                window.animator().alphaValue = 0.0
            }, completionHandler: {
                window.contentView = nil
                window.orderOut(nil)
            })
        }
    }
    
    private func getOrCreateOverlayWindow(for screen: NSScreen) -> NSWindow {
        let overlayView = PapiOverlayView(reason: currentReason) { [weak self] in
            self?.dismissAlert()
        }
        let hostingView = NSHostingView(rootView: overlayView)
        
        if let existing = overlayWindow {
            existing.contentView = hostingView
            return existing
        }
        
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        window.isReleasedWhenClosed = false
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.contentView = hostingView
        self.overlayWindow = window
        return window
    }
}
