//
//  IncomingMessages.swift
//  iChat
//
//  Created by Sarvad shetty on 12/23/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class IncomingMessage {
    //MARK: - Varibles
    var collectionView:JSQMessagesCollectionView
    
    //mark: - Initializers
    init(collectionView_:JSQMessagesCollectionView) {
        collectionView = collectionView_
    }
    
    
    //MARK: - Functions
    func CreateMessage(messageDict:NSDictionary,chatroomId:String) -> JSQMessage?{
        //message
        var message:JSQMessage?
        let type = messageDict[kTYPE] as! String
        
        switch type {
        case kTEXT:
            //create text message
            print("text")
            message = CreateTextMessage(messDict: messageDict, chatRoomId: chatroomId)
        case kPICTURE:
            //create picture message
            print("picture")
            message = CreatePictureMessage(messDict: messageDict)
        case kVIDEO:
            //create video message
            print("video")
            message = CreateVideoMessage(messDict: messageDict)
        case kAUDIO:
            //create audio message
            print("audio")
        case kLOCATION:
            //create location message
            print("location")
        default:
            print("Unknown message type")
        }
        
        if message != nil{
            return message
        }else{
            return nil
        }
    }
    
    //MARK: - Create message types
    func CreateTextMessage(messDict:NSDictionary, chatRoomId:String) -> JSQMessage{
        let name = messDict[kSENDERNAME] as! String
        let userId = messDict[kSENDERID] as! String
        
        //handling date part to check if date is present in messages from chatroom id
        var date:Date!
        if let created = messDict[kDATE]{
            if (created as! String).count != 14{
                date = Date()
            }else{
                date = dateFormatter().date(from: created as! String)
            }
        }else{
            date = Date()
        }
        
        let text = messDict[kMESSAGE] as! String
        
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, text: text)
    }
    
    //picture message
    func CreatePictureMessage(messDict:NSDictionary) -> JSQMessage{
        let name = messDict[kSENDERNAME] as? String
        let userId = messDict[kSENDERID] as? String
        
        //handling date part to check if date is present in messages from chatroom id
        var date:Date!
        if let created = messDict[kDATE]{
            if (created as! String).count != 14{
                date = Date()
            }else{
                date = dateFormatter().date(from: created as! String)
            }
        }else{
            date = Date()
        }
        
        let mediaItem = PhotoMediaItem(image:nil)
        mediaItem?.appliesMediaViewMaskAsOutgoing = ReturnOutgoingStatusForUser(senderID: userId!)
        
        //download image
        DownloadImage(imageURL: messDict[kPICTURE] as! String) { (image) in
            if image != nil{
                mediaItem?.image = image!
                //to load image
                self.collectionView.reloadData()
            }
        }
            return JSQMessage(senderId: userId!, senderDisplayName: name!, date: date, media: mediaItem)
    }
    
    func ReturnOutgoingStatusForUser(senderID:String) -> Bool{
        return senderID == FUser.currentId()
    }
    
    //video message
    func CreateVideoMessage(messDict:NSDictionary) -> JSQMessage{
        let name = messDict[kSENDERNAME] as? String
        let userId = messDict[kSENDERID] as? String
        
        //handling date part to check if date is present in messages from chatroom id
        var date:Date!
        if let created = messDict[kDATE]{
            if (created as! String).count != 14{
                date = Date()
            }else{
                date = dateFormatter().date(from: created as! String)
            }
        }else{
            date = Date()
        }
        
        //video url
        let videoURL = NSURL(fileURLWithPath: messDict[kVIDEO] as! String)
        
        let mediaItem = VideoMessage(withFileURL: videoURL, maskOutgoing: ReturnOutgoingStatusForUser(senderID: userId!))
        
        //download video
        DownloadVideo(videoURL: messDict[kVIDEO] as! String) { (ready, fileName) in
            let url = NSURL(fileURLWithPath: FileInDocumentsDirectory(filename: fileName))
            mediaItem.status = kSUCCESS
            mediaItem.fileURL = url
            imageFromData(pictureData: messDict[kPICTURE] as! String, withBlock: { (image) in
                if image != nil{
                mediaItem.image = image!
                    self.collectionView.reloadData()
                }
            })
            //after thumbnail is et and collection view is refreshed ,the collection view is supposed to be refreshed after the video is loaded
            self.collectionView.reloadData()
        }
        return JSQMessage(senderId: userId!, senderDisplayName: name!, date: date, media: mediaItem)
    }
    
}
