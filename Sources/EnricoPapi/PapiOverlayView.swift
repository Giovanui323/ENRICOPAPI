import SwiftUI
import AVKit
import AVFoundation

// MARK: - Asset Loader
final class PapiAssetLoader {
    static func videoURL() -> URL? {
        let possiblePaths = [
            Bundle.main.resourcePath.map { $0 + "/papi_animation.mp4" } ?? "",
            FileManager.default.currentDirectoryPath + "/Assets/papi_animation.mp4",
            "/Users/lucasicignano/ENRICOPAPI/Assets/papi_animation.mp4"
        ]
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
    
    static func papiImage() -> NSImage? {
        let possiblePaths = [
            Bundle.main.resourcePath.map { $0 + "/enrico_papi.jpg" } ?? "",
            FileManager.default.currentDirectoryPath + "/Assets/enrico_papi.jpg",
            "/Users/lucasicignano/ENRICOPAPI/Assets/enrico_papi.jpg"
        ]
        for path in possiblePaths {
            if let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }
    
    static func patternImage() -> NSImage? {
        let possiblePaths = [
            Bundle.main.resourcePath.map { $0 + "/papi_pattern.jpg" } ?? "",
            FileManager.default.currentDirectoryPath + "/Assets/papi_pattern.jpg",
            "/Users/lucasicignano/ENRICOPAPI/Assets/papi_pattern.jpg"
        ]
        for path in possiblePaths {
            if let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }
}

// MARK: - High-Performance Pattern Cache
final class PapiPatternCache {
    static let shared = PapiPatternCache()
    private var cachedTiledImage: NSImage?
    private var cachedScreenSize: CGSize = .zero
    
    func getTiledImage(for size: CGSize) -> NSImage? {
        let targetSize = CGSize(width: max(100, size.width), height: max(100, size.height))
        if let cached = cachedTiledImage, cachedScreenSize == targetSize {
            return cached
        }
        
        guard let sourceImage = PapiAssetLoader.patternImage() ?? PapiAssetLoader.papiImage() else {
            return nil
        }
        
        let tileW: CGFloat = 110
        let tileH: CGFloat = (tileW / max(1, sourceImage.size.width)) * sourceImage.size.height
        let spacing: CGFloat = 4
        
        // 1. Pre-render small thumbnail once
        let thumb = NSImage(size: CGSize(width: tileW, height: tileH))
        thumb.lockFocus()
        sourceImage.draw(in: CGRect(x: 0, y: 0, width: tileW, height: tileH), from: .zero, operation: .copy, fraction: 1.0)
        thumb.unlockFocus()
        
        // 2. Render tiled pattern
        let tiledImage = NSImage(size: targetSize)
        tiledImage.lockFocus()
        
        NSColor.black.setFill()
        CGRect(origin: .zero, size: targetSize).fill()
        
        let cols = Int(ceil(targetSize.width / (tileW + spacing))) + 1
        let rows = Int(ceil(targetSize.height / (tileH + spacing))) + 1
        
        for r in 0..<rows {
            for c in 0..<cols {
                let rect = CGRect(
                    x: CGFloat(c) * (tileW + spacing),
                    y: CGFloat(r) * (tileH + spacing),
                    width: tileW,
                    height: tileH
                )
                thumb.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 0.92)
            }
        }
        
        tiledImage.unlockFocus()
        self.cachedTiledImage = tiledImage
        self.cachedScreenSize = targetSize
        return tiledImage
    }
}

// MARK: - Main Overlay View
struct PapiOverlayView: View {
    let reason: String
    let onDismiss: () -> Void
    
    @ObservedObject private var overlayManager = OverlayManager.shared
    @State private var pulseScale: CGFloat = 1.0
    @State private var shakeOffset: CGFloat = 0.0
    @State private var glowOpacity: Double = 0.85
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. INFINITE ENRICO PAPI PATTERN BACKGROUND
                if let tiledImage = PapiPatternCache.shared.getTiledImage(for: geo.size) {
                    Image(nsImage: tiledImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    Color.black
                }
                
                // 2. DRAMATIC VIGNETTE AND PULSING RED GLOW OVER PATTERN
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.65),
                        Color.black.opacity(0.82),
                        Color.red.opacity(0.88)
                    ]),
                    center: .center,
                    startRadius: 180,
                    endRadius: max(geo.size.width, geo.size.height) * 0.72
                )
                .edgesIgnoringSafeArea(.all)
                .opacity(glowOpacity)
                
                // 3. MAIN FOREGROUND CONTENT
                VStack(spacing: 16) {
                    Spacer()
                    
                    // TOP HEADER: STUDIA, NON TI DISTRARRE!
                    VStack(spacing: 4) {
                        Text("⚠️ ALLARME DISTRAZIONE ⚠️")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.yellow)
                            .shadow(color: .black, radius: 4)
                        
                        Text("STUDIA, NON TI DISTRARRE!")
                            .font(.system(size: 52, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .yellow, .red],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .red, radius: 25, x: 0, y: 0)
                            .shadow(color: .black, radius: 10, x: 0, y: 5)
                            .scaleEffect(pulseScale)
                    }
                    .offset(x: shakeOffset)
                    
                    // ENRICO PAPI ANIMATION (5-SECOND LOOP VIDEO OR IMAGE)
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(
                                LinearGradient(colors: [.yellow, .orange, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 6
                            )
                            .frame(width: 252, height: 352)
                            .shadow(color: .yellow, radius: 20)
                            .scaleEffect(pulseScale * 1.02)
                        
                        if PapiAssetLoader.videoURL() != nil {
                            LoopingVideoPlayerView()
                                .frame(width: 240, height: 340)
                                .cornerRadius(26)
                                .shadow(color: .black, radius: 15)
                        } else if let img = PapiAssetLoader.papiImage() {
                            Image(nsImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 280, height: 280)
                                .cornerRadius(26)
                                .shadow(color: .black, radius: 15)
                        } else {
                            ZStack {
                                Color.blue.opacity(0.3)
                                Image(systemName: "person.fill.viewfinder")
                                    .font(.system(size: 80))
                                    .foregroundColor(.yellow)
                            }
                            .frame(width: 260, height: 260)
                            .cornerRadius(26)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // REASON BADGE
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                            .font(.title3)
                        
                        Text("BECCATO: \(reason.uppercased())")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.red, lineWidth: 2)
                            )
                    )
                    
                    // SUBTITLE & UNLOCK INSTRUCTIONS
                    VStack(spacing: 6) {
                        Text("🎵 MOOSECA! Rimettiti subito sui libri! 🎵")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.yellow)
                            .shadow(color: .black, radius: 4)
                        
                        if overlayManager.hasAcknowledged {
                            HStack(spacing: 8) {
                                Image(systemName: "eyes")
                                    .font(.headline)
                                Text("HAI CLICCATO! ORA GUARDA IL PC PER SBLOCCARE")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.85))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 1.5))
                        } else {
                            Text("1. Clicca \"HO CAPITO\"  •  2. Guarda lo schermo per sbloccare")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white.opacity(0.95))
                                .shadow(color: .black, radius: 4)
                        }
                    }
                    
                    // DUAL-VERIFICATION UNLOCK BUTTON
                    Button(action: {
                        overlayManager.acknowledge()
                    }) {
                        HStack(spacing: 12) {
                            if overlayManager.hasAcknowledged {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("CONFERMATO! ORA GUARDA IL PC")
                                        .font(.system(size: 16, weight: .heavy))
                                    Text("Fissa lo schermo per sbloccare...")
                                        .font(.system(size: 12, weight: .bold))
                                        .opacity(0.85)
                                }
                            } else {
                                Image(systemName: "hand.tap.fill")
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("HO CAPITO! TORNO A STUDIARE")
                                        .font(.system(size: 17, weight: .heavy))
                                    Text("Clicca qui e guarda lo schermo per sbloccare")
                                        .font(.system(size: 12, weight: .bold))
                                        .opacity(0.85)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .foregroundColor(.black)
                        .background(
                            overlayManager.hasAcknowledged
                                ? LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(28)
                        .shadow(color: (overlayManager.hasAcknowledged ? Color.green : Color.orange).opacity(0.8), radius: 15)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                    
                    if overlayManager.hasAcknowledged {
                        Button(action: onDismiss) {
                            Text("(Webcam coperta o stanza buia? Clicca qui per sblocco forzato)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.75))
                                .underline()
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            OverlayVideoController.shared.stop()
        }
    }
    
    private func startAnimations() {
        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
            glowOpacity = 1.0
        }
        
        withAnimation(Animation.easeInOut(duration: 0.08).repeatForever(autoreverses: true)) {
            shakeOffset = 5.0
        }
    }
}

// MARK: - Video Player View
struct LoopingVideoPlayerView: NSViewRepresentable {
    @ObservedObject var controller = OverlayVideoController.shared
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = controller.player
        playerView.controlsStyle = .none
        playerView.showsFrameSteppingButtons = false
        playerView.showsSharingServiceButton = false
        playerView.showsFullScreenToggleButton = false
        playerView.videoGravity = .resizeAspectFill
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player !== controller.player {
            nsView.player = controller.player
        }
    }
    
    static func dismantleNSView(_ nsView: AVPlayerView, coordinator: ()) {
        nsView.player = nil
    }
}
