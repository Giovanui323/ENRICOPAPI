import SwiftUI

struct PapiOverlayView: View {
    let reason: String
    let onDismiss: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var shakeOffset: CGFloat = 0.0
    @State private var glowOpacity: Double = 0.8
    @State private var laserEyes: Bool = true
    
    var body: some View {
        ZStack {
            // Dark vignette background with red pulsing edge
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.85),
                    Color.red.opacity(0.55),
                    Color.red.opacity(0.95)
                ]),
                center: .center,
                startRadius: 100,
                endRadius: 900
            )
            .edgesIgnoringSafeArea(.all)
            .opacity(glowOpacity)
            
            VStack(spacing: 24) {
                Spacer()
                
                // TOP WARNING BANNER
                VStack(spacing: 8) {
                    Text("⚠️ ALLARME DISTRAZIONE ⚠️")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                        .shadow(color: .black, radius: 4)
                    
                    Text("STUDIA, NON TI DISTRARRE!")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .yellow, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .red, radius: 20, x: 0, y: 0)
                        .shadow(color: .black, radius: 10, x: 0, y: 5)
                        .scaleEffect(pulseScale)
                }
                .offset(x: shakeOffset)
                
                // ENRICO PAPI MEME AVATAR
                ZStack {
                    // Pulsing backdrop circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow.opacity(0.6), .red.opacity(0.8), .clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 160
                            )
                        )
                        .frame(width: 320, height: 320)
                        .scaleEffect(pulseScale * 1.05)
                    
                    EnricoPapiAvatarView(laserEyes: laserEyes)
                        .frame(width: 260, height: 260)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.yellow, lineWidth: 6)
                                .shadow(color: .yellow, radius: 15)
                        )
                }
                .padding(.vertical, 10)
                
                // DISTRACTION REASON BADGE
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    
                    Text("BECCATO: \(reason)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red, lineWidth: 2)
                        )
                )
                
                // SUBTITLE & HINT
                VStack(spacing: 8) {
                    Text("🎵 MOOSECA! Enrico Papi ti sta tenendo d'occhio! 🎵")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    Text("Rialza la testa e guarda lo schermo per far sparire questo avviso.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // MANUAL DISMISS BUTTON
                Button(action: onDismiss) {
                    HStack(spacing: 10) {
                        Image(systemName: "book.fill")
                        Text("HO CAPITO! TORNO A STUDIARE")
                            .font(.system(size: 18, weight: .heavy))
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .foregroundColor(.black)
                    .background(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(30)
                    .shadow(color: .orange.opacity(0.8), radius: 15)
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
            glowOpacity = 1.0
        }
        
        withAnimation(Animation.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
            shakeOffset = 6.0
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            laserEyes.toggle()
        }
    }
}

// Stylized Enrico Papi Caricature & Meme Avatar
struct EnricoPapiAvatarView: View {
    var laserEyes: Bool = false
    
    var body: some View {
        ZStack {
            // Background studio glow
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.15, blue: 0.3), Color(red: 0.05, green: 0.05, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Check if local image asset exists, otherwise render custom illustration
            if let customImg = NSImage(named: "enrico_papi") ?? loadCustomFileImage() {
                Image(nsImage: customImg)
                    .resizable()
                    .scaledToFill()
            } else {
                // Procedural stylized Enrico Papi illustration
                ProceduralPapiFace(laserEyes: laserEyes)
            }
            
            // Laser beam effect from eyes when active
            if laserEyes {
                HStack(spacing: 40) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 14, height: 14)
                        .shadow(color: .red, radius: 15)
                        .shadow(color: .yellow, radius: 8)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 14, height: 14)
                        .shadow(color: .red, radius: 15)
                        .shadow(color: .yellow, radius: 8)
                }
                .offset(y: -12)
            }
        }
    }
    
    private func loadCustomFileImage() -> NSImage? {
        let paths = [
            FileManager.default.currentDirectoryPath + "/Assets/enrico_papi.jpg",
            FileManager.default.currentDirectoryPath + "/Assets/enrico_papi.png",
            Bundle.main.resourcePath.map { $0 + "/enrico_papi.jpg" } ?? ""
        ]
        for path in paths {
            if let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }
}

// Procedural vector illustration of Enrico Papi with his iconic rimless glasses, suit & expression
struct ProceduralPapiFace: View {
    var laserEyes: Bool
    
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            
            // Shoulders and suit
            var suitPath = Path()
            suitPath.move(to: CGPoint(x: 20, y: size.height))
            suitPath.addQuadCurve(to: CGPoint(x: size.width - 20, y: size.height), control: CGPoint(x: center.x, y: size.height - 70))
            suitPath.closeSubpath()
            context.fill(suitPath, with: .color(Color(red: 0.1, green: 0.12, blue: 0.2)))
            
            // White shirt & red tie
            var shirtPath = Path()
            shirtPath.move(to: CGPoint(x: center.x - 25, y: size.height - 40))
            shirtPath.addLine(to: CGPoint(x: center.x, y: size.height - 10))
            shirtPath.addLine(to: CGPoint(x: center.x + 25, y: size.height - 40))
            shirtPath.closeSubpath()
            context.fill(shirtPath, with: .color(.white))
            
