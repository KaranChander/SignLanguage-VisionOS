import AVFoundation
import Vision
import SwiftUI
import AVKit

class VideoProcessor: ObservableObject {
    @Published var result: String = "Detecting..."
    private var requests = [VNRequest]()
    let player = AVPlayer()
    private var videoOutput: AVPlayerItemVideoOutput?

    func setupVision() {
        guard let model = try? VNCoreMLModel(for: ASLClassifier().model) else {  
            fatalError("Unable to load model")
        }
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            self?.processClassifications(for: request, error: error)
        }
        self.requests = [request]
    }

    func processVideo() {
        guard let videoURL = Bundle.main.url(forResource: "sign_language_video", withExtension: "mp4") else {
            print("Video file not found")
            return
        }

        let playerItem = AVPlayerItem(url: videoURL)
        player.replaceCurrentItem(with: playerItem)

        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
        playerItem.add(videoOutput!)

        player.play()

        // Periodically check the video output for new frames to process
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] timer in
            self?.processFrame()
        }
    }

    private func processFrame() {
        guard let videoOutput = videoOutput else { return }

        let currentTime = player.currentTime()
        guard let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform(self.requests)
        } catch {
            print("Failed to perform classification.\n\(error.localizedDescription)")
        }
    }

    private func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results else {
            DispatchQueue.main.async {
                self.result = "Unable to classify"
            }
            return
        }

        if let recognizedObjects = results as? [VNRecognizedObjectObservation] {
            if recognizedObjects.isEmpty {
                DispatchQueue.main.async {
//                    self.result = "No classification"
                }
            } else {
                let topLabelObservation = recognizedObjects.first?.labels.first
                DispatchQueue.main.async {
                    self.result = topLabelObservation?.identifier ?? "Unknown"
                }
            }
            return
        }

        if let classifications = results as? [VNClassificationObservation] {
            if classifications.isEmpty {
                DispatchQueue.main.async {
//                    self.result = "No classification"
                }
            } else {
                DispatchQueue.main.async {
                    self.result = classifications.first?.identifier ?? "Unknown"
                }
            }
            return
        }

        DispatchQueue.main.async {
            self.result = "Unexpected result type"
        }
    }
}
