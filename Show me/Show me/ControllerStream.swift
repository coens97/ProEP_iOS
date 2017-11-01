//
//  ControllerStream.swift
//  Show me
//
//  Created by Coen Stange on 01/11/2017.
//  Copyright © 2017 Ninja coders. All rights reserved.
//

import UIKit
import GPUImage
import HaishinKit
import GPUHaishinKit
import AVFoundation

struct Preference {
    static let defaultInstance:Preference = Preference()
    
    var uri:String? = "rtmp://40.68.124.79:1984/show"
    var streamName:String? = "stream"
}

class ControllerStream: UIViewController {
    @IBOutlet var startButton: UIButton!
    @IBOutlet var streamPreview: GPUImageView!
    
    var streaming = false
    
    var camera:GPUImageVideoCamera?
    var filter:GPUImageFilter?
    var rtmpConnection:RTMPConnection?
    var rtmpStream:RTMPStream?
    
    var output:GPUImageRawDataOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        camera = GPUImageVideoCamera(sessionPreset: AVCaptureSession.Preset.hd1280x720.rawValue, cameraPosition: .back)
        rtmpConnection = RTMPConnection()
        rtmpStream = RTMPStream(connection: rtmpConnection!)
        filter = GPUImageFilter()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        do {
            try AVAudioSession.sharedInstance().setPreferredSampleRate(44_100)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setMode(AVAudioSessionModeDefault)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
        }
        
        if let camera = camera {
            rtmpStream?.attachGPUImageVideoCamera(camera)
        }
        rtmpStream?.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio))
        rtmpStream?.videoSettings = [
            "width": 720,
            "height": 1280,
        ]
        camera?.addTarget(filter!)
        filter?.addTarget(streamPreview)
        filter?.addTarget(rtmpStream!.rawDataOutput)
        camera?.outputImageOrientation = .portrait
        camera?.startCapture()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startClicked(_ sender: Any) {
        if streaming {
            streaming = false
            startButton.setTitle("Start", for:  UIControlState())
            rtmpConnection?.close()
            rtmpConnection?.removeEventListener(Event.RTMP_STATUS, selector:#selector(ControllerStream.on(status:)), observer: self)
            
        }
        else {
            streaming = true
            startButton.setTitle("Stop", for:  UIControlState())
            rtmpConnection?.addEventListener(Event.RTMP_STATUS, selector:#selector(ControllerStream.on(status:)), observer: self)
            rtmpConnection?.connect(Preference.defaultInstance.uri!)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        rtmpStream?.close()
        rtmpStream?.dispose()
        camera?.stopCapture()
        super.viewWillDisappear(animated)
    }
    
    @objc func on(status:Notification) {
        print(status)
        let e:Event = Event.from(status)
        guard let data:ASObject = e.data as? ASObject , let code:String = data["code"] as? String else {
            return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            rtmpStream!.publish(Preference.defaultInstance.streamName!)
        default:
            break
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
