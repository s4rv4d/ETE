//
//  MessageViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 12/22/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ProgressHUD
import IQAudioRecorderController
import IDMPhotoBrowser
import AVFoundation
import AVKit
import FirebaseFirestore


//////////IMPORTANT////////////
//SEARCH FOR toggleSendButtonEnabled
//AND MADE CHANGES SET CONTENT TEXT TO TRUE TO ALWAYS ENBLE THE SEND BUTTON
///////////////////////////////

class MessageViewController:  JSQMessagesViewController{
    
    //MARK: - Variables
    
    //JSQ stuff
    var outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    var incomingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    
    //chat room stuff
    var chatRoomId:String!
    var memberids:[String]!
    var memberToPush:[String]!
    
    //nav var stuff
    var titleName:String!
    
    //proper messages types
    let properMessageTypes = [kAUDIO,kVIDEO,kTEXT,kLOCATION,kPICTURE]
    
    //message constraints
    var maxMessageNumber = 0
    var minMessageNumber = 0
    var loadOld = false
    var loadedMessagesCount = 0
    
    //to hold message
    var messages:[JSQMessage] = []
    var objectMessage:[NSDictionary] = []
    var loadedMessages:[NSDictionary] = []
    var allPictureMessages:[String] = []
    var initialLoadComplete = false
    
    
    //fix iPhoneX UI
    override func viewDidLayoutSubviews() {
        //to fix the bottom,calling the fixing method
        perform(Selector(("jsq_updateCollectionViewInsets")))
    }
     //finishing UI
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //senderid and sender display name comes from jsq pod
        self.senderId = FUser.currentId()
        self.senderDisplayName = FUser.currentUser()!.firstname
        
