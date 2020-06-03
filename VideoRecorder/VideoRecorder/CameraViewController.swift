//
//  CameraViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {

    lazy private var captureSession = AVCaptureSession()
    lazy private var fileOutput = AVCaptureMovieFileOutput()
    
    private var player: AVPlayer?
    private var playerView: VideoPlayerView!
    
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!

	override func viewDidLoad() {
		super.viewDidLoad()

		// Resize camera preview to fill the entire screen
		cameraView.videoPlayerView.videoGravity = .resizeAspectFill
        
        setUpCaptureSession()
	}
    
    // startRunning?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSession.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
    }

    private func setUpCaptureSession() {
        
        captureSession.beginConfiguration()
        // Inputs
        
        // Camera
        let camera = bestCamera()
        
        guard let cameraInput = try? AVCaptureDeviceInput(device: camera),
            captureSession.canAddInput(cameraInput) else {
                // FUTURE: Display the error so you understand why it failed
                fatalError("Cannot create camera input, do something better than crashing?")
        }
        captureSession.addInput(cameraInput)
        
        // Microphone
        
        // Quality level
        
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        }
        
        // Outputs
        guard captureSession.canAddOutput(fileOutput) else {
            fatalError("Cannot add movie recording")
        }
        captureSession.addOutput(fileOutput)
        
        // Set the captureSession into our CameraPreviewView
        captureSession.commitConfiguration()
        cameraView.session = captureSession
    }
    
    private func bestCamera() -> AVCaptureDevice {
        // ideal camera, fallback camera, FUTURE: we add a button to choose front/back
        if let ultraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            return ultraWideCamera
        }
        
        if let wideAngleCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) { // try .front
            return wideAngleCamera
        }
        
        // Simulator or the requested hardware cameras doesn't work!
        fatalError("No camera available, are you on a simulator?") // TODO: show UI instead of a fatal error
    }
    
    private func updateViews() {
        recordButton.isSelected = fileOutput.isRecording
    }

    @IBAction func recordButtonPressed(_ sender: Any) {
        toggleRecording()
    }
    
    private func toggleRecording() {
        if fileOutput.isRecording {
            fileOutput.stopRecording()
            updateViews()
        } else {
            fileOutput.startRecording(to: newRecordingURL(), recordingDelegate: self)
            updateViews()
        }
    }
	
	/// Creates a new file URL in the documents directory
	private func newRecordingURL() -> URL {
		let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime]

		let name = formatter.string(from: Date())
		let fileURL = documentsDirectory.appendingPathComponent(name).appendingPathExtension("mov")
		return fileURL
	}
    
    private func playMovie(url: URL) {
        let player = AVPlayer(url: url)
        
        if playerView == nil {
            // setup view
            let playerView = VideoPlayerView()
            playerView.player = player
            
            // customize the frame
            var frame = view.bounds
            frame.size.height = frame.size.height / 4
            frame.size.width = frame.size.width / 4
            frame.origin.y = view.layoutMargins.top
            
            playerView.frame = frame
            
            view.addSubview(playerView)
            self.playerView = playerView
        }
        player.play()
        self.player = player
    }
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("didStartRecording: \(fileURL)")
        
        updateViews()
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error saving movie: \(error)")
            return
        }
        print("Play movie!")
        
        DispatchQueue.main.async {
            self.playMovie(url: outputFileURL)
        }
        
        updateViews()
    }
}
