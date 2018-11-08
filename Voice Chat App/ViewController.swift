//
//  ViewController.swift
//  Voice Chat App
//
//  Created by Hell Rocky on 8/14/18.
//  Copyright © 2018 Hell Rocky. All rights reserved.
//

import UIKit
import Alamofire
import WebRTC
import SocketIO

class ViewController: UIViewController,UITextFieldDelegate{
    
    @IBOutlet var user: UITextField!
    @IBOutlet var button: UIButton!
    @IBOutlet var profilepicture: UIImageView!
    var iceServers:[RTCIceServer]=IceServers.iceServers
    var videoClient:RTCClient?
    var captureController:RTCCapturer!
    var localCaptureView:RTCEAGLVideoView!
    var remoteCaptureView:RTCEAGLVideoView!
    let socket=SocketManager(socketURL: URL(string: "https://fast-springs-99163.herokuapp.com/")!)
    var connectionState=true
    var localvideoTrack:RTCVideoTrack!
    var remotevideoTrack:RTCVideoTrack!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        user.delegate=self
        profilepicture.layer.cornerRadius = profilepicture.frame.height/2
        
        remoteCaptureView=RTCEAGLVideoView(frame: CGRect(x: 0, y: 50, width: 100, height: 100))
        remoteCaptureView.contentMode = .scaleAspectFit
        localCaptureView=RTCEAGLVideoView(frame: CGRect(x: self.view.frame.width-100, y: self.view.frame.height/2, width: 100, height: 100))
        localCaptureView.contentMode = .scaleAspectFit
        self.view.addSubview(localCaptureView)
        self.view.addSubview(remoteCaptureView)
        videoClient=RTCClient(iceServers: iceServers, videoCall: true)
        videoClient?.delegate=self
        
