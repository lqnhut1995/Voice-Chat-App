//
//  File.swift
//  Voice Chat App
//
//  Created by Hell Rocky on 8/18/18.
//  Copyright © 2018 Hell Rocky. All rights reserved.
//

import Foundation

class Description: Codable{
    var fromuser:String?
    var touser:String?
    var sdp:String?

    init(fromuser: String, touser: String, sdp: String){
        self.fromuser=fromuser
        self.touser=touser
        self.sdp=sdp
    }
    private enum CodingKeys: String, CodingKey{
        case fromuser
        case touser
        case sdp
    }
}

class IceCandidate: Codable{
    var sdp:String?
    var sdpMLineIndex:Int32?
    var sdpMid:String?
    
    init(sdp:String,sdpMLineIndex:Int32,sdpMid:String){
        self.sdp=sdp
        self.sdpMLineIndex=sdpMLineIndex
        self.sdpMid=sdpMid
    }
    private enum CodingKeys: String, CodingKey{
        case sdp
        case sdpMLineIndex
        case sdpMid
    }
    
    
}
