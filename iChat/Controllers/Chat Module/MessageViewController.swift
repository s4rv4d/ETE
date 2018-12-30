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
    //app delegate
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //JSQ stuff
    var outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    var incomingBubble = JSQMessagesBubbleImageFactory()?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    
    //typing
    var typingCounter = 0
    
    //custom header
    let leftBarButton:UIView = {
       let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        return view
    }()
    let avatarButton:UIButton = {
       let button = UIButton(frame: CGRect(x: 0, y: 10, width: 25, height: 25))
        return button
    }()
    let titleLabel:UILabel = {
       let title = UILabel(frame: CGRect(x: 30, y: 10, width: 140, height: 15))
        title.textAlignment = .left
        title.font = UIFont(name: title.font.fontName, size: 14)
        return title
    }()
    let subTitleLabel:UILabel = {
       let subTitleLabel = UILabel(frame: CGRect(x: 30, y: 25, width: 140, height: 15))
        subTitleLabel.textAlignment = .left
        subTitleLabel.font = UIFont(name: subTitleLabel.font.fontName, size: 14)
        return subTitleLabel
    }()
    
    //chat room stuff
    var chatRoomId:String!
    var memberids:[String]!
    var memberToPush:[String]!
    var isGroup:Bool?
    var group:NSDictionary?
    var withUser:[FUser] = []
    
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
    
    //avatar
    var jsqAvaterDictionary:NSMutableDictionary?
    var avatarImageDictionary:NSMutableDictionary?
    var showAvatars = true
    var firstLoad:Bool?
    
    //listeners
    var newChatListener:ListenerRegistration?
    var typingListener:ListenerRegistration?
    var updateListener:ListenerRegistration?
    
    
    //fix iPhoneX UI
    override func viewDidLayoutSubviews() {
        //to fix the bottom,calling the fixing method
        perform(Selector(("jsq_updateCollectionViewInsets")))
    }
     //finishing UI
    
    override func viewWillAppear(_ animated: Bool) {
        ClearRecentCounter(chatRoomId: chatRoomId)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ClearRecentCounter(chatRoomId: chatRoomId)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //create typing observer
        CreateTypingObserver()
        
        //delete option
        JSQMessagesCollectionViewCell.registerMenuAction(#selector(delete))
        
        //senderid and sender display name comes from jsq pod
        self.senderId = FUser.currentId()
        self.senderDisplayName = FUser.currentUser()!.firstname
        
        //nav fixes
        navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.BackAction))]
        
        //default avatar size next to message bubble
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        //avatar stuff
        jsqAvaterDictionary = [:]
        
        //custom header
        SetCustomTitle()
        
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
    
    //MARK: - JSQ Datasource functions
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        //time stamp after every three messages
        if indexPath.item % 3 == 0{
            let message = messages[indexPath.row]
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for:message.date)
        }
            return nil
    }
    
   override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if indexPath.item % 3 == 0{
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        //last message read status
        let message = objectMessage[indexPath.row]
        let status:NSAttributedString!
        let attrFormatColor = [NSAttributedString.Key.foregroundColor:UIColor.darkGray]
        
        switch message[kSTATUS] as! String {
        case kDELIVERED:
            status = NSAttributedString(string: kDELIVERED)
        case kREAD:
            let statusText = "Read \(ReadTimeFormat(date: message[kREADDATE] as! String))"
            status = NSAttributedString(string: statusText, attributes: attrFormatColor)
        default:
            status = NSAttributedString(string: "✔️")
        }
        
        if indexPath.row == messages.count - 1{
            return status
        }else{
            return NSAttributedString(string:"")
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        let data = messages[indexPath.row]
        if data.senderId == FUser.currentId(){
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }else{
            return 0
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.row]
        var avatar:JSQMessageAvatarImageDataSource
        
        if let testAvatar = jsqAvaterDictionary!.object(forKey: message.senderId){
            avatar = testAvatar as! JSQMessageAvatarImageDataSource
        }else{
            avatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        }
        return avatar
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
//        profileViewOfUser
        let sender = messages[indexPath.row].senderId
        var selectedUser:FUser?
        
        if sender == FUser.currentId(){
            selectedUser = FUser.currentUser()
        }else{
            for user in withUser{
                if user.objectId == sender{
                    selectedUser = user
                }
            }
        }
        
        //show user profile
        PresentUserProfile(forUser: selectedUser!)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let data = messages[indexPath.row]
        
        //textviews need to be optional because text view are required only for text messages
        
        if data.senderId == FUser.currentId(){
            cell.textView?.textColor = .white
        }else{
            cell.textView?.textColor = .black
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
    
    //for multi media messages
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        super.collectionView(collectionView, shouldShowMenuForItemAt: indexPath)
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if messages[indexPath.row].isMediaMessage{
            if action.description == "delete:"{
                return true
            }else{
                return false
            }
        }else{
            if action.description == "delete:" || action.description == "copy:"{
                return true
            }else{
                return false
            }
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didDeleteMessageAt indexPath: IndexPath!) {
        let messageID = objectMessage[indexPath.row][kMESSAGEID] as! String
        objectMessage.remove(at: indexPath.row)
        messages.remove(at: indexPath.row)
        //delete from firebase
        OutgoingMessages.DeleteMessage(withId: messageID, chatroomId: chatRoomId)
    }
    
    //MARK: - JSQ Delegate functions
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        print("accessory button pressed")
        
        //camera class instance
        let camera = Camera(delegate_: self)
        
        //show option menu
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            print("camera")
            camera.PresentMultiCamera(target: self, canEdit: false)
        }
        let showPhotoLibrary = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            print("photo library")
            camera.PresentPhotoLibrary(target: self, canEdit: false)
        }
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { (action) in
            print("Video library")
            camera.PresentVideoLibrary(target: self, canEdit: false)
        }
        let shareLocation = UIAlertAction(title: "Share Location", style: .default) { (action) in
            print("Share location")
            if self.HaveAccessToUserLocation(){
                self.SendMessage(text: nil, date: Date(), picture: nil, location: kLOCATION, video: nil, audio: nil)
            }
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
            }
        }else{
            self.present(optionMenu, animated: true, completion: nil)
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
            //audio part
            print("audio message")
            
            let audioVC = AudioViewController(delegate_: self)
            audioVC.PresentAudioRecorder(target:self)
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        print("load more")
        //load morew messages
        LoadMoreMessages(max: maxMessageNumber, min: minMessageNumber)
        self.collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        print("cell tapped at \(indexPath)")
        
        let messageDictionary = objectMessage[indexPath.row]
        let messageType = messageDictionary[kTYPE] as! String
        
        //for different types
        switch messageType {
        case kPICTURE:
            print("picture tapped")
            let message = messages[indexPath.row]
            let mediaItem = message.media as! JSQPhotoMediaItem
            //using idm to handle image,and loads it with media item, it has his inbuiltbrowser for zooming in the image, or for sharing
            let photo = IDMPhoto.photos(withImages: [mediaItem.image])
            //initialize the browser
            let browser = IDMPhotoBrowser(photos: photo)
            self.present(browser!, animated: true, completion: nil)
        case kLOCATION:
            print("location message tapped")
            let message = messages[indexPath.row]
            let mediaItem = message.media as! JSQLocationMediaItem
            //instantiate map view controller
            let mapView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mapVC") as! MapViewController
            mapView.location = mediaItem.location
            self.navigationController?.pushViewController(mapView, animated: true)
        case kVIDEO:
            print("video message tapped")
            //get video url from message
            let message = messages[indexPath.row]
            let mediaItem = message.media as! VideoMessage
            //give the player the video url for it to play
            let player = AVPlayer(url: mediaItem.fileURL! as URL)
            //instantiate a movie viewcontroller to play the video
            let movieViewController = AVPlayerViewController()
            let session = AVAudioSession.sharedInstance()
            
            //for DEV INFO: there was a bug where i couldnt set setCategory function properly
            try! session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            //set the player to movie viewcontroller
            movieViewController.player = player
            
            self.present(movieViewController,animated:true){
                movieViewController.player!.play()
            }
        default:
            print("unknown messaged tapped")
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
        ClearRecentCounter(chatRoomId: chatRoomId)
        RemoveListeners()
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - UIImagePickerController functions
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
//        let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
//        let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
//
//        SendMessage(text: nil, date: Date(), picture: picture, location: nil, video: video, audio: nil)
//
//        picker.dismiss(animated: true, completion: nil)
//    }
    //for swift 4.2
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
        let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        SendMessage(text: nil, date: Date(), picture: picture, location: nil, video: video, audio: nil)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Functions
    
    //location access
    func HaveAccessToUserLocation() -> Bool{
        if appDelegate.locationManager != nil{
            return true
        }else{
            ProgressHUD.showError("Please give access to location in settings.")
            return false
        }
    }
    
    //update messages
    func UpdateMessage(msd:NSDictionary){
        for index in 0 ..< objectMessage.count{
            let temp = objectMessage[index]
            //to check if message is uploaded
            if msd[kMESSAGEID] as! String == temp[kMESSAGEID] as! String{
                objectMessage[index] = msd
                self.collectionView!.reloadData()
            }
        }
    }
    
    //load more messages
    func LoadMoreMessages(max:Int,min:Int){
        //to update max and min
        if loadOld{
            maxMessageNumber = min - 1
            minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        }
        
        if minMessageNumber < 0 {
           minMessageNumber = 0
        }
        
        for i in (minMessageNumber ... maxMessageNumber).reversed(){
            let msgDict = loadedMessages[i]
            //insert new message
            InsertNewMessage(msgD: msgDict)
            loadedMessagesCount += 1
        }
        
        loadOld = true
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    func InsertNewMessage(msgD:NSDictionary){
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView)
        let message = incomingMessage.CreateMessage(messageDict: msgD, chatroomId: chatRoomId)
        objectMessage.insert(msgD, at: 0)
        messages.insert(message!, at: 0)
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
        //picture message
        if let picture = picture{
            //upload image
            UploadImage(image: picture, chatRoomId: chatRoomId, view: self.navigationController!.view) { (imageLink) in
                if imageLink != nil{
                    let text = "[\(kPICTURE)]"
                    outgoingMessage = OutgoingMessages(message: text, pictureLink: imageLink!, senderID: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kPICTURE)
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    outgoingMessage?.SendMessage(chatRoomId: self.chatRoomId, messageDict: outgoingMessage!.messageDictionary, memberids: self.memberids, membersToPush: self.memberToPush)
                }
            }
            return
        }
        //video message
        if let video = video{
            //get video
            let videoData = NSData(contentsOfFile: video.path!)
            //getting thumbnail from video
            let thmbnail = VideoThumbnail(video: video)
            //for uploading to firebase
//            let dataThumbNail = UIImageJPEGRepresentation(thmbnail, 0.3)
            let dataThumbNail = thmbnail.jpegData(compressionQuality: 0.3)
            
            UploadVideo(video: videoData!, chatroomID: chatRoomId, view: (self.navigationController?.view)!) { (videoLnk) in
                if videoLnk != nil{
                    let text = "[\(kVIDEO)]"
                    outgoingMessage = OutgoingMessages(message: text, videoLink: videoLnk!, thumbNail: dataThumbNail! as NSData, senderID: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kVIDEO)
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    outgoingMessage?.SendMessage(chatRoomId: self.chatRoomId, messageDict: (outgoingMessage?.messageDictionary)!, memberids: self.memberids, membersToPush: self.memberToPush)
                }
            }
            return
        }
        //audio message
        if let audioPath = audio{
            UploadAudioMessage(audioPath: audioPath, chatroomID: chatRoomId, view: (self.navigationController?.view)!) { (audioLink) in
                if audioLink != nil{
                    let text = "[\(kAUDIO)]"
                    outgoingMessage = OutgoingMessages(message: text, audio: audioLink!, senderID: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kAUDIO)
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    outgoingMessage?.SendMessage(chatRoomId: self.chatRoomId, messageDict: outgoingMessage!.messageDictionary, memberids: self.memberids, membersToPush: self.memberToPush)
                }
            }
            return
        }
        //location message
        if let location = location{
            print("send location")
            let lat:NSNumber = NSNumber(value: appDelegate.coordinates!.latitude)
            let long:NSNumber = NSNumber(value: appDelegate.coordinates!.longitude)
            
            let text = "[\(kLOCATION)]"
            
            outgoingMessage = OutgoingMessages(message: text, latitude: lat, longitude: long, senderID: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kLOCATION)
            
        }
        
        //sending message sound
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
        outgoingMessage!.SendMessage(chatRoomId: chatRoomId, messageDict: outgoingMessage!.messageDictionary, memberids: memberids, membersToPush: memberToPush)
    }
    
    //loading messages
    func LoadMessages(){
        
        //to update status
        updateListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else{return}
            //is empty or not
            if !snapshot.isEmpty{
                //for loop for document changes
                snapshot.documentChanges.forEach({ (difference) in
                    if difference.type == .modified{
                        //updated local message
                        self.UpdateMessage(msd: difference.document.data() as NSDictionary)
                    }
                })
            }
        })
        
        //get last 11 messages
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshot, error) in
            //get 11 messages
            guard let snapshot = snapshot else{
                //initial loading is done
                self.initialLoadComplete = true
                //listening for new chat
                self.ListenForNewChat()
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
            self.GetPictureMessages()
            //get old messages in background
            self.GetOldMessagesInBackground()
            //start listening for new chats
            self.ListenForNewChat()
            
        }
    }
    
    func ListenForNewChat(){
        var lastMessageDate = "0"
        
        if loadedMessages.count > 0{
            lastMessageDate = loadedMessages.last![kDATE] as! String
        }
        
        newChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else{return}
            
            if !snapshot.isEmpty{
                for diff in snapshot.documentChanges{
                    if diff.type == .added{
                        let item = diff.document.data() as NSDictionary
                        if let type = item[kTYPE]{
                            if self.properMessageTypes.contains(type as! String){
                                if type as! String == kPICTURE{
                                    //for pictures
                                    //add to pictures
                                    self.AddNewPictureMessageLink(link: item[kPICTURE] as! String)
                                }
                                
                                if self.InsertInitialLoadedMessages(md: item){
                                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                }
                                
                                self.finishReceivingMessage()
                            }
                        }
                    }
                }
            }
        })
        
    }
    
    //Typing indicator
    func CreateTypingObserver(){
        typingListener = reference(.Typing).document(chatRoomId).addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else {return}
            
            if snapshot.exists{
                for data in snapshot.data()!{
                    //we dont want to know if we are typing
                    if data.key != FUser.currentId(){
                        let typing = data.value as! Bool
                        self.showTypingIndicator = typing
                        
                        if typing{
                            self.scrollToBottom(animated: true)
                        }
                    }
                }
            }else{
                reference(.Typing).document(self.chatRoomId).setData([FUser.currentId():false])
            }
        })
    }
    
    func TypingCounterStart(){
        typingCounter += 1
        TypingCounterSave(typing: true)
        self.perform(#selector(self.TypingCounterStop), with: nil, afterDelay: 2.0)
    }
    
    @objc func TypingCounterStop(){
        typingCounter -= 1
        if typingCounter == 0{
            TypingCounterSave(typing: false)
        }
    }
    
    func TypingCounterSave(typing:Bool){
        reference(.Typing).document(chatRoomId).updateData([FUser.currentId():typing])
    }
    
    func AddNewPictureMessageLink(link:String){
        allPictureMessages.append(link)
    }
    
    func GetPictureMessages(){
        allPictureMessages = []
        for message in  loadedMessages{
            if message[kTYPE] as! String == kPICTURE{
                allPictureMessages.append(message[kPICTURE] as! String)
            }
        }
    }
    
    //MARK: - UITextView delegate
    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        TypingCounterStart()
        
        return true
    }
    
    func GetOldMessagesInBackground(){
        //getting messages in background
        if loadedMessages.count > 10{
            let firstMessageDate = loadedMessages.first![kDATE] as! String
            //to get older messages
            reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isLessThan: firstMessageDate).getDocuments { (snapshot, error) in
                guard let snapshot = snapshot else{return}
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
                //to bring old messages before the current messages
                self.loadedMessages = self.RemoveCorruptMessages(allMessages: sorted) + self.loadedMessages
                
                //get messages
                self.GetPictureMessages()
                //to update max and min after getting old messages
                self.maxMessageNumber = self.loadedMessages.count - self.loadedMessagesCount - 1
                self.minMessageNumber = self.maxMessageNumber - kNUMBEROFMESSAGES
            }
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
    
    //MARK: - Update UI
    func SetCustomTitle(){
        leftBarButton.addSubview(avatarButton)
        leftBarButton.addSubview(titleLabel)
        leftBarButton.addSubview(subTitleLabel)
        
        let infoButton = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.InfoButtonPressed))
        self.navigationItem.rightBarButtonItem = infoButton
        
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButton)
        self.navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        
        if isGroup!{
            avatarButton.addTarget(self, action: #selector(self.ShowGroup), for: .touchUpInside)
        }else{
            avatarButton.addTarget(self, action: #selector(self.ShowUserProfile), for: .touchUpInside)
        }
        
        getUsersFromFirestore(withIds: memberids) { (withUsers) in
            self.withUser = withUsers
            //get avatars
            self.GetAvatarImages()
            
            if !self.isGroup!{
                //update user info
                self.SetupUIForSingleChat()
            }
        }
    }
    
    func SetupUIForSingleChat(){
        let withUsr = withUser.first!
        imageFromData(pictureData: withUsr.avatar) { (img) in
            if img != nil{
                avatarButton.setImage(img!.circleMasked, for: .normal)
            }
        }
        titleLabel.text = withUsr.fullname
        if withUsr.isOnline{
            subTitleLabel.text = "Online"
        }else{
            subTitleLabel.text = "Offline"
        }
        
        avatarButton.addTarget(self, action: #selector(self.ShowUserProfile), for: .touchUpInside)
    }
    
    @objc func InfoButtonPressed(){
        print("info button tapped to show info")
        let mediaVc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mediaView") as! PicturesCollectionViewController
        mediaVc.allImageLinks = allPictureMessages
        self.navigationController?.pushViewController(mediaVc, animated: true)
    }
    
    @objc func ShowGroup(){
        print("show group info")
    }
    
    @objc func ShowUserProfile(){
        print("show user profile info")
        let profileView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileViewOfUser") as! ProfilePageTableViewController
        profileView.user = withUser.first!
        self.navigationController?.pushViewController(profileView, animated: true)
    }
    
    func PresentUserProfile(forUser:FUser){
        print("present user profile info")
        let profileView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileViewOfUser") as! ProfilePageTableViewController
        profileView.user = forUser
        self.navigationController?.pushViewController(profileView, animated: true)
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
            OutgoingMessages.UpdateMessage(withid: md[kMESSAGEID] as! String, chatroom: chatRoomId, memberIds: memberids)
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
    
    //for time of READ message
    func ReadTimeFormat(date:String) -> String{
        let date = dateFormatter().date(from: date)
        let currentDateformat = dateFormatter()
        currentDateformat.dateFormat = "HH:mm"
        return currentDateformat.string(from: date!)
    }
    
    //remove listeners
    func RemoveListeners(){
        if typingListener != nil{
            typingListener!.remove()
        }
        
        if newChatListener != nil{
            newChatListener!.remove()
        }
        
        if updateListener != nil{
            updateListener!.remove()
        }
    }
    
    //Get avatars
    func GetAvatarImages(){
        if showAvatars{
            collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 30, height: 30)
            collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 30, height: 30)
            
            //for current user
            AvatarImageFrom(user: FUser.currentUser()!)
            
            for user in withUser{
                AvatarImageFrom(user: user)
            }
        }
    }
    
    func AvatarImageFrom(user:FUser){
        if user.avatar != ""{
            dataImageFromString(pictureString: user.avatar) { (imageData) in
                if imageData == nil{
                    return
                }
                
                if self.avatarImageDictionary != nil{
                    //update avatar if we have any
                    self.avatarImageDictionary!.removeObject(forKey: user.objectId)
                    self.avatarImageDictionary!.setObject(imageData, forKey: user.objectId as NSCopying)
                }else{
                    self.avatarImageDictionary = [user.objectId:imageData!]
                }
                //create jsq avatars
                self.CreateJSQAvatas(dict: self.avatarImageDictionary)
            }
        }
    }
    
    func CreateJSQAvatas(dict:NSMutableDictionary?){
        let defaultAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        if dict != nil{
            for userId in memberids{
                if let avatarImageDATA = dict![userId]{
                    let jsqAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: avatarImageDATA as! Data), diameter: 70)
                    self.jsqAvaterDictionary!.setValue(jsqAvatar, forKey: userId)
                }else{
                    self.jsqAvaterDictionary!.setValue(defaultAvatar, forKey: userId)
                }
            }
        }
        self.collectionView.reloadData()
    }
}

extension JSQMessagesInputToolbar {
    //to fix ui on iPhone X
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = window else { return }
        if #available(iOS 11.0, *) {
            let anchor = window.safeAreaLayoutGuide.bottomAnchor
            bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: anchor, multiplier: 1.0).isActive = true
        }
    }
}


extension MessageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    //just conforming nothing else, to use functions in Camera class
}

//conform to IQAUDIORECORDER VC DELEGATE

extension MessageViewController:IQAudioRecorderViewControllerDelegate{
    
    //MARK: - AUdio delegate functions
    func audioRecorderController(_ controller: IQAudioRecorderViewController, didFinishWithAudioAtPath filePath: String) {
        controller.dismiss(animated: true, completion: nil)
        self.SendMessage(text: nil, date: Date(), picture: nil, location: nil, video: nil, audio: filePath)
    }
    
    func audioRecorderControllerDidCancel(_ controller: IQAudioRecorderViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
