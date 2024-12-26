//
//  ContentView.swift
//  RainGenerator
//
//  Created by Matthew Gallagher on 1/12/2024.
//

import SwiftUI
import Charts

struct ContentView: View {
    @State private var audioEngine = AudioEngine()
    @State private var waveform: [Float] = []

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Impact duration: \(audioEngine.parameters.raindrop.deltaT1 * 1000) milliseconds")
                    Slider(value: $audioEngine.parameters.raindrop.deltaT1, in: 0.0002...0.1)
                    
                    Text("Impact amplitude: \(audioEngine.parameters.raindrop.a1) amplitude")
                    Slider(value: $audioEngine.parameters.raindrop.a1, in: 0...1.5)
                    
                    Text("Pause duration: \(audioEngine.parameters.raindrop.deltaT2 * 1000) milliseconds")
                    Slider(value: $audioEngine.parameters.raindrop.deltaT2, in: 0.0002...0.08)
                    
                    Text("Bubble duration: \(audioEngine.parameters.raindrop.deltaT3 * 1000) milliseconds")
                    Slider(value: $audioEngine.parameters.raindrop.deltaT3, in: 0.001...0.4)
                    
                    Text("Bubble amplitude: \(audioEngine.parameters.raindrop.a2) amplitude")
                    Slider(value: $audioEngine.parameters.raindrop.a2, in: 0...1.5)

                    Text("Bubble frequency: \(audioEngine.parameters.raindrop.frequency) Hz")
                    Slider(value: $audioEngine.parameters.raindrop.frequency, in: 2...2000)
                }
                VStack(alignment: .leading) {
                    Text("Drop randomness: \(Int(audioEngine.parameters.dropRandomness * 100))%")
                    Slider(value: $audioEngine.parameters.dropRandomness, in: 0...2)
                    
                    Text("Drop rate: \(Int(audioEngine.parameters.dropsPerMinute)) per minute")
                    Slider(value: $audioEngine.parameters.dropsPerMinute, in: 20...4000)
                    
                    Text("Rate randomness: \(Int(audioEngine.parameters.frequencyRandomness * 100))%")
                    Slider(value: $audioEngine.parameters.frequencyRandomness, in: 0...1)
                    
                    Text("White noise: \(audioEngine.parameters.whiteNoise * 200)%")
                    Slider(value: $audioEngine.parameters.whiteNoise, in: 0...0.5)
                    
                    Text("Brown noise: \(audioEngine.parameters.brownNoise * 200)%")
                    Slider(value: $audioEngine.parameters.brownNoise, in: 0...0.5)
                    
                    Text("Pink noise: \(audioEngine.parameters.pinkNoise * 200)%")
                    Slider(value: $audioEngine.parameters.pinkNoise, in: 0...0.5)
                }
            }
            .padding(.horizontal)
            
            Chart {
                ForEach(Array(waveform.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", Float(index) / audioEngine.parameters.raindrop.sampleRate),
                        y: .value("Amplitude", value)
                    )
                    .foregroundStyle(by: .value("Segment", color(index: index)))
                }
            }
            .chartXAxisLabel("Seconds", position: .bottomLeading)
            .chartYScale(domain: -1.0...1.0)
            .chartLegend(position: .overlay)
            
            Text("Volume: \(Int(audioEngine.parameters.volume * 100))%")
            Slider(value: $audioEngine.parameters.volume, in: 0...1)
            
            Button {
                if audioEngine.isRunning {
                    audioEngine.stop()
                } else {
                    try? audioEngine.start()
                }
            } label: {
                Text(audioEngine.isRunning ? "Stop" : "Start").frame(maxWidth: .infinity)
            }
        }
        .padding()
        .onChange(of: audioEngine.parameters, initial: true) { _, _ in
            updateWaveform()
        }
    }
    
    private func color(index: Int) -> String {
        audioEngine.parameters.raindrop.color(index: index)
    }
    
    private func updateWaveform() {
        waveform = audioEngine.generateWaveform(samples: audioEngine.raindropSampleCount())
    }
}

private extension AudioEngine.Raindrop {
    func color(index: Int) -> String {
        switch Float(index) / sampleRate {
        case 0..<tInit: return "Padding (Initial)"
        case (tInit)..<(tInit + deltaT1): return "Impact"
        case (tInit + deltaT1)..<(tInit + deltaT1 + deltaT2): return "Pause"
        case (tInit + deltaT1 + deltaT2)..<(tInit + deltaT1 + deltaT2 + deltaT3): return "Bubble"
        default: return "Padding (Trailing)"
        }
    }
}

#Preview(
    "Content",
    traits: .fixedLayout(width: 700, height: 800)
) {
    ContentView()
}
