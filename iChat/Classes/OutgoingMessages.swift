//
//  OutgoingMessages.swift
//  iChat
//
//  Created by Sarvad shetty on 12/23/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import Foundation

class OutgoingMessages {
    
    //MARK: - Variables
    let messageDictionary:NSMutableDictionary
    
    //MARK: - Initializers
    //for text message
    init(message:String,senderID:String,senderName:String,date:Date,status:String,type:String) {
        //date can only be saved in string format
        messageDictionary = NSMutableDictionary(objects: [message,senderID,senderName,dateFormatter().string(from: date),status,type], forKeys: [kMESSAGE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }
    
    //MARK: - Send function to save in Firestore
    func SendMessage(chatRoomId:String,messageDict:NSMutableDictionary,memberids:[String],membersToPush:[String]){
        let messageID = UUID().uuidString
        messageDict[kMESSAGEID] = messageID
        
        //need to save the message in all the member ids present in the chatroom
        for member in memberids{
            reference(.Message).document(member).collection(chatRoomId).document(messageID).setData(messageDict as! [String:Any])
        }
        
        //recent chat needs to be updated
        
        //send push notification
    }
    
}
