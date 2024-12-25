//
//  ContentView.swift
//  ToneGenerator
//
//  Created by Matthew Gallagher on 1/12/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngine()
    
    enum WaveType: String, CaseIterable {
        case sine = "Sine Wave"
        case square = "Square Wave"
        case sawtooth = "Sawtooth Wave"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tone Generator")
                .font(.title)
            
            Picker("Wave Type", selection: $audioEngine.waveType) {
                ForEach(WaveType.allCases, id: \.self) { waveType in
                    Text(waveType.rawValue)
                }
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading) {
                Text("Frequency: \(Int(audioEngine.frequency)) Hz")
                Slider(value: $audioEngine.frequency, in: 20...20000)
                
                Text("Volume: \(Int(audioEngine.volume * 100))%")
                Slider(value: $audioEngine.volume, in: 0...1)
            }
            .padding(.horizontal)
            
            Button {
                if audioEngine.isPlaying {
                    audioEngine.stop()
                } else {
                    try? audioEngine.start()
                }
            } label: {
                Text(audioEngine.isPlaying ? "Stop" : "Play")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
