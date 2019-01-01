//
//  Group.swift
//  iChat
//
//  Created by Sarvad shetty on 12/31/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import Foundation
import FirebaseFirestore

class Group{
    
    //MARK: - Variables
    let groupDictionary:NSMutableDictionary
    
    //MARK: - Initializers
    init(groupID:String, subject:String, owner:String, members:[String], avatar:String) {
        groupDictionary = NSMutableDictionary(objects: [groupID,subject,owner,members,members,avatar], forKeys: [kGROUPID as NSCopying,kNAME as NSCopying,kOWNERID as NSCopying,kMEMBERS as NSCopying,kMEMBERSTOPUSH as NSCopying,kAVATAR as NSCopying])
    }
    
    //MARK: - Functions
    func SaveGroup(){
        let date = dateFormatter().string(from: Date())
        groupDictionary[kDATE] = date
        
        //accessing firestore
        reference(.Group).document(groupDictionary[kGROUPID] as! String).setData(groupDictionary as! [String:Any])
    }
    
    class func UpdateGroup(groupID:String,withValues:[String:Any]){
        reference(.Group).document(groupID).updateData(withValues)
    }
}
