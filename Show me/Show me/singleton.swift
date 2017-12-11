//
//  Singleton.swift
//  Show me
//
//  Created by Miyako on 2017/12/11.
//  Copyright © 2017年 Ninja coders. All rights reserved.
//

import SocketIO
final class Singleton  {
    
    private init() { }
    
    // Shared instance
    static let instance = Singleton()
    
    // local variable
    let manager = SocketManager(socketURL: URL(string: "http://40.68.124.79:1903/")!, config: [.log(true), .compress])
}
