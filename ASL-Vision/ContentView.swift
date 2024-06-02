//
//  ContentView.swift
//  ASL-Vision
//
//  Created by Karan . on 6/1/24.
//

import SwiftUI
import Vision
import AVKit


struct ContentView: View {
    @StateObject private var videoProcessor = VideoProcessor()
        
    
    var body: some View {
         VStack {
             VideoPlayer(player: videoProcessor.player)
                 .frame(height: 300)
             Text(videoProcessor.result)
                 .font(.largeTitle)
                 .padding()
             Button("Process Video") {
                 videoProcessor.setupVision()
                 videoProcessor.processVideo()
             }
         }
         .onAppear {
             videoProcessor.setupVision()
         }
     }
 }

#Preview {
    ContentView()
}
