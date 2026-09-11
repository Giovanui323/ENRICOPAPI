import Foundation
import Vision
import CoreMedia
import Combine

public struct GazeStatus: Sendable {
    public var isFaceDetected: Bool = false
    public var isDistracted: Bool = false
    public var distractionReason: String = ""
    public var yaw: Double = 0.0
    public var pitch: Double = 0.0
    public var roll: Double = 0.0
    public var leftEyeOpenness: Double = 1.0
    public var rightEyeOpenness: Double = 1.0
    public var pupilVerticalOffset: Double = 0.0
    public var continuousDistractionTime: TimeInterval = 0.0
}

final class FaceTracker: ObservableObject, @unchecked Sendable {
    static let shared = FaceTracker()
    
    @Published var currentStatus = GazeStatus()
    @Published var isDistractionAlertActive: Bool = false
    @Published var alertReason: String = ""
    @Published var distractionCount: Int = 0
    
    // User configurable thresholds
    @Published var toleranceSeconds: Double = 1.5
    @Published var yawThreshold: Double = 0.28          // ~16 degrees
    @Published var pitchDownThreshold: Double = -0.16   // Downward head tilt
    @Published var checkEyesClosed: Bool = true
    @Published var eyeOpennessThreshold: Double = 0.15
    @Published var isTrackingActive: Bool = false {
        didSet {
            if !isTrackingActive {
                distractionStartTime = nil
            }
        }
    }
    
    private var distractionStartTime: Date? = nil
    private let sequenceHandler = VNSequenceRequestHandler()
    private let visionQueue = DispatchQueue(label: "com.enricopapi.vision", qos: .userInitiated)
    private var isProcessingFrame = false
    private var startupGraceUntil = Date().addingTimeInterval(3.5)
    
    // Callback for overlay trigger
    var onDistractionTriggered: (@Sendable (String) -> Void)?
    var onDistractionResolved: (@Sendable () -> Void)?
    
    private init() {}
    
    func resetDistractionCount() {
        DispatchQueue.main.async {
            self.distractionCount = 0
        }
    }
    
