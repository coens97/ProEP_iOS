//
//  LoginController.swift
//  Show me
//
//  Created by Miyako on 2017/12/6.
//  Copyright © 2017年 Ninja coders. All rights reserved.
//

import Foundation
import UIKit
import SocketIO

class LoginController: UIViewController {
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var usernameTxt: UITextField!
    @IBOutlet var passwordTxt: UITextField!
    @IBOutlet var errorTxt: UILabel!
    var socketClient:SocketIOClient?
    
    override func viewWillAppear(_ animated: Bool) {
        runSocket()
    }
    
    func runSocket() {
        self.socketClient = Singleton.instance.manager.defaultSocket
        
        self.socketClient!.on(clientEvent: .connect) {data, ack in
            print("socket connected")
            self.statusLabel!.text = "✅"
        }
        
        self.socketClient!.on(clientEvent: .disconnect) {data, ack in
            print("socket disconnected")
            self.statusLabel!.text = "🚫"
        }
        self.socketClient!.on(clientEvent: .error) {data, ack in
            print("socket error")
            print(data)
            self.statusLabel!.text = "😦"
        }
        
        self.socketClient!.on("login") {data, ack in
            print("login")
            let o = data[0] as! [String: Any]
            if let succeed = o["succeed"] as! Bool? {
                if succeed {
                    self.performSegue(withIdentifier: "ShowStream", sender: nil)
                }
                else {
                    print(data)
                    if let message = o["message"] as! String? {
                        self.errorTxt!.text = message
                    }
                }
            }
            else {
                self.errorTxt!.text = "Received unexpected message"
            }
        }
        self.socketClient!.connect()
        
    }
    
    @IBAction func loginClicked(_ sender: Any) {
        let username = usernameTxt.text
        let password = passwordTxt.text
        self.errorTxt!.text = ""
        
        let json =  ["name": username, "pass": password] // { name: 'asana', pass: 'ding ding ding' }
        print(json)
        socketClient!.emit("login", json)
    }
    
    @IBAction func unwindToViewControllerLogin(segue: UIStoryboardSegue) {
        //nothing goes here
    }
    
}
