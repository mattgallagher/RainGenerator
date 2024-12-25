import AVFoundation
import Foundation

@Observable
class AudioEngine {
    struct Raindrop: Equatable {
        fileprivate var currentSample: Int = 0
        fileprivate var sampleRate: Float = 44100
        var tInit: Float = 0.001
        var deltaT1: Float = 0.0075
        var deltaT2: Float = 0.015
        var deltaT3: Float = 0.030
        var a1: Float = 0.4
        var a2: Float = 0.7
        var frequency: Float = 400.0
        
        var time: Float {
            Float(currentSample) / sampleRate
        }
        
        mutating func generateSample() -> Float {
            let time = self.time
            currentSample += 1
            if time < tInit {
                return 0.0
            } else if time < deltaT1 {
                let t = .pi * (time - tInit) / (deltaT1 - tInit) - 0.5 * .pi
                return a1 * cos(t)
            } else if time < deltaT2 {
                return 0.0
            } else if time < deltaT3 {
                let bubbleTime = time - deltaT2
                let decay = exp(-6 * bubbleTime / (deltaT3 - deltaT2))
                let expand = exp(0.5 * bubbleTime / (deltaT3 - deltaT2))
                return decay * a2 * sin(2.0 * .pi * frequency * bubbleTime * expand)
            } else if time < deltaT3 + tInit {
                return 0.0
            }
            return 0.0
        }
    }
    
    struct Parameters: Equatable {
        var raindrop = Raindrop()
        
        var volume: Float = 0.5
        var dropsPerMinute: Float = 300
        var dropRandomness: Float = 1.0
        var frequencyRandomness: Float = 0.75
        var pinkNoise: Float = 0.025
        var brownNoise: Float = 0.05
        var whiteNoise: Float = 0.0

        func createNewRaindrop(fixedValue: Bool, sampleRate: Float) -> Raindrop {
            var newDrop = raindrop
            newDrop.sampleRate = sampleRate
            
            // Timing parameters
            newDrop.deltaT1 = newDrop.tInit + Float.randomnessAroundMidpoint(randomness: fixedValue ? 0 : dropRandomness, midpoint: newDrop.deltaT1)
            newDrop.deltaT2 = newDrop.deltaT1 + Float.randomnessAroundMidpoint(randomness: fixedValue ? 0 : dropRandomness, midpoint: newDrop.deltaT2)
            newDrop.deltaT3 = newDrop.deltaT2 + Float.randomnessAroundMidpoint(randomness: fixedValue ? 0 : dropRandomness, midpoint: newDrop.deltaT3)
            
            // Sound parameters
            newDrop.frequency = Float.randomnessAroundMidpoint(randomness: fixedValue ? 0 : dropRandomness, midpoint: newDrop.frequency)
            
            return newDrop
        }
    }
    
    struct GeneratorState {
        var currentTime: Float = 0.0
        var raindrops: [Raindrop] = []
        var nextDropTime: Float = 0
        var pinkNoiseState: [Float] = Array(repeating: 0.0, count: 7)
        var brownNoiseState: Float = 0.0

        mutating func generatePinkNoise() -> Float {
            let white = Float.random(in: -1.0...1.0)
            pinkNoiseState[0] = 0.99886 * pinkNoiseState[0] + white * 0.0555179
            pinkNoiseState[1] = 0.99332 * pinkNoiseState[1] + white * 0.0750759
            pinkNoiseState[2] = 0.96900 * pinkNoiseState[2] + white * 0.1538520
            pinkNoiseState[3] = 0.86650 * pinkNoiseState[3] + white * 0.3104856
            pinkNoiseState[4] = 0.55000 * pinkNoiseState[4] + white * 0.5329522
            pinkNoiseState[5] = -0.7616 * pinkNoiseState[5] - white * 0.0168980
            let pink = pinkNoiseState[0] + pinkNoiseState[1] + pinkNoiseState[2] + pinkNoiseState[3] + pinkNoiseState[4] + pinkNoiseState[5] + pinkNoiseState[6] + white * 0.5362
            pinkNoiseState[6] = white * 0.115926
            return pink
        }
        
        func generateWhiteNoise() -> Float {
            return Float.random(in: -1.0...1.0)
        }
        
