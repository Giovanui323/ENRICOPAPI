import SwiftUI

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
            
            VStack(spacing: 20) {
                Spacer()
                
                // TOP HEADER: STUDIA, NON TI DISTRARRE!
                VStack(spacing: 6) {
                    Text("⚠️ ALLARME DISTRAZIONE ⚠️")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                        .shadow(color: .black, radius: 4)
                    
                    Text("STUDIA, NON TI DISTRARRE!")
                        .font(.system(size: 58, weight: .heavy, design: .rounded))
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
                
                // ENRICO PAPI MOOSECA IMAGE
                ZStack {
                    // Outer neon pulse ring
                    RoundedRectangle(cornerRadius: 36)
                        .stroke(
                            LinearGradient(colors: [.yellow, .orange, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 8
                        )
                        .frame(width: 330, height: 330)
                        .shadow(color: .yellow, radius: 25)
                        .scaleEffect(pulseScale * 1.02)
                    
                    if let img = loadPapiImage() {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 320, height: 320)
                            .cornerRadius(32)
                            .shadow(color: .black, radius: 15)
                    } else {
                        ZStack {
                            Color.blue.opacity(0.3)
                            Image(systemName: "person.fill.viewfinder")
                                .font(.system(size: 80))
                                .foregroundColor(.yellow)
                        }
                        .frame(width: 320, height: 320)
                        .cornerRadius(32)
                    }
                }
                .padding(.vertical, 8)
                
                // REASON BADGE
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    
                    Text("BECCATO: \(reason.uppercased())")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red, lineWidth: 2)
                        )
                )
                
                // SUBTITLE
                VStack(spacing: 6) {
                    Text("🎵 MOOSECA! Rimettiti subito sui libri! 🎵")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.yellow)
                        .shadow(color: .black, radius: 4)
                    
                    Text("Rialza lo sguardo verso lo schermo per far sparire questo avviso.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // DISMISS BUTTON
                Button(action: onDismiss) {
                    HStack(spacing: 10) {
                        Image(systemName: "book.fill")
                        Text("HO CAPITO! TORNO A STUDIARE")
                            .font(.system(size: 18, weight: .heavy))
                    }
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .foregroundColor(.black)
                    .background(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(30)
                    .shadow(color: .orange.opacity(0.8), radius: 15)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            startAnimations()
        }
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
            pulseScale = 1.06
            glowOpacity = 1.0
        }
        
        withAnimation(Animation.easeInOut(duration: 0.08).repeatForever(autoreverses: true)) {
            shakeOffset = 5.0
        }
    }
}
