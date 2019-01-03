//
//  CallViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 1/3/19.
//  Copyright © 2019 Sarvad shetty. All rights reserved.
//

import UIKit

class CallViewController: UIViewController {
    
    //MARK: - Variables
    var speaker = false
    var mute = false
    var durationTimer:Timer! = nil
    var _call:SINCall!
    var callAnswered = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //MARK: - IBOutlets
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var muteButtonOutlet: UIButton!
    @IBOutlet weak var speskerButtonOutlet: UIButton!
    @IBOutlet weak var anwserCallOutlet: UIButton!
    @IBOutlet weak var endCallButtonOutlet: UIButton!
    @IBOutlet weak var declineCallIutlet: UIButton!
    
    //MARK: - Main
    override func viewWillAppear(_ animated: Bool) {
        fullNameLabel.text = "Unknown"
        let id = _call.remoteUserId
        
        getUsersFromFirestore(withIds: [id!]) { (user) in
            if user.count > 0{
                let userF = user.first!
                self.fullNameLabel.text = userF.fullname
                imageFromData(pictureData: userF.avatar, withBlock: { (image) in
                    if image != nil{
                        self.avatarImageView.image = image!.circleMasked
                    }
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        _call.delegate = self
        
        if _call.direction == SINCallDirection.incoming{
            //show buttons
            ShowButtons()
        }else{
            callAnswered = true
            //show buttons
            ShowButtons()
            SetCallStatusText(text: "Calling...")
        }
    }
    
    //MARK: - IBActions
    @IBAction func MuteTapped(_ sender: UIButton) {
        if mute{
            mute = false
            AudioController().unmute()
            muteButtonOutlet.setImage(UIImage(named: "mute"), for: .normal)
        }else{
            mute = true
            AudioController().mute()
            muteButtonOutlet.setImage(UIImage(named: "muteSelected"), for: .normal)
        }
    }
    
    @IBAction func SpeakerTapped(_ sender: UIButton) {
        if !speaker{
            speaker = true
            AudioController().enableSpeaker()
            speskerButtonOutlet.setImage(UIImage(named: "speakerSelected"), for: .normal)
        }else{
            speaker = false
            AudioController().disableSpeaker()
            speskerButtonOutlet.setImage(UIImage(named: "speaker"), for: .normal)
        }
    }
    
    @IBAction func AnswerTapped(_ sender: UIButton) {
        callAnswered = true
        ShowButtons()
        AudioController().stopPlayingSoundFile()
        _call.answer()
    }
    
    @IBAction func HangUpTapped(_ sender: UIButton) {
        _call.hangup()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func DeclineTapped(_ sender: UIButton) {
        _call.hangup()
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Functions
    func SetCallStatusText(text:String){
        statusLabel.text = text
    }
    
    func ShowButtons(){
        if callAnswered {
            declineCallIutlet.isHidden = true
            endCallButtonOutlet.isHidden = false
            anwserCallOutlet.isHidden = true
            muteButtonOutlet.isHidden = false
            speskerButtonOutlet.isHidden = false
            AudioController().startPlayingSoundFile(PathForSound(soundName: "incoming"), loop: true)
        }else{
            declineCallIutlet.isHidden = false
            endCallButtonOutlet.isHidden = true
            anwserCallOutlet.isHidden = false
            muteButtonOutlet.isHidden = true
            speskerButtonOutlet.isHidden = true
        }
    }
    
    func AudioController() -> SINAudioController{
        return appDelegate._client.audioController()
    }
    
    func SetCall(call:SINCall){
        _call = call
        _call.delegate = self
    }
    
    //MARK: - Helper Functions
    func PathForSound(soundName:String) -> String{
        return Bundle.main.path(forResource: soundName, ofType: "wav")!
    }
}

//MARK: - Extensions
extension CallViewController: SINCallDelegate{

    func callDidProgress(_ call: SINCall!) {
        SetCallStatusText(text: "Ringing...")
        AudioController().startPlayingSoundFile(PathForSound(soundName: "ringback"), loop: true)
    }
    
    func callDidEstablish(_ call: SINCall!) {
        //start timer
        StartCallDurationTimer()
        ShowButtons()
        AudioController().stopPlayingSoundFile()
    }
    
    func callDidEnd(_ call: SINCall!) {
        print("call ended")
        AudioController().stopPlayingSoundFile()
        //stop timer
        StopCallDurationTimer()
        self.dismiss(animated: true, completion: nil)
    }
    
    //Timer functions
    @objc func Onduration(){
        let duration = Date().timeIntervalSince(_call.details.establishedTime)
        //update time timer label
        UpdateTimerLabel(sec: Int(duration))
    }
    
    func UpdateTimerLabel(sec:Int){
        let min  = String(format: "%02d", (sec/60))
        let secs = String(format: "%02d", (sec % 60))
        SetCallStatusText(text: "\(min) : \(secs)")
    }
    
    func StartCallDurationTimer(){
        self.durationTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.Onduration), userInfo: nil, repeats: true)
    }
    
    func StopCallDurationTimer(){
        if durationTimer != nil{
            durationTimer.invalidate()
            durationTimer = nil
        }
    }
}