        //nav fixes
        navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.BackAction))]
        title = titleName
        
        //default avatar size next to message bubble
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        LoadMessages()
        //fix iPhoneX UI
        let constraint = perform(Selector(("toolbarBottomLayoutGuide")))?.takeUnretainedValue() as! NSLayoutConstraint
        constraint.priority = UILayoutPriority(rawValue: 1000)
        self.inputToolbar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        //finishing UI
        
        //custom send button
        self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        self.inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
    }
    
    //MARK: - Functions
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let data = messages[indexPath.row]
        if data.senderId == FUser.currentId(){
            cell.textView.textColor = .white
        }else{
            cell.textView.textColor = .black
        }
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        if data.senderId == FUser.currentId(){
            return outgoingBubble
        }else{
            return incomingBubble
        }
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        print("accessory button pressed")
        //show option menu
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            print("camera")
        }
        let showPhotoLibrary = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            print("photo library")
        }
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { (action) in
            print("Video library")
        }
        let shareLocation = UIAlertAction(title: "Share Location", style: .default) { (action) in
            print("Share location")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("cancel")
        }
        //images for accessory
        takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
        showPhotoLibrary.setValue(UIImage(named: "picture"), forKey: "image")
        shareVideo.setValue(UIImage(named: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")
        
        optionMenu.addAction(takePhotoOrVideo)
        optionMenu.addAction(showPhotoLibrary)
        optionMenu.addAction(shareVideo)
        optionMenu.addAction(shareLocation)
        optionMenu.addAction(cancelAction)
        
        //to check for iPads
        if (UI_USER_INTERFACE_IDIOM() == .pad){
            if let currentPopoverPresebtationController = optionMenu.popoverPresentationController{
                currentPopoverPresebtationController.sourceView = self.inputToolbar.contentView.leftBarButtonItem
                currentPopoverPresebtationController.sourceRect = self.inputToolbar.contentView.leftBarButtonItem.bounds
                
                currentPopoverPresebtationController.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }else{
                self.present(optionMenu, animated: true, completion: nil)
            }
        }
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        print("send button pressed")
        
        //to check for text
        if text != ""{
            //for text message to be sent nothing else
            self.SendMessage(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
            //after send button is pressed
            UpdateSendButton(isSend: false)
        }else{
            print("audio message")
        }
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        if textView.text != ""{
            UpdateSendButton(isSend: true)
        }else{
            UpdateSendButton(isSend: false)
        }
    }
    
    @objc func BackAction(){
        self.navigationController?.popViewController(animated: true)
    }
    
    //Custom send button
    func UpdateSendButton(isSend:Bool){
        if isSend{
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
        }else{
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        }
    }
    
    //send messages
    func SendMessage(text:String?, date:Date, picture: UIImage?, location:String?, video:NSURL?, audio:String?){
        //create an instance of outgoing message
        var outgoingMessage:OutgoingMessages?
        let currentUser = FUser.currentUser()!
        
        //text message
        if let text = text{
            outgoingMessage = OutgoingMessages(message: text, senderID: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kTEXT)
        }
        //sending message sound
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
        outgoingMessage!.SendMessage(chatRoomId: chatRoomId, messageDict: outgoingMessage!.messageDictionary, memberids: memberids, membersToPush: memberToPush)
    }
    
    //loading messages
    func LoadMessages(){
        
        //get last 11 messages
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshot, error) in
            //get 11 messages
            guard let snapshot = snapshot else{
                //initial loading is done
                self.initialLoadComplete = true
                //listening for new chat
                return
            }
            //sorting messages
            let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
            //to remove corrupted messages
            self.loadedMessages = self.RemoveCorruptMessages(allMessages: sorted)
            //insert after converting to JSQMessages
            self.InsertMessages()
            self.finishReceivingMessage(animated: true)
            self.initialLoadComplete = true
            
            print("we have \(self.messages.count) loaded")
            //get picture messages
            //get old messages in background
            //start listening for new chats
            
        }
    }
    
    func RemoveCorruptMessages(allMessages:[NSDictionary]) -> [NSDictionary]{
        //to make it mutable transfer to temp variables
        var tempMessages = allMessages
        for message in tempMessages{
            if message[kTYPE] != nil{
                if !self.properMessageTypes.contains(message[kTYPE] as! String){
                    //remove the message from temp dict
                    tempMessages.remove(at: tempMessages.index(of:message)!)
                }
            }else{
                tempMessages.remove(at: tempMessages.index(of:message)!)
            }
        }
        return tempMessages
    }
    
    //MARK: - Insert Messages
    func InsertMessages(){
        maxMessageNumber = loadedMessages.count - loadedMessagesCount
        minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        
        if minMessageNumber < 0{
            minMessageNumber = 0
        }
        
        //for debugging
        print("max: \(maxMessageNumber)")
        print("min: \(minMessageNumber)")
        
        for i in minMessageNumber ..< maxMessageNumber{
           let messageDictionary = loadedMessages[i]
            
            //insert message
            InsertInitialLoadedMessages(md: messageDictionary)
            loadedMessagesCount += 1
        }
        
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    //to load messages
    func InsertInitialLoadedMessages(md:NSDictionary) -> Bool{
        
        let incomingMsg = IncomingMessage(collectionView_: self.collectionView!)
        
        //check if incoming
        if(md[kSENDERID] as! String) != FUser.currentId(){
            //update message status
        }
        
        let message = incomingMsg.CreateMessage(messageDict: md, chatroomId: chatRoomId)
        
        if message != nil{
            objectMessage.append(md)
            messages.append(message!)
        }
        
        print("messages array \(messages)")
        return IsIncoming(messD:md)
    }
    
    //to check if its an incoming or outgoing message
    func IsIncoming(messD:NSDictionary) -> Bool{
        if FUser.currentId() == messD[kSENDERID] as! String{
            return false
        }else{
            return true
        }
    }
}

extension JSQMessagesInputToolbar {
    //to fix ui on iPhone X
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = window else { return }
        if #available(iOS 11.0, *) {
            let anchor = window.safeAreaLayoutGuide.bottomAnchor
            bottomAnchor.constraintLessThanOrEqualToSystemSpacingBelow(anchor, multiplier: 1.0).isActive = true
        }
    }
}
