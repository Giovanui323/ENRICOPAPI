import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager.shared
    @StateObject private var tracker = FaceTracker.shared
    @StateObject private var soundManager = SoundManager.shared
    
    // Pomodoro Timer State
    @State private var pomodoroSecondsRemaining: Int = 25 * 60
    @State private var isPomodoroRunning: Bool = false
    @State private var isBreakMode: Bool = false
    @State private var pomodoroTimer: Timer? = nil
    
    // Settings Sheet state
    @State private var showingSettings: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // HEADER
            HStack(spacing: 12) {
                if let icon = loadAppIcon() {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .cornerRadius(10)
                        .shadow(color: .blue.opacity(0.4), radius: 4)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Papi Focus")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                    Text("STUDIA, NON TI DISTRARRE!")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                // Test Jumpscare Quick Button
                Button(action: triggerTestJumpscare) {
                    Label("Test", systemImage: "bolt.fill")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .help("Testa subito l'allarme a schermo intero")
                
                // Settings Gear Button
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .help("Apri Impostazioni e Sensibilità")
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            
            // WEBCAM CARD
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 380, height: 250)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(statusBorderColor, lineWidth: 3.5)
                            .shadow(color: statusBorderColor.opacity(0.6), radius: 10)
                    )
                
                if let image = cameraManager.currentFrame {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 376, height: 246)
                        .cornerRadius(18)
                        .clipped()
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(cameraManager.permissionGranted ? "Avvio fotocamera..." : "Richiesta permessi fotocamera...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Status Overlay Tag
                VStack {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 10, height: 10)
                                .shadow(color: statusColor, radius: 4)
                            
                            Text(statusText)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            
                            if tracker.currentStatus.isDistracted && tracker.currentStatus.continuousDistractionTime > 0 {
                                Text(String(format: "(%.1fs)", tracker.currentStatus.continuousDistractionTime))
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(20)
                        
                        Spacer()
                    }
                    .padding(12)
                    
                    Spacer()
                }
            }
            
            // POMODORO TIMER AREA
            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Label(isBreakMode ? "Pausa Caffè" : "Sessione Studio", systemImage: isBreakMode ? "cup.and.saucer.fill" : "book.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isBreakMode ? .green : .secondary)
                    
                    Spacer()
                    
                    Text(formatTime(pomodoroSecondsRemaining))
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(isBreakMode ? .green : (isPomodoroRunning ? .yellow : .primary))
                }
                .padding(.horizontal, 8)
                
                HStack(spacing: 12) {
                    Button(action: togglePomodoro) {
                        HStack {
                            Image(systemName: isPomodoroRunning ? "pause.fill" : "play.fill")
                            Text(isPomodoroRunning ? "Metti in Pausa" : "Avvia Studio")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            isPomodoroRunning ?
                            LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: (isPomodoroRunning ? Color.red : Color.green).opacity(0.3), radius: 6)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: resetPomodoro) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 15, weight: .bold))
                            .padding(12)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .help("Azzera Timer Studio")
                }
            }
            .padding(.horizontal, 24)
            
            // FOOTER: STATS BADGE
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Beccato da Papi:")
                        .foregroundColor(.secondary)
                    Text("\(tracker.distractionCount) \(tracker.distractionCount == 1 ? "volta" : "volte")")
                        .fontWeight(.bold)
                }
                .font(.system(size: 13))
                
                Spacer()
                
                if tracker.distractionCount > 0 {
                    Button("Azzera") {
                        tracker.resetDistractionCount()
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(width: 420, height: 490)
        .sheet(isPresented: $showingSettings) {
            SettingsView(tracker: tracker, soundManager: soundManager)
        }
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
        return .green
    }
    
    private var statusText: String {
        if isBreakMode { return "Pausa Relax" }
        if !tracker.isTrackingActive { return "Pausa" }
        if tracker.isDistractionAlertActive { return "STUDIA, NON TI DISTRARRE!" }
        if tracker.currentStatus.isDistracted { return "Attenzione: distratto!" }
        return "Concentrato sul PC"
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
                        isBreakMode.toggle()
                        pomodoroSecondsRemaining = isBreakMode ? (5 * 60) : (25 * 60)
                        FaceTracker.shared.isTrackingActive = !isBreakMode
                        SoundManager.shared.playMoosecaAudio()
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
    
    private func loadAppIcon() -> NSImage? {
        let paths = [
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
}

// DEDICATED SETTINGS VIEW SHEET
struct SettingsView: View {
    @ObservedObject var tracker: FaceTracker
    @ObservedObject var soundManager: SoundManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Impostazioni")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button("Fine") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(18)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // SECTION 1: Sensibilità e Tempi
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Sensibilità & Rilevamento")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Tolleranza
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Tempo di tolleranza:")
                                Spacer()
                                Text(String(format: "%.1f secondi", tracker.toleranceSeconds))
                                    .fontWeight(.bold)
                            }
                            Slider(value: $tracker.toleranceSeconds, in: 0.5...4.0, step: 0.25)
                            Text("Tempo di distrazione continuata prima dell'allarme.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // Pitch (telefono)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Sguardo in basso (Telefono):")
                                Spacer()
                                Text(pitchSensitivityDescription)
                                    .fontWeight(.bold)
                            }
                            Slider(value: Binding(
                                get: { -tracker.pitchDownThreshold },
                                set: { tracker.pitchDownThreshold = -$0 }
                            ), in: 0.08...0.30, step: 0.02)
                            Text("Regola quanto in basso devi guardare prima che scatti l'allarme.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // Yaw (voltarsi)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Rotazione testa (Laterale):")
                                Spacer()
                                Text(yawSensitivityDescription)
                                    .fontWeight(.bold)
                            }
                            Slider(value: $tracker.yawThreshold, in: 0.18...0.42, step: 0.02)
                        }
                        
                        Toggle("Rileva occhi chiusi / sonnolenza", isOn: $tracker.checkEyesClosed)
                        Toggle("Monitoraggio attivo", isOn: $tracker.isTrackingActive)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                    
                    // SECTION 2: Audio Mooseca
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Audio Mooseca")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Toggle("Audio \"MOOSECA!\" all'allarme", isOn: $soundManager.isMoosecaAudioEnabled)
                        
                        Button(action: { soundManager.playMoosecaAudio() }) {
                            Label("Ascolta Anteprima Audio Mooseca", systemImage: "speaker.wave.3.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                    
                    // SECTION 3: Telemetria Live (Diagnostica)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Telemetria in Tempo Reale")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("Inclinazione (Pitch):")
                            Spacer()
                            Text(String(format: "%.2f", tracker.currentStatus.pitch))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(tracker.currentStatus.pitch < tracker.pitchDownThreshold ? .red : .green)
                        }
                        
                        HStack {
                            Text("Rotazione (Yaw):")
                            Spacer()
                            Text(String(format: "%.2f", tracker.currentStatus.yaw))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(abs(tracker.currentStatus.yaw) > tracker.yawThreshold ? .red : .green)
                        }
                        
                        HStack {
                            Text("Apertura Occhi:")
                            Spacer()
                            Text(String(format: "%.2f", (tracker.currentStatus.leftEyeOpenness + tracker.currentStatus.rightEyeOpenness) / 2))
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    .font(.subheadline)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                }
                .padding(20)
            }
        }
        .frame(width: 440, height: 530)
    }
    
    private var pitchSensitivityDescription: String {
        let val = -tracker.pitchDownThreshold
        if val < 0.12 { return "Molto Severa" }
        if val < 0.20 { return "Normale" }
        return "Tollerante"
    }
    
    private var yawSensitivityDescription: String {
        let val = tracker.yawThreshold
        if val < 0.22 { return "Molto Severa" }
        if val < 0.32 { return "Normale" }
        return "Tollerante"
    }
}
