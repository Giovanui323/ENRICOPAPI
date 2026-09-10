import SwiftUI
import AVKit
import AVFoundation

struct PapiOverlayView: View {
    let reason: String
    let onDismiss: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var shakeOffset: CGFloat = 0.0
    @State private var glowOpacity: Double = 0.85
    
    var body: some View {
        ZStack {
            // Dramatic dark backdrop with pulsing red vignette
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.88),
                    Color.red.opacity(0.65),
                    Color.red.opacity(0.95)
                ]),
                center: .center,
                startRadius: 100,
                endRadius: 900
            )
            .edgesIgnoringSafeArea(.all)
            .opacity(glowOpacity)
            
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
                    
                    if let videoURL = loadVideoURL() {
                        LoopingVideoPlayerView(videoURL: videoURL)
                            .frame(width: 240, height: 340)
                            .cornerRadius(26)
                            .shadow(color: .black, radius: 15)
                    } else if let img = loadPapiImage() {
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
                
                // SUBTITLE
                VStack(spacing: 4) {
                    Text("🎵 MOOSECA! Rimettiti subito sui libri! 🎵")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.yellow)
                        .shadow(color: .black, radius: 4)
                    
                    Text("Rialza lo sguardo verso lo schermo per far sparire questo avviso.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // DISMISS BUTTON
                Button(action: onDismiss) {
                    HStack(spacing: 10) {
                        Image(systemName: "book.fill")
                        Text("HO CAPITO! TORNO A STUDIARE")
                            .font(.system(size: 17, weight: .heavy))
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .foregroundColor(.black)
                    .background(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(28)
                    .shadow(color: .orange.opacity(0.8), radius: 15)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func loadVideoURL() -> URL? {
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
    
    private func loadPapiImage() -> NSImage? {
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

// Seamless looping video player for macOS using AVPlayerLooper
struct LoopingVideoPlayerView: NSViewRepresentable {
    let videoURL: URL
    
    class Coordinator {
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        let asset = AVURLAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        context.coordinator.player = queuePlayer
        context.coordinator.looper = looper
        
        playerView.player = queuePlayer
        playerView.controlsStyle = .none
        playerView.showsFrameSteppingButtons = false
        playerView.showsSharingServiceButton = false
        playerView.showsFullScreenToggleButton = false
        playerView.videoGravity = .resizeAspectFill
        
        queuePlayer.isMuted = false
        queuePlayer.play()
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {}
    
    static func dismantleNSView(_ nsView: AVPlayerView, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.player = nil
        coordinator.looper = nil
    }
}
