import Foundation
import AVFoundation

class AudioEngine: ObservableObject {
    private var engine: AVAudioEngine
    private var mainMixer: AVAudioMixerNode
    private var player: AVAudioSourceNode?
    private var sampleRate: Double
    private var currentPhase: Double = 0.0
    
    @Published var frequency: Double = 440
    @Published var volume: Double = 0.5
    @Published var waveType: ContentView.WaveType = .sine
    @Published var isPlaying = false

    init() {
        engine = AVAudioEngine()
        mainMixer = engine.mainMixerNode
        sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        
        let player = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList in
            guard let self else { return noErr }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let frameLength = Int(frameCount)
            
            for frame in 0..<frameLength {
                let sampleVal = self.generateSample(phase: self.currentPhase)
                self.currentPhase += 2.0 * Double.pi * self.frequency / self.sampleRate
                
                if self.currentPhase >= 2.0 * Double.pi {
                    self.currentPhase -= 2.0 * Double.pi
                }
                
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = Float(sampleVal * self.volume)
                }
            }
            return noErr
        }
        self.player = player
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        engine.attach(player)
        engine.connect(player, to: mainMixer, format: format)
        engine.connect(mainMixer, to: engine.outputNode, format: format)
        
        mainMixer.outputVolume = 1.0
    }
    
    private func generateSample(phase: Double) -> Double {
        // Calculate amplitude scaling factor (rough approximation)
        let amplitudeScale = 1.0 / sqrt(frequency / 440.0)
        
        let rawSignal = switch waveType {
        case .sine:
            sin(phase)
        case .square:
            phase < Double.pi ? 1.0 : -1.0
        case .sawtooth:
            1.0 - (phase / Double.pi - 1.0)
        }
        
        return rawSignal * amplitudeScale
    }
    
    func start() throws {
        try engine.start()
        isPlaying = true
    }
    
    func stop() {
        engine.stop()
        isPlaying = false
    }
} 
