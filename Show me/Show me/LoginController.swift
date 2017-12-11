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
        self.socketClient!.connect()
        
    }
    
    @IBAction func loginClicked(_ sender: Any) {
        // get the text of the username and the password
        // send login over socket
        //socket manger: let manager = SocketManager(socketURL: URL(string: Preference.defaultInstance.socketUri!)!, config: [.log(true), .compress])
        // make singleton in new file
        
    }
    
    
    
    
}
