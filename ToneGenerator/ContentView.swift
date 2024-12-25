//
//  ContentView.swift
//  ToneGenerator
//
//  Created by Matthew Gallagher on 1/12/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngine()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Raindrop Generator")
                .font(.title)
            
            VStack(alignment: .leading) {
                Text("Sample interval: \(audioEngine.sampleInterval)")
                Slider(value: $audioEngine.sampleInterval, in: 0...10)
                
                Text("Randomness: \(Int(audioEngine.randomness * 100))%")
                Slider(value: $audioEngine.randomness, in: 0...1)
                
                Text("Volume: \(Int(audioEngine.volume * 100))%")
                Slider(value: $audioEngine.volume, in: 0...1)
            }
            .padding(.horizontal)
            
            Button {
                try? audioEngine.start()
            } label: {
                Text("Generate Drop")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
