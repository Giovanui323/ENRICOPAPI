import Foundation
import AVKit
import AVFoundation

@MainActor
final class OverlayVideoController: ObservableObject {
    static let shared = OverlayVideoController()
    
    @Published private(set) var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    
    private init() {}
    
    func start(url: URL, isMuted: Bool = false) {
        stop()
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let queue = AVQueuePlayer(playerItem: playerItem)
        self.looper = AVPlayerLooper(player: queue, templateItem: playerItem)
        self.player = queue
        
        queue.isMuted = isMuted
        queue.volume = 1.0
        queue.play()
    }
    
    func stop() {
        if let p = player {
            p.pause()
            p.isMuted = true
            p.removeAllItems()
        }
        player = nil
        looper = nil
    }
}