        mutating func generateBrownNoise() -> Float {
            let white = Float.random(in: -1.0...1.0)
            brownNoiseState = (brownNoiseState + white).clamped(to: -1.0...1.0)
            return brownNoiseState
        }
    }

    private var engine: AVAudioEngine
    private var mainMixer: AVAudioMixerNode
    private var player: AVAudioSourceNode?
    private(set) var sampleRate: Float
    
    var parameters = Parameters()
    private var generatorState = GeneratorState()
    
    private(set) var isRunning: Bool = false
    
    init() {
        let engine = AVAudioEngine()
        self.engine = engine
        mainMixer = engine.mainMixerNode
        let outputFormat = engine.outputNode.outputFormat(forBus: 0)
        let playerFormat = AVAudioFormat(standardFormatWithSampleRate: outputFormat.sampleRate, channels: 1)!
        sampleRate = Float(playerFormat.sampleRate)
        
        let player = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList in
            guard let self = self else { return noErr }
            return self.generateAudio(audioBufferList: audioBufferList, frameCount: frameCount)
        }
        self.player = player
        
        engine.attach(player)
        engine.connect(player, to: mainMixer, format: playerFormat)
        engine.connect(mainMixer, to: engine.outputNode, format: playerFormat)
        mainMixer.outputVolume = 1.0
    }
    
    func raindropSampleCount() -> Int {
        let newDrop = parameters.createNewRaindrop(fixedValue: true, sampleRate: sampleRate)
        return Int((newDrop.deltaT3 + newDrop.tInit) * sampleRate)
    }
    
    func generateWaveform(samples: Int) -> [Float] {
        var waveform: [Float] = []
        var raindrop = parameters.createNewRaindrop(fixedValue: true, sampleRate: sampleRate)
        
        for _ in 0..<samples {
            let sample = raindrop.generateSample()
            waveform.append(sample)
        }
        return waveform
    }
    
    private func generateAudio(
        audioBufferList: UnsafeMutablePointer<AudioBufferList>,
        frameCount: AVAudioFrameCount
    ) -> OSStatus {
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let frameLength = Int(frameCount)
        
        let dropInterval = 60.0 / parameters.dropsPerMinute
        for frame in 0..<frameLength {
            // Check if it's time to add a new raindrop
            if generatorState.currentTime >= generatorState.nextDropTime {
                generatorState.raindrops.append(parameters.createNewRaindrop(fixedValue: false, sampleRate: sampleRate))
                generatorState.nextDropTime = generatorState.currentTime + Float.randomnessAroundMidpoint(randomness: 0.95 * parameters.frequencyRandomness, midpoint: dropInterval)
            }
            
            // Sum the samples from all active raindrops
            var sample: Float = 0.0
            generatorState.raindrops = generatorState.raindrops.filter { drop in
                return drop.time < (drop.deltaT3 + drop.tInit)  // Keep drop if it hasn't finished playing
            }
            
            for i in 0..<generatorState.raindrops.count {
                sample += generatorState.raindrops[i].generateSample()
                generatorState.raindrops[i].currentSample += 1
            }
            
            // Add pink noise to the sample
            sample += generatorState.generateWhiteNoise() * parameters.whiteNoise + parameters.brownNoise * generatorState.generateBrownNoise() + generatorState.generatePinkNoise() * parameters.pinkNoise
            
            // Write the sample to all channels
            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                buf[frame] = sample * parameters.volume
            }
            
            generatorState.currentTime += 1.0 / sampleRate
        }
        
        return noErr
    }

    func start() throws {
        generatorState = GeneratorState()
        try engine.start()
        isRunning = true
    }
    
    func stop() {
        engine.stop()
        isRunning = false
    }
}

extension Float {
    func clamped(to: ClosedRange<Float>) -> Float {
        if self < to.lowerBound {
            return to.lowerBound
        } else if self > to.upperBound {
            return to.upperBound
        } else {
            return self
        }
    }
    
    static func randomnessAroundMidpoint(randomness: Float, midpoint: Float) -> Float {
        if randomness != 0 {
            let scale = randomness > 1 ? randomness : 1
            let scaledRandomness = randomness > 1 ? 1 : randomness
            return Float.random(in: (scale * midpoint * (1 - scaledRandomness))...(scale * midpoint * (1 + scaledRandomness)))
        } else {
            return midpoint
        }
    }
}