        socket.defaultSocket.connect()
        socket.defaultSocket.on("sendfromserver6") { (data, ack) in
            if let otheruser=data[0] as? String,otheruser != self.user.text!{
                self.videoClient?.disconnect()
                self.button.setImage(UIImage(named: "call-btn-1"), for: .normal)
            }
        }
        socket.defaultSocket.on("sendfromserver5") { (data, ack) in
            if let otheruser=data[0] as? String,otheruser != self.user.text!{
                self.button.setImage(UIImage(named: "call-btn"), for: .normal)
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        establish()
        if user.text! == "b"{
//            self.videoClient?.startConnection()
            socket.defaultSocket.on("sendfromserver1") { (data, ack) in
                print(data.count)
                let decoding=JSONDecoder()
                let description=try? decoding.decode(Description.self, from: data[0] as! Data)
                self.videoClient?.createAnswerForOfferReceived(withRemoteSDP: description!.sdp!)
                print("sendfromserver1 received")
            }
            socket.defaultSocket.on("sendfromserver3") { (data, ack) in
                let decoding=JSONDecoder()
                let iceCandidate=try? decoding.decode(IceCandidate.self, from: data[0] as! Data)
                self.videoClient?.addIceCandidate(iceCandidate: RTCIceCandidate(sdp: iceCandidate!.sdp!, sdpMLineIndex: iceCandidate!.sdpMLineIndex!, sdpMid: iceCandidate!.sdpMid!))
                print(iceCandidate!.sdp!)
                print("sendfromserver3 received")
            }
            print("user b established")
        }
        textField.resignFirstResponder()
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func calling(_ sender: Any) {
        switch connectionState {
        case false:
            videoClient?.disconnect()
            connectionState=true
            button.setImage(UIImage(named: "call-btn-1"), for: .normal)
        default:
            videoClient?.makeOffer()
            connectionState=false
            button.imageView?.image = UIImage(named: "call-btn")
            button.setImage(UIImage(named: "call-btn"), for: .normal)
        }
        
    }

    @IBAction func switchcamera(_ sender: Any) {
        self.captureController.switchCamera()
    }
}

extension ViewController:RTCClientDelegate{
    
    func rtcClient(client: RTCClient, didCreateLocalCapturer capturer: RTCCameraVideoCapturer) {
        let settingsModel=RTCCapturerSettingsModel()
//        let _=settingsModel.storeVideoResolutionSetting(resolution: RTCCapturerSettingsModel.SettingsConstants.videoResolutionsStaticValues[2])
//        let _=settingsModel.storeVideoCodecSetting(videoCodec: RTCCapturerSettingsModel.SettingsConstants.videoCodecsStaticValues[2])
        self.captureController=RTCCapturer(withCapturer: capturer, settingsModel: settingsModel)
        self.captureController.startCapture()
    }
    
    func rtcClient(client: RTCClient, didGenerateIceCandidate iceCandidate: RTCIceCandidate) {
//        if iceCandidate.sdp.range(of: "relay") == nil{
//            return
//        }
        let iceuser=IceCandidate(sdp: iceCandidate.sdp, sdpMLineIndex: iceCandidate.sdpMLineIndex, sdpMid: iceCandidate.sdpMid!)
        let encoding=JSONEncoder()
        let data=try? encoding.encode(iceuser)
        if(user.text! == "a"){
            self.socket.defaultSocket.emit("msgtoclient3", data!);
        }else{
            print("count")
            self.socket.defaultSocket.emit("msgtoclient4", data!);
        }
        print("\(iceCandidate.sdpMid!)\n\(iceCandidate.sdpMLineIndex)\n\(iceCandidate.sdp)\n\(iceCandidate.serverUrl!)\n\n")
    }
    
    func rtcClient(client: RTCClient, didReceiveLocalVideoTrack localVideoTrack: RTCVideoTrack) {
        localVideoTrack.add(self.localCaptureView)
        self.localvideoTrack=localVideoTrack
    }
    
    func rtcClient(client: RTCClient, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack) {
        remoteVideoTrack.add(self.remoteCaptureView)
        self.remotevideoTrack=remoteVideoTrack
        print("remote stream received")
    }
    
    func rtcClient(client: RTCClient, startCallWithSdp sdp: String) {
        if user.text! == "a"{
            let userinfo=Description(fromuser: user.text!, touser: "b", sdp: sdp)
            let encoding=JSONEncoder()
            let data=try? encoding.encode(userinfo)
            self.socket.defaultSocket.emit("msgtoclient1", data!);
            print("msgtoclient1 sended")
        }else{
            let userinfo=Description(fromuser: user.text!, touser: "a", sdp: sdp)
            let encoding=JSONEncoder()
            let data=try? encoding.encode(userinfo)
            self.socket.defaultSocket.emit("msgtoclient2", data!);
            print("msgtoclient2 sended")
        }
        
    }
    
    func rtcClient(client: RTCClient, didReceiveError error: Error) {
        print("geterror")
    }
    
    func establish(){
        if(user.text! == "a"){
            videoClient?.startConnection()
            socket.defaultSocket.on("sendfromserver2") { (data, ack) in
                let decoding=JSONDecoder()
                let description=try? decoding.decode(Description.self, from: data[0] as! Data)
                self.videoClient?.handleAnswerReceived(withRemoteSDP: description!.sdp!)
                print("sendfromserver2 received")
            }
            socket.defaultSocket.on("sendfromserver4") { (data, ack) in
                let decoding=JSONDecoder()
                let iceCandidate=try? decoding.decode(IceCandidate.self, from: data[0] as! Data)
                self.videoClient?.addIceCandidate(iceCandidate: RTCIceCandidate(sdp: iceCandidate!.sdp!, sdpMLineIndex: iceCandidate!.sdpMLineIndex!, sdpMid: iceCandidate!.sdpMid!))
//                print("\(iceCandidate!.sdpMid!)\n\(iceCandidate!.sdpMLineIndex!)\n\(iceCandidate!.sdp!)\n\n")
                print("sendfromserver4 received")
            }
            print("user a established")
        }
    }
    
    func rtcClient(client: RTCClient, didChangeState state: RTCClientState) {
        if state == RTCClientState.disconnected{
            self.socket.defaultSocket.emit("disconnectstate", user.text!)
        }
        if state == RTCClientState.connected{
            self.socket.defaultSocket.emit("connectstate", user.text!)
        }
    }
    
    func rtcClient(client: RTCClient, didIceGatheringState state: RTCIceGatheringState) {
        
    }
}

