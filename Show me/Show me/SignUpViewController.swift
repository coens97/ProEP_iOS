//
//  SignUpViewController.swift
//  Show me
//
//  Created by Miyako on 2018/1/3.
//  Copyright © 2018年 Ninja coders. All rights reserved.
//

import UIKit
import SocketIO

class SignUpViewController: UIViewController {
    @IBOutlet weak var Login: UIButton!
    

        // Do any additional setup after loading the view.
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var errorTest: UILabel!
    var socketClient:SocketIOClient?
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
   
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signup(_ sender: Any) {
        self.view.endEditing(true)
        let name = username.text
        let mail = email.text
        let pass = password.text
        
        self.errorTest!.text = ""
        
        let json =  ["name": name,"email":mail, "pass": pass] // { name: 'asana', pass: 'ding ding ding' }
        print(json)
        socketClient!.emit("register", json)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
         runSocket()
    }
    
    func runSocket() {
        
        self.socketClient = Singleton.instance.manager.defaultSocket
        
        if (self.socketClient!.status == .connected) {
            self.statusLabel!.text = "💯"
        }
        
//        self.socketClient!.on(clientEvent: .connect) {data, ack in
//            print("socket connected")
//            self.statusLabel!.text = "✅"
//        }
//
//        self.socketClient!.on(clientEvent: .disconnect) {data, ack in
//            print("socket disconnected")
//            self.statusLabel!.text = "🚫"
//        }
//        self.socketClient!.on(clientEvent: .error) {data, ack in
//            print("socket error")
//            print(data)
//            self.statusLabel!.text = "😦"
//        }
        
self.socketClient!.on("register") {data, ack in
            print("register")
           let o = data[0] as! [String: Any]
            if let succeed = o["succeed"] as! Bool? {
               if succeed {
                  // self.performSegue(withIdentifier: "ShowStream", sender: nil)
                print(data)
                self.errorTest!.text = "Register Succeed!"
               }
               else {
                   print(data)
                   if let message = o["message"] as! String? {
                        self.errorTest!.text = message
                   }
               }
            }
           else {
                self.errorTest!.text = "Received unexpected message"
            }
        }
       // self.socketClient!.connect()
        
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
