//
//  IceServers.swift
//  Voice Chat App
//
//  Created by Hell Rocky on 8/19/18.
//  Copyright © 2018 Hell Rocky. All rights reserved.
//

import Foundation
import WebRTC

class IceServers{
    static var iceServers=[
//                           RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
                           RTCIceServer(urlStrings: ["turn:lqnhut1995@ec2-18-223-76-123.us-east-2.compute.amazonaws.com:80"], username: "lqnhut1995", credential: "lamquangnhut")]
}
