import AVFoundation
import Foundation

class AudioEngine: ObservableObject {
    private struct Raindrop {
        var currentSample: Int = 0
        var tInit: Double = 0.001
        var deltaT1: Double = 0.002
        var deltaT2: Double = 0.006
        var deltaT3: Double = 0.012
        var a0: Double = 0.5
        var a1: Double = 1.2
        var frequency: Double = 1000.0
        var decayRate: Double = 6.0
        
        mutating func generateSample(time: Double, sampleRate: Double) -> Double {
            if time < tInit {
                return 0.0
            } else if time < (tInit + deltaT1) {
                let t = .pi * (time - tInit) / deltaT1 - 0.5 * .pi
                return a0 * cos(t)
            } else if time < (tInit + deltaT2) {
                return 0.0
            } else if time < (tInit + deltaT3) {
                let bubbleTime = time - tInit - deltaT2
                let decay = exp(-decayRate * bubbleTime / (deltaT3 - deltaT2))
                return decay * a1 * sin(2.0 * .pi * frequency * bubbleTime)
            }
            return 0.0
        }
    }
    
    private var engine: AVAudioEngine
    private var mainMixer: AVAudioMixerNode
    private var player: AVAudioSourceNode?
    private var sampleRate: Double
    private var raindrops: [Raindrop] = []
    private var lastDropTime: Double = 0
    
    @Published var volume: Double = 0.5
    @Published var dropsPerMinute: Double = 1200 {  // One drop per second by default
        didSet {
            updateDropInterval()
        }
    }
    @Published var sampleInterval: Double = 8
    @Published var randomness: Double = 0.5
    
    private var dropInterval: Double = 1.0  // Time between drops in seconds
    private var currentTime: Double = 0.0
    
    @Published private(set) var isRunning: Bool = false
    
    init() {
        engine = AVAudioEngine()
        mainMixer = engine.mainMixerNode
        sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        updateDropInterval()
        
        let player = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList in
            guard let self = self else { return noErr }
            return self.generateAudio(audioBufferList: audioBufferList, frameCount: frameCount)
        }
        self.player = player
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: mainMixer, format: format)
        engine.connect(mainMixer, to: engine.outputNode, format: format)
        mainMixer.outputVolume = 1.0
    }
    
    private func updateDropInterval() {
        dropInterval = 60.0 / dropsPerMinute
    }
    
    private func createNewRaindrop() -> Raindrop {
        var drop = Raindrop()
        
        // Randomize parameters based on drop size
        let intervalCoeff = sampleInterval
        let freqCoeff = randomness
        
        // Timing parameters
        drop.deltaT1 = intervalCoeff * Double.random(in: 0...0.002)
        drop.deltaT2 = 0.002 + intervalCoeff * Double.random(in: 0...0.004)
        drop.deltaT3 = 0.006 + intervalCoeff * Double.random(in: 0...0.006)
        
        // Sound parameters
        drop.decayRate = 3.0 + freqCoeff * Double.random(in: 0...12)
        drop.frequency = 500.0 + freqCoeff * Double.random(in: 0...2000)
        
        return drop
    }
    
    private func generateAudio(
        audioBufferList: UnsafeMutablePointer<AudioBufferList>,
        frameCount: AVAudioFrameCount
    ) -> OSStatus {
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let frameLength = Int(frameCount)
        
        for frame in 0..<frameLength {
            // Check if it's time to add a new raindrop
            if currentTime - lastDropTime >= dropInterval {
                raindrops.append(createNewRaindrop())
                lastDropTime = currentTime + dropInterval * Double.random(in: (-2 * randomness)...(4 * randomness))
            }
            
            // Sum the samples from all active raindrops
            var sample: Double = 0.0
            raindrops = raindrops.filter { drop in
                let dropTime = Double(drop.currentSample) / sampleRate
                return dropTime < (drop.tInit + drop.deltaT3)  // Keep drop if it hasn't finished playing
            }
            
            for i in 0..<raindrops.count {
                let dropTime = Double(raindrops[i].currentSample) / sampleRate
                sample += raindrops[i].generateSample(time: dropTime, sampleRate: sampleRate)
                raindrops[i].currentSample += 1
            }
            
            // Apply volume and write to buffer
            let finalSample = sample * volume
            
            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                buf[frame] = Float(finalSample)
            }
            
            currentTime += 1.0 / sampleRate
        }
        
        return noErr
    }
    

    func start() throws {
        try engine.start()
        isRunning = true
    }
    
    func stop() {
        engine.stop()
        isRunning = false
    }
}