    func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        visionQueue.async { [weak self] in
            autoreleasepool {
                guard let self = self else { return }
                guard self.isTrackingActive else { return }
                guard !self.isProcessingFrame else { return }
                
                self.isProcessingFrame = true
                defer { self.isProcessingFrame = false }
                
                let request = VNDetectFaceLandmarksRequest()
                do {
                    try self.sequenceHandler.perform([request], on: pixelBuffer, orientation: .leftMirrored)
                    let observations = request.results
                    self.handleVisionResults(observations)
                } catch {
                    // Vision error fallback
                }
            }
        }
    }
    
    private func handleVisionResults(_ observations: [VNFaceObservation]?) {
        guard isTrackingActive else { return }
        
        guard let observations = observations, let face = observations.first else {
            // No face visible
            registerDistractionSample(
                isDistracted: true,
                reason: "Nessun volto rilevato (ti sei allontanato!)",
                yaw: 0,
                pitch: 0,
                roll: 0,
                faceDetected: false
            )
            return
        }
        
        let yaw = face.yaw?.doubleValue ?? 0.0
        let pitch = face.pitch?.doubleValue ?? 0.0
        let roll = face.roll?.doubleValue ?? 0.0
        
        var isDistracted = false
        var reason = ""
        
        // Check 1: Head pitch (Looking down at smartphone/desk)
        if pitch < pitchDownThreshold {
            isDistracted = true
            reason = "Sguardo in basso (stai guardando il telefono!)"
        }
        // Check 2: Head yaw (Head turned left or right away from monitor)
        else if abs(yaw) > yawThreshold {
            isDistracted = true
            let dir = yaw > 0 ? "destra" : "sinistra"
            reason = "Testa voltata a \(dir) (guarda lo schermo!)"
        }
        
        // Check 3: Eye openness and pupil gaze if landmarks are present
        var leftOpenness: Double = 1.0
        var rightOpenness: Double = 1.0
        var pupilOffset: Double = 0.0
        
        if let landmarks = face.landmarks {
            if let leftEye = landmarks.leftEye {
                leftOpenness = calculateEyeAspect(points: leftEye.normalizedPoints)
            }
            if let rightEye = landmarks.rightEye {
                rightOpenness = calculateEyeAspect(points: rightEye.normalizedPoints)
            }
            
            // Pupil vertical check relative to eye center
            if let leftPupil = landmarks.leftPupil?.normalizedPoints.first,
               let leftEye = landmarks.leftEye {
                let eyeCenterY = leftEye.normalizedPoints.map { $0.y }.reduce(0, +) / Double(max(1, leftEye.normalizedPoints.count))
                pupilOffset = leftPupil.y - eyeCenterY
                
                // If eyes are looking down sharply
                if pupilOffset < -0.06 && !isDistracted {
                    isDistracted = true
                    reason = "Occhi puntati in basso (posa il telefono!)"
                }
            }
            
            // Eyes closed check
            if checkEyesClosed && (leftOpenness < eyeOpennessThreshold && rightOpenness < eyeOpennessThreshold) {
                if !isDistracted {
                    isDistracted = true
                    reason = "Occhi chiusi (non dormire, studia!)"
                }
            }
        }
        
        registerDistractionSample(
            isDistracted: isDistracted,
            reason: reason,
            yaw: yaw,
            pitch: pitch,
            roll: roll,
            faceDetected: true,
            leftEyeOpenness: leftOpenness,
            rightEyeOpenness: rightOpenness,
            pupilOffset: pupilOffset
        )
    }
    
    private func registerDistractionSample(
        isDistracted: Bool,
        reason: String,
        yaw: Double,
        pitch: Double,
        roll: Double,
        faceDetected: Bool,
        leftEyeOpenness: Double = 1.0,
        rightEyeOpenness: Double = 1.0,
        pupilOffset: Double = 0.0
    ) {
        let now = Date()
        var continuousTime: TimeInterval = 0
        
        // Grace period on app launch to let user settle
        if now < startupGraceUntil {
            let status = GazeStatus(
                isFaceDetected: faceDetected,
                isDistracted: false,
                distractionReason: "Calibrazione iniziale fotocamera...",
                yaw: yaw,
                pitch: pitch,
                roll: roll,
                leftEyeOpenness: leftEyeOpenness,
                rightEyeOpenness: rightEyeOpenness,
                pupilVerticalOffset: pupilOffset,
                continuousDistractionTime: 0
            )
            DispatchQueue.main.async {
                self.currentStatus = status
            }
            distractionStartTime = nil
            return
        }
        
        var shouldTriggerAlert = false
        
        if isDistracted {
            if let start = distractionStartTime {
                continuousTime = now.timeIntervalSince(start)
            } else {
                distractionStartTime = now
                continuousTime = 0
            }
            
            // Trigger overlay if distraction exceeds tolerance
            if continuousTime >= toleranceSeconds && !isDistractionAlertActive {
                shouldTriggerAlert = true
            }
        } else {
            // User is looking at the screen
            distractionStartTime = nil
            continuousTime = 0
        }
        
        let status = GazeStatus(
            isFaceDetected: faceDetected,
            isDistracted: isDistracted,
            distractionReason: isDistracted ? reason : "Concentrato sul computer",
            yaw: yaw,
            pitch: pitch,
            roll: roll,
            leftEyeOpenness: leftEyeOpenness,
            rightEyeOpenness: rightEyeOpenness,
            pupilVerticalOffset: pupilOffset,
            continuousDistractionTime: continuousTime
        )
        
        DispatchQueue.main.async {
            self.currentStatus = status
            
            if shouldTriggerAlert {
                self.isDistractionAlertActive = true
                self.alertReason = reason
                self.distractionCount += 1
                self.onDistractionTriggered?(reason)
            } else if self.isDistractionAlertActive && !isDistracted && faceDetected {
                self.onDistractionResolved?()
            }
        }
    }
    
    private func calculateEyeAspect(points: [CGPoint]) -> Double {
        guard points.count >= 6 else { return 0.25 }
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 1
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 1
        
        let width = max(0.001, maxX - minX)
        let height = maxY - minY
        return height / width
    }
}
