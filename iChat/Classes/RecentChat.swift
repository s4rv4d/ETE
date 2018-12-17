//
//  RecentChat.swift
//  iChat
//
//  Created by Sarvad shetty on 12/1/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import Foundation

//MARK:Chat functions
func StartPrivateChat(user1:FUser,user2:FUser) -> String{
    
    //object ids for room id
    let user1ID = user1.objectId
    let user2ID = user2.objectId
    
    //room id
    var chatRoomID = ""
    
    //generating a chat roomid
    let value = user1ID.compare(user2ID).rawValue
    
    if value < 0{
        chatRoomID = user1ID + user2ID
    }else{
        chatRoomID = user2ID + user1ID
    }
    
    //chat room members
    let members = [user1ID,user2ID]
    
    //create chatroom
    CreateChat(members: members, chatroomID: chatRoomID, withUserUsername: "", type: kPRIVATE, users: [user1,user2], avatarOfGroup: nil)
    
    return chatRoomID
    
}

func CreateChat(members:[String],chatroomID:String,withUserUsername:String,type:String,users:[FUser]?,avatarOfGroup:String?){
    
    var tempMembers = members
    
    //to check if chat started before in firestore using chat room id
    reference(.Recent).whereField(kRECENTID, isEqualTo: chatroomID).getDocuments { (snapshots, error) in
        guard let snapshot = snapshots else {return}
        
        //to check if snapshot isnt empty i.e., if chat already started before
        if !snapshot.isEmpty{
            //to check for the recent texts
            for recent in snapshot.documents{
                let currentRecent = recent.data() as NSDictionary
                print("current recent: \(currentRecent)")
                if let currentUserId = currentRecent[kUSERID]{
                    //to check if reccent chat object already created between users
                    if tempMembers.contains(currentUserId as! String){
                        tempMembers.remove(at: tempMembers.index(of:currentUserId as! String)!)
                    }
                }
            }
        }
        
        //if recent chat no created between the members in tempMembers
        for userID in tempMembers{
            //create recent items
                CreateRecentItems(userID: userID, chatRoomID: chatroomID, members: members, withUserUsername: withUserUsername, type: type, users: users, avatarOfGroup: avatarOfGroup)
        }
    }
}

func CreateRecentItems(userID:String,chatRoomID:String,members:[String],withUserUsername:String,type:String,users:[FUser]?,avatarOfGroup:String?){
 
    //create reference
    let ref = reference(.Recent).document()
    let refID = ref.documentID
    
    //create a date to note the time it was create
    let date = dateFormatter().string(from: Date())
    //create a dictionary
    var recent:[String:Any]!
    
    //to check for type
    if type == kPRIVATE{
        //for private
        var withUser:FUser?
        
        if users != nil && users!.count > 0{
            //for current user
            if userID == FUser.currentId(){
                withUser = users!.last!
            }else{
                //if creating the chat for the second user
                withUser = users!.first!
            }
        }
        
        //init the dict
        recent = [kRECENTID:refID,kUSERID:userID,kCHATROOMID:chatRoomID,kMEMBERS:members,kMEMBERSTOPUSH:members,kWITHUSERFULLNAME:withUser!.fullname,kWITHUSERUSERID:withUser!.objectId,kLASTMESSAGE:"",kCOUNTER:0,kDATE:date,kTYPE:type,kAVATAR:withUser!.avatar] as [String:Any]
    }else{
        //for group
        
        //to check if avatar of group isnt equal to nil
        if avatarOfGroup != nil{
            recent = [kRECENTID:refID,kUSERID:userID,kCHATROOMID:chatRoomID,kMEMBERS:members,kMEMBERSTOPUSH:members,kWITHUSERFULLNAME:withUserUsername,kLASTMESSAGE:"",kCOUNTER:0,kDATE:date,kTYPE:type,kAVATAR:avatarOfGroup!] as [String:Any]
        }
    }
    
    //save to firestore
    ref.setData(recent)
}
