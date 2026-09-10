import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager.shared
    @StateObject private var tracker = FaceTracker.shared
    @StateObject private var overlayManager = OverlayManager.shared
    @StateObject private var soundManager = SoundManager.shared
    
    // Pomodoro Timer State
    @State private var pomodoroSecondsRemaining: Int = 25 * 60
    @State private var isPomodoroRunning: Bool = false
    @State private var isBreakMode: Bool = false
    @State private var pomodoroTimer: Timer? = nil
    
    var body: some View {
        HStack(spacing: 0) {
            // LEFT PANEL: Camera Feed & Real-time Gaze Telemetry
            VStack(spacing: 16) {
                // Video Preview Card
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.8))
                        .frame(height: 260)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(statusBorderColor, lineWidth: 3)
                        )
                    
                    if let image = cameraManager.currentFrame {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 256)
                            .cornerRadius(14)
                            .overlay(cameraHUDOverlay)
                    } else {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text(cameraManager.permissionGranted ? "Avvio fotocamera..." : "In attesa permessi fotocamera...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Real-time Status Badge
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 14, height: 14)
                        .shadow(color: statusColor, radius: 8)
                    
                    Text(statusText)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if tracker.currentStatus.isDistracted && tracker.currentStatus.continuousDistractionTime > 0 {
                        Text(String(format: "%.1fs / %.1fs", tracker.currentStatus.continuousDistractionTime, tracker.toleranceSeconds))
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                
                // Telemetry Gauges
                VStack(spacing: 8) {
                    telemetryRow(
                        title: "Inclinazione Testa (Pitch)",
                        value: tracker.currentStatus.pitch,
                        status: tracker.currentStatus.pitch < tracker.pitchDownThreshold ? "In basso (Telefono)" : "Schermo",
                        isAlert: tracker.currentStatus.pitch < tracker.pitchDownThreshold
                    )
                    
                    telemetryRow(
                        title: "Rotazione Testa (Yaw)",
                        value: tracker.currentStatus.yaw,
                        status: abs(tracker.currentStatus.yaw) > tracker.yawThreshold ? "Voltata" : "Centrata",
                        isAlert: abs(tracker.currentStatus.yaw) > tracker.yawThreshold
                    )
                    
                    telemetryRow(
                        title: "Apertura Occhi",
                        value: (tracker.currentStatus.leftEyeOpenness + tracker.currentStatus.rightEyeOpenness) / 2.0,
                        status: tracker.currentStatus.leftEyeOpenness < tracker.eyeOpennessThreshold ? "Chiusi" : "Aperti",
                        isAlert: tracker.currentStatus.leftEyeOpenness < tracker.eyeOpennessThreshold
                    )
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                
                // Pomodoro Timer Box
                VStack(spacing: 8) {
                    HStack {
                        Label(isBreakMode ? "Pausa Caffè" : "Sessione Studio", systemImage: isBreakMode ? "cup.and.saucer.fill" : "book.fill")
                            .font(.headline)
                            .foregroundColor(isBreakMode ? .green : .orange)
                        
                        Spacer()
                        
                        Text(formatTime(pomodoroSecondsRemaining))
                            .font(.system(size: 26, weight: .heavy, design: .monospaced))
                            .foregroundColor(isBreakMode ? .green : .yellow)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: togglePomodoro) {
                            Label(isPomodoroRunning ? "Metti in Pausa" : "Avvia Studio", systemImage: isPomodoroRunning ? "pause.fill" : "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isPomodoroRunning ? .red : .green)
                        
                        Button(action: resetPomodoro) {
                            Text("Reset")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                
                Spacer()
            }
            .padding(20)
            .frame(width: 360)
            
            Divider()
            
            // RIGHT PANEL: Controls, Sensitivity & Actions
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enrico Papi Anti-Distrazione")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                        Text("Monitoraggio sguardo e correzione posturale per lo studio")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Jumpscare Instant Test Button
                    Button(action: triggerTestJumpscare) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PROVA JUMPSCARE PAPI")
                                    .font(.headline)
                                Text("Testa l'allarme a schermo intero con audio e voce")
                                    .font(.caption2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .foregroundColor(.black)
                        .background(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(12)
                        .shadow(color: .orange.opacity(0.5), radius: 6)
                    }
                    .buttonStyle(.plain)
                    
                    // Statistics Card
                    HStack(spacing: 16) {
                        StatCard(title: "Beccato da Papi", value: "\(tracker.distractionCount)", unit: "volte", icon: "exclamationmark.octagon.fill", color: .red)
                        StatCard(title: "Sensibilità", value: String(format: "%.1fs", tracker.toleranceSeconds), unit: "ritardo", icon: "timer", color: .blue)
                    }
                    
                    // Threshold Controls
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Impostazioni Rilevamento")
                            .font(.headline)
                        
                        // Tolerance slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Tempo di tolleranza distrazione:")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.1f secondi", tracker.toleranceSeconds))
                                    .font(.subheadline.bold())
                            }
                            Slider(value: $tracker.toleranceSeconds, in: 0.5...4.0, step: 0.25)
                            Text("Tempo continuato prima che Enrico Papi compaia a rimproverarti.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Pitch down (phone) sensitivity
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Soglia sguardo in basso (Telefono):")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.2f rad", abs(tracker.pitchDownThreshold)))
                                    .font(.subheadline.bold())
                            }
                            Slider(value: Binding(
                                get: { -tracker.pitchDownThreshold },
                                set: { tracker.pitchDownThreshold = -$0 }
                            ), in: 0.08...0.35, step: 0.02)
                            Text("Aumenta se hai il monitor posizionato molto in alto.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Yaw (looking away) sensitivity
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Soglia rotazione testa (Laterale):")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.2f rad", tracker.yawThreshold))
                                    .font(.subheadline.bold())
                            }
                            Slider(value: $tracker.yawThreshold, in: 0.15...0.45, step: 0.02)
                        }
                        
                        Divider()
                        
                        // Toggles
                        Toggle("Rileva occhi chiusi / colpi di sonno", isOn: $tracker.checkEyesClosed)
                        Toggle("Voce italiana di Enrico Papi (\"Studia!\")", isOn: $soundManager.isVoiceEnabled)
                        Toggle("Jingle audio acustico", isOn: $soundManager.isSoundFxEnabled)
                        Toggle("Monitoraggio attivo", isOn: $tracker.isTrackingActive)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                    
                    // Reset stats button
                    Button(action: { tracker.resetDistractionCount() }) {
                        Label("Azzera Contatore Distrazioni", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 10)
                }
                .padding(20)
            }
        }
        .frame(minWidth: 780, minHeight: 620)
    }
    
    // Helpers
    private var statusColor: Color {
        if !tracker.currentStatus.isFaceDetected { return .red }
        if tracker.isDistractionAlertActive { return .red }
        if tracker.currentStatus.isDistracted { return .orange }
        return .green
    }
    
    private var statusBorderColor: Color {
        if tracker.isDistractionAlertActive { return .red }
        if tracker.currentStatus.isDistracted { return .orange }
        return .green.opacity(0.8)
    }
    
    private var statusText: String {
        if isBreakMode { return "Modalità Pausa Relax" }
        if !tracker.isTrackingActive { return "Monitoraggio in pausa" }
        if tracker.isDistractionAlertActive { return "ENRICO PAPI ATTIVO!" }
        if tracker.currentStatus.isDistracted { return "Attenzione: distratto!" }
        return "Concentrato sul PC"
    }
    
    private var cameraHUDOverlay: some View {
        VStack {
            HStack {
                Text("LIVE GAZE TRACKER")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)
                Spacer()
            }
            Spacer()
        }
        .padding(8)
    }
    
    private func telemetryRow(title: String, value: Double, status: String, isAlert: Bool) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(status)
                .font(.caption.bold())
                .foregroundColor(isAlert ? .red : .green)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func togglePomodoro() {
        isPomodoroRunning.toggle()
        if isPomodoroRunning {
            tracker.isTrackingActive = !isBreakMode
            pomodoroTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                Task { @MainActor in
                    if pomodoroSecondsRemaining > 0 {
                        pomodoroSecondsRemaining -= 1
                    } else {
                        // Switch between study & break
                        isBreakMode.toggle()
                        pomodoroSecondsRemaining = isBreakMode ? (5 * 60) : (25 * 60)
                        FaceTracker.shared.isTrackingActive = !isBreakMode
                        SoundManager.shared.speak(text: isBreakMode ? "Pausa finita! Si torna a studiare!" : "Ottimo lavoro! Pausa caffè!")
                    }
                }
            }
        } else {
            pomodoroTimer?.invalidate()
            pomodoroTimer = nil
        }
    }
    
    private func resetPomodoro() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        isPomodoroRunning = false
        isBreakMode = false
        pomodoroSecondsRemaining = 25 * 60
        tracker.isTrackingActive = true
    }
    
    private func triggerTestJumpscare() {
        OverlayManager.shared.triggerAlert(reason: "Test jumpscare manuale!")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            OverlayManager.shared.dismissAlert()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 26, weight: .bold))
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
    }
}
