import Foundation
import AVFoundation
import AppKit

final class SoundManager: NSObject, ObservableObject, @unchecked Sendable {
    static let shared = SoundManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var lastSpeechTime: Date = Date.distantPast
    
    @Published var isVoiceEnabled: Bool = true
    @Published var isMoosecaAudioEnabled: Bool = true
    @Published var speechRate: Float = 0.52
    
    private let warningPhrases: [String] = [
        "Ti ho visto! Studia, non ti distrarre!",
        "Metti giù quel telefono e torna sui libri!",
        "Mooseca! Guarda lo schermo e studia!",
        "Enrico ti sta osservando! Concentrati!",
        "Ehi! Gli esami non si preparano da soli, studia!",
        "Non guardare altrove! Rimani concentrato sul PC!",
        "Ti sei distratto! Torna a studiare subito!"
    ]
    
    override private init() {
        super.init()
        prepareAudioPlayer()
    }
    
    private func prepareAudioPlayer() {
        let possiblePaths = [
            Bundle.main.resourcePath.map { $0 + "/mooseca.wav" } ?? "",
            Bundle.main.resourcePath.map { $0 + "/mooseca.mp3" } ?? "",
            FileManager.default.currentDirectoryPath + "/Assets/mooseca.wav",
            FileManager.default.currentDirectoryPath + "/Assets/mooseca.mp3"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                let url = URL(fileURLWithPath: path)
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                    audioPlayer?.prepareToPlay()
                    break
                } catch {
                    // fallback to speech
                }
            }
        }
    }
    
    func playDistractionAlert(reason: String) {
        if isMoosecaAudioEnabled {
            playMoosecaAudio()
        }
        
        if isVoiceEnabled {
            let now = Date()
            if now.timeIntervalSince(lastSpeechTime) > 3.0 {
                lastSpeechTime = now
                speakRandomWarning(reason: reason)
            }
        }
    }
    
    func playMoosecaAudio() {
        if audioPlayer == nil {
            prepareAudioPlayer()
        }
        
        if let player = audioPlayer {
            player.stop()
            player.currentTime = 0
            player.volume = 1.0
            player.play()
        } else {
            NSSound.beep()
        }
    }
    
    func playPraise() {
        guard isVoiceEnabled else { return }
        let praises = [
            "Bravo, continua a studiare!",
            "Bentornato! Ottima concentrazione!",
            "Così mi piaci! Avanti tutta!"
        ]
        let phrase = praises.randomElement() ?? praises[0]
        speak(text: phrase)
    }
    
    private func speakRandomWarning(reason: String) {
        let phrase: String
        if reason.contains("telefono") || reason.contains("basso") {
            phrase = "Metti giù quel telefono e torna a studiare!"
        } else if reason.contains("occhi") || reason.contains("dorm") {
            phrase = "Non dormire! Sveglia e studia!"
        } else {
            phrase = warningPhrases.randomElement() ?? warningPhrases[0]
        }
        speak(text: phrase)
    }
    
    func speak(text: String) {
        DispatchQueue.main.async {
            self.synthesizer.stopSpeaking(at: .immediate)
            
            let utterance = AVSpeechUtterance(string: text)
            // Use Italian voice
            utterance.voice = AVSpeechSynthesisVoice(language: "it-IT") ?? AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = self.speechRate
            utterance.pitchMultiplier = 1.15
            utterance.volume = 1.0
            
            self.synthesizer.speak(utterance)
        }
    }
}
