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
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. SFONDO CON LA FACCIA DI PAPI OVUNQUE (Subtle Watermark Mosaic)
                if let tiled = PapiPatternCache.shared.getTiledImage(for: geo.size) {
                    Image(nsImage: tiled)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .opacity(0.16)
                }
                
                // 2. SFUMATURA VIBRANT DARK MACOS GLASS
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.70),
                        Color(nsColor: .windowBackgroundColor).opacity(0.85),
                        Color.black.opacity(0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // 3. CONTENUTO PRINCIPALE IN CARD MODERNE MACOS
                VStack(spacing: 16) {
                    // SUBHEADER MINIMALE (Nessuna icona qui, l'icona è nella barra dell'app!)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Papi Focus")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(colors: [.white, .yellow.opacity(0.9)], startPoint: .leading, endPoint: .trailing)
                                )
                            Text("STUDIA, NON TI DISTRARRE!")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        // Allarme Live Pill
                        HStack(spacing: 6) {
                            Circle()
                                .fill(tracker.isTrackingActive ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(tracker.isTrackingActive ? "ALLARME ATTIVO" : "STANDBY")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(tracker.isTrackingActive ? .green : .secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(tracker.isTrackingActive ? Color.green.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    
                    // WEBCAM MONITOR CARD CON CORNICE VIBRANTE MACOS
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.black.opacity(0.88))
                            .frame(width: 440, height: 250)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(statusBorderColor, lineWidth: 3)
                                    .shadow(color: statusBorderColor.opacity(0.5), radius: 8)
                            )
                        
                        if let image = cameraManager.currentFrame {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 436, height: 246)
                                .cornerRadius(16)
                                .clipped()
                        } else {
                            VStack(spacing: 10) {
                                ProgressView()
                                Text(cameraManager.permissionGranted ? "Avvio fotocamera..." : "Richiesta permessi fotocamera...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Overlay Top Badges (Stato concentrazione & Papi Tag)
                        VStack {
                            HStack {
                                // Status Tag
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(statusColor)
                                        .frame(width: 9, height: 9)
                                        .shadow(color: statusColor, radius: 4)
                                    
                                    Text(statusText)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    if tracker.isTrackingActive && tracker.currentStatus.isDistracted && tracker.currentStatus.continuousDistractionTime > 0 {
                                        Text(String(format: "(%.1fs)", tracker.currentStatus.continuousDistractionTime))
                                            .font(.system(size: 11, weight: .black, design: .monospaced))
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.black.opacity(0.80))
                                .cornerRadius(14)
                                
                                Spacer()
                                
                                // Enrico Papi Watermark Tag
                                HStack(spacing: 5) {
                                    if let icon = loadPapiMiniIcon() {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 14, height: 14)
                                            .clipShape(Circle())
                                    }
                                    Text("Papi Watch")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.yellow)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.75))
                                .cornerRadius(10)
                            }
                            .padding(10)
                            
                            Spacer()
                        }
                    }
                    
                    // CARD CONTROLLO STUDIO & TIMER (L'allarme si attiva solo quando attivato)
                    VStack(spacing: 12) {
                        // Selettore Durata Studio (visibile prima di avviare)
                        if !isPomodoroRunning {
                            HStack(spacing: 6) {
                                Text("Durata:")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                ForEach([15, 25, 30, 45, 60], id: \.self) { mins in
                                    Button("\(mins)m") {
                                        studyDurationMinutes = mins
                                        pomodoroSecondsRemaining = mins * 60
                                    }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 11, weight: studyDurationMinutes == mins ? .black : .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(studyDurationMinutes == mins ? Color.orange : Color(nsColor: .controlBackgroundColor).opacity(0.8))
                                    .foregroundColor(studyDurationMinutes == mins ? .white : .primary)
                                    .cornerRadius(6)
                                }
                                
                                Spacer()
                                
                                // Stepper [-] [+]
                                HStack(spacing: 2) {
                                    Button(action: {
                                        if studyDurationMinutes > 5 {
                                            studyDurationMinutes -= 5
                                            pomodoroSecondsRemaining = studyDurationMinutes * 60
                                        }
                                    }) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 10, weight: .bold))
                                            .frame(width: 22, height: 22)
                                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                                            .cornerRadius(4)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Text("\(studyDurationMinutes)m")
                                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                        .frame(width: 36)
                                    
                                    Button(action: {
                                        if studyDurationMinutes < 180 {
                                            studyDurationMinutes += 5
                                            pomodoroSecondsRemaining = studyDurationMinutes * 60
                                        }
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 10, weight: .bold))
                                            .frame(width: 22, height: 22)
                                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                                            .cornerRadius(4)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        
                        // Grande Display Digitale del Timer
                        HStack(alignment: .firstTextBaseline) {
                            Label(isBreakMode ? "Pausa Caffè" : "Sessione di Studio", systemImage: isBreakMode ? "cup.and.saucer.fill" : "book.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(isBreakMode ? .green : .secondary)
                            
                            Spacer()
                            
                            Text(formatTime(pomodoroSecondsRemaining))
                                .font(.system(size: 38, weight: .heavy, design: .rounded))
                                .foregroundColor(isBreakMode ? .green : (isPomodoroRunning ? .yellow : .primary))
                                .shadow(color: (isPomodoroRunning ? Color.yellow.opacity(0.4) : Color.clear), radius: 8)
                        }
                        .padding(.horizontal, 6)
                        
                        // Pulsanti di Avvio Studio & Reset
                        HStack(spacing: 12) {
                            Button(action: togglePomodoro) {
                                HStack(spacing: 8) {
                                    Image(systemName: isPomodoroRunning ? "pause.fill" : "play.fill")
                                    Text(isPomodoroRunning ? "Metti in Pausa (Disattiva Allarme)" : "Avvia Studio e Allarme (\(studyDurationMinutes) min)")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    isPomodoroRunning ?
                                    LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing) :
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
                                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .help("Azzera Timer e Disattiva Allarme")
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.65))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    )
                    .padding(.horizontal, 22)
                    
                    // FOOTER: STATISTICHE DISTRAZIONI CON AVATAR DI PAPI
                    HStack {
                        HStack(spacing: 8) {
                            if let icon = loadPapiMiniIcon() {
                                Image(nsImage: icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .clipShape(Circle())
                            }
                            Text("Beccato da Papi:")
                                .foregroundColor(.secondary)
                            Text("\(tracker.distractionCount) \(tracker.distractionCount == 1 ? "volta" : "volte")")
                                .fontWeight(.bold)
                                .foregroundColor(tracker.distractionCount > 0 ? .orange : .primary)
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
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(width: 480, height: 570)
        // BARRA NATIVA MACOS (L'icona e il nome stanno QUI nella barra, non nella pagina iniziale!)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 8) {
                    if let icon = loadAppIcon() {
                        Image(nsImage: icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .cornerRadius(5)
                            .shadow(color: .black.opacity(0.2), radius: 2)
                    }
                    Text("Papi Focus")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: triggerTestJumpscare) {
                    Label("Test Allarme", systemImage: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                }
                .help("Testa l'allarme: dovrai cliccare 'HO CAPITO' e guardare il PC per sbloccare!")
                
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12, weight: .semibold))
                }
                .help("Apri Impostazioni e Sensibilità")
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(tracker: tracker, soundManager: soundManager)
        }
    }
    
    // Helpers
    private var statusColor: Color {
        if !tracker.isTrackingActive { return .gray }
        if !tracker.currentStatus.isFaceDetected { return .red }
        if tracker.isDistractionAlertActive { return .red }
        if tracker.currentStatus.isDistracted { return .orange }
        return .green
    }
    
    private var statusBorderColor: Color {
        if !tracker.isTrackingActive { return .secondary.opacity(0.3) }
        if tracker.isDistractionAlertActive { return .red }
        if tracker.currentStatus.isDistracted { return .orange }
        return .green
    }
    
    private var statusText: String {
        if isBreakMode { return "Pausa Relax" }
        if !tracker.isTrackingActive { return "Allarme in Standby" }
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
    
    private func loadPapiMiniIcon() -> NSImage? {
        let paths = [
            Bundle.main.resourcePath.map { $0 + "/papi_pattern.jpg" } ?? "",
            FileManager.default.currentDirectoryPath + "/Assets/papi_pattern.jpg",
            "/Users/lucasicignano/ENRICOPAPI/Assets/papi_pattern.jpg"
        ]
        for path in paths {
            if let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return loadAppIcon()
    }
}

// MARK: - Dedicated Settings Sheet
struct SettingsView: View {
    @ObservedObject var tracker: FaceTracker
    @ObservedObject var soundManager: SoundManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Impostazioni & Sensibilità")
                    .font(.headline)
                Spacer()
                Button("Fine") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(18)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // SECTION 0: Attivazione Manuale
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Stato Allarme")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Toggle("Attiva allarme anti-distrazione anche fuori sessione Pomodoro", isOn: $tracker.isTrackingActive)
                            .toggleStyle(.switch)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                    
                    // SECTION 1: Soglie di Rilevamento
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Sensibilità Distrazione")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Tolleranza prima dell'allarme:")
                                Spacer()
                                Text(String(format: "%.1f secondi", tracker.toleranceSeconds))
                                    .fontWeight(.semibold)
                            }
                            Slider(value: $tracker.toleranceSeconds, in: 0.5...5.0, step: 0.5)
                            Text("Tempo in cui puoi guardare altrove prima che scatti Enrico Papi.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Inclinazione verso il basso (Telefono/Scrivania):")
                                Spacer()
                                Text(String(format: "%.2f", abs(tracker.pitchDownThreshold)))
                                    .fontWeight(.semibold)
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
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Rotazione orizzontale (Sinistra/Destra):")
                                Spacer()
                                Text(String(format: "%.2f rad", tracker.yawThreshold))
                                    .fontWeight(.semibold)
                            }
                            Slider(value: $tracker.yawThreshold, in: 0.15...0.60, step: 0.02)
                        }
                        
                        Divider()
                        
                        Toggle("Rileva occhi chiusi (anti-sonno)", isOn: $tracker.checkEyesClosed)
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
                        .buttonStyle(.plain)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color(nsColor: .windowBackgroundColor))
                        .cornerRadius(8)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                }
                .padding(20)
            }
        }
        .frame(width: 480, height: 520)
    }
}
