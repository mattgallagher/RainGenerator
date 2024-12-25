import AVFoundation
import Foundation

class AudioEngine: ObservableObject {
    private var engine: AVAudioEngine
    private var mainMixer: AVAudioMixerNode
    private var player: AVAudioSourceNode?
    private var sampleRate: Double
    private var currentSample: Int = 0
    private let duration: Double = 2.0
    
    // Raindrop timing parameters
    private var tInit: Double = 0.001
    private var deltaT1: Double = 0.002
    private var deltaT2: Double = 0.006
    private var deltaT3: Double = 0.012
    
    // Raindrop sound parameters
    private var a0: Double = 1.0
    private var a1: Double = 1.2
    private var frequency: Double = 1500.0
    private var decayRate: Double = 6.0
    
    @Published var volume: Double = 0.5
    @Published var sampleInterval: Double = 1 {  // 0.0-10 range affects sound characteristics
        didSet {
            updateRaindropParameters()
        }
    }
    @Published var randomness: Double = 0.5 {  // 0-1 range affects sound characteristics
        didSet {
            updateRaindropParameters()
        }
    }
    
    init() {
        engine = AVAudioEngine()
        mainMixer = engine.mainMixerNode
        sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        
        updateRaindropParameters()
        
        let player = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList in
            guard let self = self else { return noErr }
            return self.generateRaindrop(audioBufferList: audioBufferList, frameCount: frameCount)
        }
        self.player = player
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: mainMixer, format: format)
        engine.connect(mainMixer, to: engine.outputNode, format: format)
        mainMixer.outputVolume = 1.0
    }
    
    private func updateRaindropParameters() {
        // Randomize parameters based on drop size
        let intervalCoeff = sampleInterval
        let freqCoeff = randomness
        
        // Timing parameters
        deltaT1 = intervalCoeff * Double.random(in: 0...0.002)
        deltaT2 = 0.002 + intervalCoeff * Double.random(in: 0...0.004)
        deltaT3 = 0.006 + intervalCoeff * Double.random(in: 0...0.006)
        
        // Sound parameters
        a0 = 1.0
        a1 = 1.2
        decayRate = 3.0 + freqCoeff * Double.random(in: 0...12)
        frequency = 1000.0 + freqCoeff * Double.random(in: 0...1000)
    }
    
    private func generateRaindrop(
        audioBufferList: UnsafeMutablePointer<AudioBufferList>,
        frameCount: AVAudioFrameCount
    ) -> OSStatus {
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let frameLength = Int(frameCount)
        let totalSamples = Int(sampleRate * duration)
        
        for frame in 0..<frameLength {
            if currentSample >= totalSamples {
                DispatchQueue.main.async {
                    self.stop()
                }
                return noErr
            }
            
            let time = Double(currentSample) / sampleRate
            
            var sample: Double
            if time < tInit {
                // Silent initial period
                sample = 0.0
            } else if time < (tInit + deltaT1) {
                // Initial impact sound
                let t = 2.0 * (time - tInit) / deltaT1 - 1.0
                sample = a0 * (acos(t * t) * 2.0 / .pi)
            } else if time < (tInit + deltaT2) {
                // Silent gap between impact and bubble
                sample = 0.0
            } else if time < (tInit + deltaT3) {
                // Bubble oscillation
                let bubbleTime = time - tInit - deltaT2
                let decay = exp(-decayRate * bubbleTime / (deltaT3 - deltaT2))
                sample = decay * a1 * sin(2.0 * .pi * frequency * bubbleTime)
            } else {
                sample = 0
            }
            
            // Apply volume
            let finalSample = sample * volume
            
            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                buf[frame] = Float(finalSample)
            }
            
            currentSample += 1
        }
        return noErr
    }
    
    func start() throws {
        currentSample = 0
        updateRaindropParameters()  // Generate new random parameters for each drop
        try engine.start()
    }
    
    func stop() {
        engine.stop()
    }
}