            var tiePath = Path()
            tiePath.move(to: CGPoint(x: center.x - 8, y: size.height - 25))
            tiePath.addLine(to: CGPoint(x: center.x + 8, y: size.height - 25))
            tiePath.addLine(to: CGPoint(x: center.x + 12, y: size.height))
            tiePath.addLine(to: CGPoint(x: center.x - 12, y: size.height))
            tiePath.closeSubpath()
            context.fill(tiePath, with: .color(.red))
            
            // Neck
            let neckRect = CGRect(x: center.x - 22, y: center.y + 35, width: 44, height: 40)
            context.fill(Path(neckRect), with: .color(Color(red: 0.92, green: 0.76, blue: 0.65)))
            
            // Head / Face
            let faceRect = CGRect(x: center.x - 55, y: center.y - 65, width: 110, height: 125)
            context.fill(Path(ellipseIn: faceRect), with: .color(Color(red: 0.98, green: 0.82, blue: 0.72)))
            
            // Hair (dark, styled)
            var hairPath = Path()
            hairPath.addArc(center: CGPoint(x: center.x, y: center.y - 45), radius: 58, startAngle: .degrees(160), endAngle: .degrees(20), clockwise: false)
            hairPath.addQuadCurve(to: CGPoint(x: center.x - 55, y: center.y - 30), control: CGPoint(x: center.x, y: center.y - 75))
            hairPath.closeSubpath()
            context.fill(hairPath, with: .color(Color(red: 0.15, green: 0.12, blue: 0.1)))
            
            // Eyebrows (high, expressive)
            var leftBrow = Path()
            leftBrow.move(to: CGPoint(x: center.x - 42, y: center.y - 28))
            leftBrow.addQuadCurve(to: CGPoint(x: center.x - 14, y: center.y - 34), control: CGPoint(x: center.x - 28, y: center.y - 42))
            context.stroke(leftBrow, with: .color(Color(red: 0.2, green: 0.15, blue: 0.1)), lineWidth: 4)
            
            var rightBrow = Path()
            rightBrow.move(to: CGPoint(x: center.x + 14, y: center.y - 34))
            rightBrow.addQuadCurve(to: CGPoint(x: center.x + 42, y: center.y - 28), control: CGPoint(x: center.x + 28, y: center.y - 42))
            context.stroke(rightBrow, with: .color(Color(red: 0.2, green: 0.15, blue: 0.1)), lineWidth: 4)
            
            // Iconic Rimless Glasses
            let leftGlass = CGRect(x: center.x - 46, y: center.y - 24, width: 34, height: 24)
            let rightGlass = CGRect(x: center.x + 12, y: center.y - 24, width: 34, height: 24)
            
            context.stroke(Path(roundedRect: leftGlass, cornerRadius: 6), with: .color(.cyan.opacity(0.8)), lineWidth: 2.5)
            context.stroke(Path(roundedRect: rightGlass, cornerRadius: 6), with: .color(.cyan.opacity(0.8)), lineWidth: 2.5)
            
            // Bridge between lenses
            var bridge = Path()
            bridge.move(to: CGPoint(x: center.x - 12, y: center.y - 14))
            bridge.addLine(to: CGPoint(x: center.x + 12, y: center.y - 14))
            context.stroke(bridge, with: .color(.cyan), lineWidth: 2)
            
            // Eyes
            let leftEye = CGRect(x: center.x - 36, y: center.y - 19, width: 14, height: 14)
            let rightEye = CGRect(x: center.x + 22, y: center.y - 19, width: 14, height: 14)
            context.fill(Path(ellipseIn: leftEye), with: .color(.white))
            context.fill(Path(ellipseIn: rightEye), with: .color(.white))
            
            // Pupils
            let pupilColor: Color = laserEyes ? .red : Color(red: 0.2, green: 0.15, blue: 0.1)
            let leftPupil = CGRect(x: center.x - 33, y: center.y - 16, width: 8, height: 8)
            let rightPupil = CGRect(x: center.x + 25, y: center.y - 16, width: 8, height: 8)
            context.fill(Path(ellipseIn: leftPupil), with: .color(pupilColor))
            context.fill(Path(ellipseIn: rightPupil), with: .color(pupilColor))
            
            // Nose
            var nose = Path()
            nose.move(to: CGPoint(x: center.x, y: center.y - 10))
            nose.addLine(to: CGPoint(x: center.x - 4, y: center.y + 10))
            nose.addLine(to: CGPoint(x: center.x + 4, y: center.y + 10))
            context.stroke(nose, with: .color(Color(red: 0.85, green: 0.65, blue: 0.55)), lineWidth: 2)
            
            // Big enthusiastic Sarabanda Smile!
            var smile = Path()
            smile.move(to: CGPoint(x: center.x - 28, y: center.y + 24))
            smile.addQuadCurve(to: CGPoint(x: center.x + 28, y: center.y + 24), control: CGPoint(x: center.x, y: center.y + 44))
            smile.closeSubpath()
            context.fill(smile, with: .color(Color(red: 0.7, green: 0.1, blue: 0.15)))
            
            // Teeth
            let teethRect = CGRect(x: center.x - 20, y: center.y + 24, width: 40, height: 8)
            context.fill(Path(roundedRect: teethRect, cornerRadius: 2), with: .color(.white))
        }
    }
}
