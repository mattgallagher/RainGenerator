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
                    Text("Impact duration: \(audioEngine.raindrop.deltaT1 * 1000) milliseconds")
                    Slider(value: $audioEngine.raindrop.deltaT1, in: 0.0002...0.1)
                        .onChange(of: audioEngine.raindrop.deltaT1) { _, _ in
                            updateWaveform()
                        }
                    
                    Text("Impact amplitude: \(audioEngine.raindrop.a1) amplitude")
                    Slider(value: $audioEngine.raindrop.a1, in: 0...1.5)
                        .onChange(of: audioEngine.raindrop.a1) { _, _ in
                            updateWaveform()
                        }
                    
                    Text("Pause duration: \(audioEngine.raindrop.deltaT2 * 1000) milliseconds")
                    Slider(value: $audioEngine.raindrop.deltaT2, in: 0.0002...0.08)
                        .onChange(of: audioEngine.raindrop.deltaT2) { _, _ in
                            updateWaveform()
                        }
                    
                    Text("Bubble duration: \(audioEngine.raindrop.deltaT3 * 1000) milliseconds")
                    Slider(value: $audioEngine.raindrop.deltaT3, in: 0.001...0.4)
                        .onChange(of: audioEngine.raindrop.deltaT3) { _, _ in
                            updateWaveform()
                        }
                    
                    Text("Bubble amplitude: \(audioEngine.raindrop.a2) amplitude")
                    Slider(value: $audioEngine.raindrop.a2, in: 0...1.5)
                        .onChange(of: audioEngine.raindrop.a2) { _, _ in
                            updateWaveform()
                        }

                    Text("Bubble frequency: \(audioEngine.raindrop.frequency) Hz")
                    Slider(value: $audioEngine.raindrop.frequency, in: 2...2000)
                        .onChange(of: audioEngine.raindrop.frequency) { _, _ in
                            updateWaveform()
                        }
                }
                VStack(alignment: .leading) {
                    Text("Drop randomness: \(Int(audioEngine.dropRandomness * 100))%")
                    Slider(value: $audioEngine.dropRandomness, in: 0...2)
                        .onChange(of: audioEngine.dropRandomness) { _, _ in
                            updateWaveform()
                        }
                    
                    Text("Drop rate: \(Int(audioEngine.dropsPerMinute)) per minute")
                    Slider(value: $audioEngine.dropsPerMinute, in: 20...4000)
                        .onChange(of: audioEngine.dropsPerMinute) { _, _ in
                            updateWaveform()
                        }
                    
                    Text("Rate randomness: \(Int(audioEngine.frequencyRandomness * 100))%")
                    Slider(value: $audioEngine.frequencyRandomness, in: 0...1)
                        .onChange(of: audioEngine.frequencyRandomness) { _, _ in
                            updateWaveform()
                        }
                    
                    Text("White noise: \(audioEngine.whiteNoise * 200)%")
                    Slider(value: $audioEngine.whiteNoise, in: 0...0.5)
                        .onChange(of: audioEngine.whiteNoise) { _, _ in
                            updateWaveform()
                        }
                    
                    Text("Brown noise: \(audioEngine.brownNoise * 200)%")
                    Slider(value: $audioEngine.brownNoise, in: 0...0.5)
                        .onChange(of: audioEngine.brownNoise) { _, _ in
                            updateWaveform()
                        }
                    
                    Text("Pink noise: \(audioEngine.pinkNoise * 200)%")
                    Slider(value: $audioEngine.pinkNoise, in: 0...0.5)
                        .onChange(of: audioEngine.pinkNoise) { _, _ in
                            updateWaveform()
                        }
                }
            }
            .padding(.horizontal)
            
            Chart {
                ForEach(Array(waveform.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", Float(index) / audioEngine.sampleRate),
                        y: .value("Amplitude", value)
                    )
                    .foregroundStyle(by: .value("Segment", colorFor(index: index)))
                }
            }
            .chartXAxisLabel("Seconds", position: .bottomLeading)
            .chartYScale(domain: -1.0...1.0)
            .chartLegend(position: .overlay)
            
            Text("Volume: \(Int(audioEngine.volume * 100))%")
            Slider(value: $audioEngine.volume, in: 0...1)
            
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
        .onAppear {
            updateWaveform()
        }
    }
    
    private func colorFor(index: Int) -> String {
        switch Float(index) / audioEngine.sampleRate {
        case 0..<audioEngine.raindrop.tInit: return "Padding (Initial)"
        case (audioEngine.raindrop.tInit)..<(audioEngine.raindrop.tInit + audioEngine.raindrop.deltaT1): return "Impact"
        case (audioEngine.raindrop.tInit + audioEngine.raindrop.deltaT1)..<(audioEngine.raindrop.tInit + audioEngine.raindrop.deltaT1 + audioEngine.raindrop.deltaT2): return "Pause"
        case (audioEngine.raindrop.tInit + audioEngine.raindrop.deltaT1 + audioEngine.raindrop.deltaT2)..<(audioEngine.raindrop.tInit + audioEngine.raindrop.deltaT1 + audioEngine.raindrop.deltaT2 + audioEngine.raindrop.deltaT3): return "Bubble"
        default: return "Padding (Trailing)"
        }
    }
    
    private func updateWaveform() {
        waveform = audioEngine.generateWaveform(samples: audioEngine.raindropSampleCount())
    }
}

#Preview(
    "Content",
    traits: .fixedLayout(width: 700, height: 800)
) {
    ContentView()
}
