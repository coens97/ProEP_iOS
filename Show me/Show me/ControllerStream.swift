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
import SocketIO
import CoreLocation

struct Preference {
    static let defaultInstance:Preference = Preference()
    
    var uri:String? = "rtmp://40.68.124.79:1984/show/"
}

class ControllerStream: UIViewController, CLLocationManagerDelegate{
    @IBOutlet var startButton: UIButton!
    @IBOutlet var streamPreview: GPUImageView!
    @IBOutlet var videoLabel: UILabel!
    @IBOutlet var socketLabel: UILabel!
    var streaming = false
    
    var camera:GPUImageVideoCamera?
    var filter:GPUImageFilter?
    var rtmpConnection:RTMPConnection?
    var rtmpStream:RTMPStream?
    var socketClient:SocketIOClient?
    var timer = Timer()
    var locationManager = CLLocationManager()
    var streamName:String = "stream"
//    let manager = SocketManager(socketURL: URL(string: Preference.defaultInstance.socketUri!)!, config: [.log(true), .compress])
    
    var output:GPUImageRawDataOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        camera = GPUImageVideoCamera(sessionPreset: AVCaptureSession.Preset.hd1280x720.rawValue, cameraPosition: .back)
        rtmpConnection = RTMPConnection()
        rtmpStream = RTMPStream(connection: rtmpConnection!)
        filter = GPUImageFilter()
        // ask for permissions for location
        locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
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
        // Start socket
        runSocket()
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
            timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)// run the timer to send metadata
            self.videoLabel!.text = "🔴"
        }
        else {
            startButton.setTitle("Starting...", for:  UIControlState())
            if (streamName == "stream") {
                socketClient!.emit("initStream")
            } else { // reuse old uuid
                startStream()
            }
        }
    }
    
    @IBAction func switchedClicked(_ sender: Any) {
        camera!.rotateCamera()
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
            DispatchQueue.main.async {
                self.videoLabel!.text = "💯"
            }
            rtmpStream!.publish(self.streamName)
            break
        default:
            break
        }
    }
    
    func runSocket() {
        
        self.socketClient = Singleton.instance.manager.defaultSocket
        
        if (self.socketClient!.status == .connected) {
            self.socketLabel!.text = "💯"
        }
        
        self.socketClient!.on(clientEvent: .connect) {data, ack in
            print("socket connected")
            self.socketLabel!.text = "💯"
        }
        
        self.socketClient!.on(clientEvent: .disconnect) {data, ack in
            print("socket disconnected")
            self.socketLabel!.text = "🔴"
        }
        self.socketClient!.on(clientEvent: .error) {data, ack in
            print("socket error")
            print(data)
            self.socketLabel!.text = "😓"
        }
        
        self.socketClient!.on("initStream") {data, ack in
            self.startButton.setTitle("Failed...", for:  UIControlState())
            print(data)
            
            let o = data[0] as! [String: Any]
            if let succeed = o["succeed"] as! Bool? , let uuid = o["data"] as! String?{
                if (succeed) {
                    print(uuid)
                    self.streamName = uuid
                    self.startStream()
                }
            }
        }
        //self.socketClient!.connect()
    }
    
    func startStream() {
        self.startButton.setTitle("Stop", for:  UIControlState())
        self.rtmpConnection?.addEventListener(Event.RTMP_STATUS, selector:#selector(ControllerStream.on(status:)), observer: self)
        self.rtmpConnection?.connect(Preference.defaultInstance.uri!)
        self.timer.invalidate()
        self.streaming = true
    }
    
    @objc func timerAction() {
        // timer that doesn't do anything 👀👀
    }
    
    /*func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!)
    {
        locationManager.stopUpdatingLocation()
        if ((error) != nil)
        {
            print(error)
        }
    }*/
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let locationArray = locations as NSArray
        let locationObj = locationArray.lastObject as! CLLocation
        let coord = locationObj.coordinate
        if streaming {
            let json =  ["location": ["long": coord.longitude.magnitude, "lat": coord.latitude.magnitude]]
            print(json)
            socketClient!.emit("phonemeta", json) // send location
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
