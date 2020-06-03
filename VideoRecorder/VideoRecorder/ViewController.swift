//
//  ViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}
	
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        // view must be on screen before we can transition to a new screen
        requestPermissionAndShowCamera()
    }

    private func requestPermissionAndShowCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
            case .authorized:
                // 2nd time user has used app (they've already authorized)
                showCamera()
            case .denied:
                // 2nd time user has used app (they have not given permission)
                // take to the settings app (or show a custom Onboarding screen to explain why need access)
                fatalError("Show user UI to get them to give access")
            case .notDetermined:
                // 1st time user is using app
                requestPermission()
            case .restricted:
                // Parental controls (need to inform user they don't have access, maybe ask parents?)
                fatalError("Show user UI to request permssion from boss/parent/self")
            @unknown default:
                fatalError("Apple added another enum value that we're not handling")
        }
    }

    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
            guard granted else {
                fatalError("Show user UI to get them to give access")
                // return  // TODO show UI for getting privacy permission
            }
            
            DispatchQueue.main.async {
                self.showCamera()
            }
        }
    }
    
	private func showCamera() {
		performSegue(withIdentifier: "ShowCamera", sender: self)
	}
}
