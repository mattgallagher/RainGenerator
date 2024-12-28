//
//  ContentView.swift
//  RainGenerator
//
//  Created by Matthew Gallagher on 1/12/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngine()
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Sample interval: \(audioEngine.sampleInterval)")
                Slider(value: $audioEngine.sampleInterval, in: 0.5...50)
                
                Text("Randomness: \(Int(audioEngine.randomness * 100))%")
                Slider(value: $audioEngine.randomness, in: 0...1)
                
                Text("Drops per minute: \(Int(audioEngine.dropsPerMinute))")
                Slider(value: $audioEngine.dropsPerMinute, in: 60...10000)
                
                Text("Volume: \(Int(audioEngine.volume * 100))%")
                Slider(value: $audioEngine.volume, in: 0...1)
            }
            .padding(.horizontal)
            
            Button {
                if audioEngine.isRunning {
                    audioEngine.stop()
                } else {
                    try?audioEngine.start()
                }
            } label: {
                Text(audioEngine.isRunning ? "Stop" : "Start")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
