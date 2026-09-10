import Foundation
import AVFoundation
import AppKit

final class SoundManager: NSObject, ObservableObject, @unchecked Sendable {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isMoosecaAudioEnabled: Bool = true
    
    override private init() {
        super.init()
        prepareAudioPlayer()
    }
    
    func prepareAudioPlayer() {
        let possiblePaths = [
            Bundle.main.resourcePath.map { $0 + "/mooseca.wav" } ?? "",
            FileManager.default.currentDirectoryPath + "/Assets/mooseca.wav",
            "/Users/lucasicignano/ENRICOPAPI/Assets/mooseca.wav"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                let url = URL(fileURLWithPath: path)
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                    audioPlayer?.prepareToPlay()
                    break
                } catch {
                    // fallback
                }
            }
        }
    }
    
    func playDistractionAlert(reason: String) {
        guard isMoosecaAudioEnabled else { return }
        playMoosecaAudio()
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
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
    }
}
