import Foundation
import AVFoundation
import AppKit

@MainActor
final class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpeechTime: Date = Date.distantPast
    
    @Published var isVoiceEnabled: Bool = true
    @Published var isSoundFxEnabled: Bool = true
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
    
    private init() {}
    
    func playDistractionAlert(reason: String) {
        if isSoundFxEnabled {
            playAlertTone()
        }
        
        if isVoiceEnabled {
            // Rate limit speech to avoid overlap
            let now = Date()
            if now.timeIntervalSince(lastSpeechTime) > 3.5 {
                lastSpeechTime = now
                speakRandomWarning(reason: reason)
            }
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
        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "it-IT") ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = speechRate
        utterance.pitchMultiplier = 1.15
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    private func playAlertTone() {
        NSSound.beep()
    }
}
