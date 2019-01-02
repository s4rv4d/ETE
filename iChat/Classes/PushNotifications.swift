//
//  PushNotifications.swift
//  iChat
//
//  Created by Sarvad shetty on 1/2/19.
//  Copyright © 2019 Sarvad shetty. All rights reserved.
//

import Foundation
import OneSignal

func SendPushNotification(membersToPush:[String],message:String){
    let updatedMembers = RemoveCurrentUserFromMembersArray(members: membersToPush)
    GetMembersToPush(members: updatedMembers) { (userPushIds) in
        let currentUser = FUser.currentUser()!
        OneSignal.postNotification(["contents":["en":"\(currentUser.firstname) \n \(message)"],"ios_badgeType":"Increase","ios_badgeCount":"1","include_player_ids":userPushIds])
    }
}

func RemoveCurrentUserFromMembersArray(members:[String]) -> [String]{
    var updatedMembers:[String] = []
    for memberID in members{
        if memberID != FUser.currentId(){
            updatedMembers.append(memberID)
        }
    }
    return updatedMembers
}

func GetMembersToPush(members:[String], completion:@escaping(_ usersArray:[String]) -> Void){
    var pushIDS:[String] = []
    var count = 0
    
    for memberID in members{
        reference(.User).document(memberID).getDocument { (snapshot, error) in
            guard let snapshot = snapshot else {
                completion(pushIDS)
                return
            }
            
            if snapshot.exists{
                let userDictionary = snapshot.data() as! NSDictionary
                let fuser = FUser(_dictionary: userDictionary)
                pushIDS.append(fuser.pushId!)
                count += 1
                
                if members.count == count{
                    completion(pushIDS)
                }
            }else{
                completion(pushIDS)
            }
        }
    }
}
