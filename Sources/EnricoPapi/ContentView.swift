import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager.shared
    @StateObject private var tracker = FaceTracker.shared
    @StateObject private var soundManager = SoundManager.shared
    @StateObject private var overlayManager = OverlayManager.shared
    
    // Study Time & Pomodoro Timer State
    @State private var studyDurationMinutes: Int = 25
    @State private var pomodoroSecondsRemaining: Int = 25 * 60
    @State private var isPomodoroRunning: Bool = false
    @State private var isBreakMode: Bool = false
    @State private var pomodoroTimer: Timer? = nil
    
    // Settings Sheet state
    @State private var showingSettings: Bool = false
    
    // Duration presets for segmented picker
    private let durationPresets = [15, 25, 30, 45, 60]
    
    var body: some View {
        VStack(spacing: 0) {
            // ── WEBCAM MONITOR ──
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                
                if let image = cameraManager.currentFrame {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 230)
                        .cornerRadius(11)
                        .clipped()
                } else {
                    ZStack {
                        if let papiImg = loadPapiLaserImage() {
                            Image(nsImage: papiImg)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 230)
                                .cornerRadius(11)
                                .clipped()
                                .opacity(0.6)
                        }
                        VStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text(cameraManager.permissionGranted ? "Avvio fotocamera..." : "Richiesta permessi fotocamera...")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 230)
                    .background(Color.black)
                    .cornerRadius(11)
                }
                
                // Status overlay badge — top left
                VStack {
                    HStack {
                        statusPill
                        Spacer()
                    }
                    .padding(10)
                    Spacer()
                }
            }
            .frame(height: 234)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // ── STATUS INDICATOR ── centered below webcam
            HStack(spacing: 6) {
                Circle()
                    .fill(tracker.isTrackingActive ? Color.green : Color.secondary)
                    .frame(width: 8, height: 8)
                Text(tracker.isTrackingActive ? "Allarme attivo" : "Standby")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 14)
            
            // ── TIMER DISPLAY ──
            Text(formatTime(pomodoroSecondsRemaining))
                .font(.system(size: 52, weight: .medium, design: .rounded))
                .foregroundColor(timerColor)
                .monospacedDigit()
                .padding(.top, 8)
            
            // Session label
            Label(isBreakMode ? "Pausa Caffè" : "Sessione di Studio",
                  systemImage: isBreakMode ? "cup.and.saucer.fill" : "book.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isBreakMode ? .green : .secondary)
                .padding(.top, 2)
            
            // ── DURATION SELECTOR ── native segmented picker
            if !isPomodoroRunning {
                Picker("Durata", selection: $studyDurationMinutes) {
                    ForEach(durationPresets, id: \.self) { mins in
                        Text("\(mins)m").tag(mins)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)
                .padding(.top, 16)
                .onChange(of: studyDurationMinutes) { newValue in
                    pomodoroSecondsRemaining = newValue * 60
                }
                
                // Fine-tune stepper
                HStack(spacing: 4) {
                    Button(action: {
                        if studyDurationMinutes > 5 {
                            studyDurationMinutes -= 5
                            pomodoroSecondsRemaining = studyDurationMinutes * 60
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .semibold))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Text("\(studyDurationMinutes) min")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .frame(width: 50)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        if studyDurationMinutes < 180 {
                            studyDurationMinutes += 5
                            pomodoroSecondsRemaining = studyDurationMinutes * 60
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .semibold))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.top, 8)
            }
            
            Spacer().frame(minHeight: 12, maxHeight: 20)
            
            // ── ACTION BUTTONS ──
            HStack(spacing: 10) {
                Button(action: togglePomodoro) {
                    HStack(spacing: 6) {
                        Image(systemName: isPomodoroRunning ? "pause.fill" : "play.fill")
                        Text(isPomodoroRunning ? "Pausa" : "Avvia Studio")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(isPomodoroRunning ? .orange : .accentColor)
                
                Button(action: resetPomodoro) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .help("Azzera Timer e Disattiva Allarme")
            }
            .padding(.horizontal, 20)
            
            // ── FOOTER: DISTRACTION COUNTER ──
            HStack {
                Text("Beccato da Papi:")
                    .foregroundColor(.secondary)
                Text("\(tracker.distractionCount) \(tracker.distractionCount == 1 ? "volta" : "volte")")
                    .fontWeight(.semibold)
                    .foregroundColor(tracker.distractionCount > 0 ? .orange : .primary)
                
                Spacer()
                
                if tracker.distractionCount > 0 {
                    Button("Azzera") {
                        tracker.resetDistractionCount()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.caption)
                }
            }
            .font(.system(size: 12))
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .frame(width: 420, height: 580)
        .background(Color(nsColor: .windowBackgroundColor))
        // macOS native toolbar
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 8) {
                    if let icon = loadAppIcon() {
                        Image(nsImage: icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .cornerRadius(4)
                    }
                    Text("Papi Focus")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: triggerTestJumpscare) {
                    Label("Test Allarme", systemImage: "bolt.fill")
                }
                .help("Testa l'allarme")
                
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                }
                .help("Impostazioni")
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(tracker: tracker, soundManager: soundManager)
        }
    }
    
    // MARK: - Status Pill (overlay on webcam)
    
    private var statusPill: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            
            Text(statusText)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
            
            if tracker.isTrackingActive && tracker.currentStatus.isDistracted && tracker.currentStatus.continuousDistractionTime > 0 {
                Text(String(format: "(%.1fs)", tracker.currentStatus.continuousDistractionTime))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        if !tracker.isTrackingActive { return .gray }
        if !tracker.currentStatus.isFaceDetected { return .red }
        if tracker.isDistractionAlertActive { return .red }
        if tracker.currentStatus.isDistracted { return .orange }
        return .green
    }
    
    private var timerColor: Color {
        if isBreakMode { return .green }
        if isPomodoroRunning { return .primary }
        return .primary
    }
    
    private var statusText: String {
        if isBreakMode { return "Pausa Relax" }
        if !tracker.isTrackingActive { return "Standby" }
        if tracker.isDistractionAlertActive { return "DISTRATTO!" }
        if tracker.currentStatus.isDistracted { return "Attenzione" }
        return "Concentrato"
    }
    
    // MARK: - Timer Logic (unchanged)
    
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
                        pomodoroSecondsRemaining = isBreakMode ? (5 * 60) : (studyDurationMinutes * 60)
                        FaceTracker.shared.isTrackingActive = !isBreakMode
                        SoundManager.shared.playMoosecaAudio()
                    }
                }
            }
        } else {
            tracker.isTrackingActive = false
            pomodoroTimer?.invalidate()
            pomodoroTimer = nil
        }
    }
    
    private func resetPomodoro() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        isPomodoroRunning = false
        isBreakMode = false
        pomodoroSecondsRemaining = studyDurationMinutes * 60
        tracker.isTrackingActive = false
    }
    
    private func triggerTestJumpscare() {
        OverlayManager.shared.triggerAlert(reason: "Test jumpscare manuale")
    }
    
    private func loadAppIcon() -> NSImage? {
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
    
    private func loadPapiLaserImage() -> NSImage? {
        let paths = [
            Bundle.main.resourcePath.map { $0 + "/papi_laser.png" } ?? "",
            Bundle.main.resourcePath.map { $0 + "/papi_laser.jpg" } ?? "",
            FileManager.default.currentDirectoryPath + "/Assets/papi_laser.png",
            FileManager.default.currentDirectoryPath + "/Assets/papi_laser.jpg",
            "/Users/lucasicignano/ENRICOPAPI/Assets/papi_laser.png",
            "/Users/lucasicignano/ENRICOPAPI/Assets/papi_laser.jpg"
        ]
        for path in paths {
            if let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return loadAppIcon()
    }
}

// MARK: - Settings Sheet (restyled to match)

struct SettingsView: View {
    @ObservedObject var tracker: FaceTracker
    @ObservedObject var soundManager: SoundManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Impostazioni")
                    .font(.headline)
                Spacer()
                Button("Fine") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(18)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // SECTION: Alarm State
                    GroupBox("Stato Allarme") {
                        Toggle("Attiva allarme anche fuori sessione Pomodoro", isOn: $tracker.isTrackingActive)
                            .toggleStyle(.switch)
                            .padding(.vertical, 4)
                    }
                    
                    // SECTION: Detection Sensitivity
                    GroupBox("Sensibilità Distrazione") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Tolleranza prima dell'allarme")
                                    Spacer()
                                    Text(String(format: "%.1f s", tracker.toleranceSeconds))
                                        .foregroundColor(.secondary)
                                        .monospacedDigit()
                                }
                                Slider(value: $tracker.toleranceSeconds, in: 0.5...5.0, step: 0.5)
                                Text("Tempo in cui puoi guardare altrove prima che scatti l'allarme.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Inclinazione verso il basso")
                                    Spacer()
                                    Text(String(format: "%.2f", abs(tracker.pitchDownThreshold)))
                                        .foregroundColor(.secondary)
                                        .monospacedDigit()
                                }
                                Slider(value: Binding(
                                    get: { abs(tracker.pitchDownThreshold) },
                                    set: { tracker.pitchDownThreshold = -$0 }
                                ), in: 0.08...0.40, step: 0.02)
                                Text("Valori più bassi = allarme più severo se abbassi la testa.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Rotazione orizzontale")
                                    Spacer()
                                    Text(String(format: "%.2f rad", tracker.yawThreshold))
                                        .foregroundColor(.secondary)
                                        .monospacedDigit()
                                }
                                Slider(value: $tracker.yawThreshold, in: 0.15...0.60, step: 0.02)
                            }
                            
                            Divider()
                            
                            Toggle("Rileva occhi chiusi (anti-sonno)", isOn: $tracker.checkEyesClosed)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // SECTION: Audio
                    GroupBox("Audio") {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Audio \"MOOSECA!\" all'allarme", isOn: $soundManager.isMoosecaAudioEnabled)
                            
                            Button(action: { soundManager.playMoosecaAudio() }) {
                                Label("Ascolta Anteprima", systemImage: "speaker.wave.3.fill")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 440, height: 500)
    }
}
