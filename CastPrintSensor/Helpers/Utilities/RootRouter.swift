//
//  RootRouter.swift
//  CastPrintSensor
//
//  Copyright © CastPrint. All rights reserved.
//

import UIKit

class RootRouter {

    /** Replaces root view controller. You can specify the replacment animation type.
     If no animation type is specified, there is no animation */
    func setRootViewController(controller: UIViewController, animatedWithOptions: UIView.AnimationOptions?) {
        guard let window = UIApplication.shared.keyWindow else {
            fatalError("No window in app")
        }
        if let animationOptions = animatedWithOptions, window.rootViewController != nil {
            window.rootViewController = controller
            UIView.transition(with: window, duration: 0.33, options: animationOptions, animations: {
            }, completion: nil)
        } else {
            window.rootViewController = controller
        }
    }

    func loadMainAppStructure() {
        // Customize your app structure here

        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)

        if authStatus != .authorized {
            NSLog("Not authorized to use the camera!")
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { _ in
            }
        }
        
        let storyboard = UIStoryboard(name: "Scan", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "ScanController")
        
        setRootViewController(controller: initialViewController, animatedWithOptions: nil)
    }
}
