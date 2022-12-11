//
//  ViewController.swift
//  Example
//
//  Created by Tomoya Hirano on 2020/04/02.
//  Copyright © 2020 Tomoya Hirano. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, TrackerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var toggleView: UISwitch!
    var previewLayer: AVCaptureVideoPreviewLayer!
    @IBOutlet weak var xyLabel:UILabel!
    @IBOutlet weak var featurePoint: UIView!
    
    static let trackerParams: HolisticTrackerConfig = HolisticTrackerConfig(false, enableRefinedFace: true, maxPersonsToTrack: 0, enableFaceLandmarks: false, enablePoseLandmarks: false, enableLeftHandLandmarks: false, enableRightHandLandmarks: false, enableHolisticLandmarks: true, enablePoseWorldLandmarks: false, enablePixelBufferOutput: true)
    let tracker: HolisticTracker = HolisticTracker(trackerParams)!
    let camera = Camera()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera.setSampleBufferDelegate(self)
        camera.start()
        tracker.startGraph()
        tracker.delegate = self
        
//        previewLayer = AVCaptureVideoPreviewLayer(session: camera.session) as AVCaptureVideoPreviewLayer
//        previewLayer.frame = view.bounds
//        view.layer.addSublayer(previewLayer)
//        view.bringSubviewToFront(xyLabel)
//        view.bringSubviewToFront(featurePoint)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        tracker.processVideoFrame(pixelBuffer)

        DispatchQueue.main.async {
            if !self.toggleView.isOn {
                self.imageView.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer!))
            }
        }
    }
    
    func holisticTracker(_ holisticTracker: HolisticTracker!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {
        // Holistic tracker delegate output function
        DispatchQueue.main.async {
            if self.toggleView.isOn {
                self.imageView.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
            }
        }
    }
    
    func holisticTracker(_ holisticTracker: HolisticTracker!, didOutputLandmarks name: String!, packetData packet: [AnyHashable : Any]!) {
        // Landmarks handling
        name.withCString { nameStr in
            if (0 == memcmp(nameStr, kMultiHolisticStream, strlen(kMultiHolisticStream))) {
                processHolisticLandmarks(packet)
            } else if (0 == memcmp(nameStr, kMultiFaceStream, strlen(kMultiFaceStream)) ||
                       0 == memcmp(nameStr, kMultiPoseStream, strlen(kMultiPoseStream)) ||
                       0 == memcmp(nameStr, kMultiLeftHandStream, strlen(kMultiLeftHandStream)) ||
                       0 == memcmp(nameStr, kMultiRightHandStream, strlen(kMultiRightHandStream)) ||
                       0 == memcmp(nameStr, kMultiPoseWorldStream, strlen(kMultiPoseWorldStream))) {
                processLandmarksByType(packet, landmarkType: name)
            }
        }
    }
    
    func processHolisticLandmarks(_ landmarkData: [AnyHashable : Any]!) {
        // Holistic landmarks, Dict<Dict<Array<Landmark>>>
        NSLog("==== Got new holistic packet ====")
        for (idx, data) in landmarkData {
            let index = idx as! Int
            let holisticDict = data as! [AnyHashable : Any]
            NSLog("Holistic landmark #%d count %d", index, holisticDict.count)
            for (lmKey, lmVal) in holisticDict {
                let landmarkType = lmKey as! Int
                let landmarkList = lmVal as! [Landmark]
                NSLog("#%d landmarks count %d", landmarkType, landmarkList.count)
                for landmark in landmarkList {
                    NSLog("\t\"%d\": %.6f %.6f %.6f", landmarkType, landmark.x, landmark.y, landmark.z)
                }
            }
        }
    }
    
    func processLandmarksByType(_ landmarkData: [AnyHashable : Any]!, landmarkType: String) {
        // Landmarks of a single component, Dict<Array<Landmark>>
        NSLog("==== Got new %s packet ====", landmarkType)
        for (idx, data) in landmarkData {
            let index = idx as! Int
            let landmarkList = data as! [Landmark]
            NSLog("#%d landmarks count %d", index, landmarkList.count)
            for landmark in landmarkList {
                NSLog("\t\"%d\": %.6f %.6f %.6f", index, landmark.x, landmark.y, landmark.z)
            }
        }
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension CGFloat {
    func ceiling(toDecimal decimal: Int) -> CGFloat {
        let numberOfDigits = CGFloat(abs(pow(10.0, Double(decimal))))
        if self.sign == .minus {
            return CGFloat(Int(self * numberOfDigits)) / numberOfDigits
        } else {
            return CGFloat(ceil(self * numberOfDigits)) / numberOfDigits
        }
    }
}

extension Double {
    func ceiling(toDecimal decimal: Int) -> Double {
        let numberOfDigits = abs(pow(10.0, Double(decimal)))
        if self.sign == .minus {
            return Double(Int(self * numberOfDigits)) / numberOfDigits
        } else {
            return Double(ceil(self * numberOfDigits)) / numberOfDigits
        }
    }
}
