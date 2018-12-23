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
        case kVIDEO:
            //create video message
            print("video")
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
}
