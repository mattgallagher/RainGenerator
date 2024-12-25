//
//  ContentView.swift
//  ToneGenerator
//
//  Created by Matthew Gallagher on 1/12/2024.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var frequency: Double = 440.0
    @State private var volume: Double = 0.5
    @State private var waveform: Waveform = .sine
    private var audioEngine = AudioEngine()

    var body: some View {
        VStack {
            Picker("Waveform", selection: $waveform) {
                Text("Sine").tag(Waveform.sine)
                Text("Square").tag(Waveform.square)
                Text("Sawtooth").tag(Waveform.sawtooth)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Slider(value: $frequency, in: 20...2000, step: 1) {
                Text("Frequency")
            }
            .padding()

            Slider(value: $volume, in: 0...1) {
                Text("Volume")
            }
            .padding()

            Button("Play") {
                audioEngine.start(waveform: waveform, frequency: frequency, volume: volume)
            }
            .padding()

            Button("Stop") {
                audioEngine.stop()
            }
            .padding()
        }
        .padding()
    }
}

enum Waveform {
    case sine, square, sawtooth
}

class AudioEngine {
    private var engine = AVAudioEngine()
    private var player = AVAudioPlayerNode()
    private var buffer: AVAudioPCMBuffer?

    init() {
        engine.attach(player)
        let format = engine.outputNode.inputFormat(forBus: 0)
        engine.connect(player, to: engine.outputNode, format: format)
        try? engine.start()
    }

    func start(waveform: Waveform, frequency: Double, volume: Double) {
        let sampleRate = 44100
        let length = AVAudioFrameCount(sampleRate)
        let format = engine.outputNode.inputFormat(forBus: 0)
        buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: length)
        buffer?.frameLength = length

        let theta = 2.0 * Double.pi * frequency / Double(sampleRate)
        var currentPhase: Double = 0

        for frame in 0..<Int(length) {
            let sample: Float
            switch waveform {
            case .sine:
                sample = Float(sin(currentPhase))
            case .square:
                sample = Float(currentPhase < Double.pi ? 1.0 : -1.0)
            case .sawtooth:
                sample = Float(2.0 * (currentPhase / (2.0 * Double.pi)) - 1.0)
            }
            buffer?.floatChannelData?.pointee[frame] = sample * Float(volume)
            currentPhase += theta
            if currentPhase > 2.0 * Double.pi {
                currentPhase -= 2.0 * Double.pi
            }
        }

        player.scheduleBuffer(buffer!, at: nil, options: .loops, completionHandler: nil)
        player.play()
    }

    func stop() {
        player.stop()
    }
}

#Preview {
    ContentView()
}
