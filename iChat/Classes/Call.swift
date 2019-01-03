//
//  Call.swift
//  iChat
//
//  Created by Sarvad shetty on 1/2/19.
//  Copyright © 2019 Sarvad shetty. All rights reserved.
//

import Foundation

class Call{
    
    //MARK: - Variables
    var objectID:String
    var callerID:String
    var callerFullName:String
    var withUserFullName:String
    var withUserId:String
    var status:String
    var isIncoming:Bool
    var callDate:Date
    
    //MARK: - Initializers
    init(_callerID:String, _withUserId:String, _callerFullName:String, _withUserFullName:String) {
         objectID = UUID().uuidString
         callerID = _callerID
         callerFullName = _callerFullName
         withUserFullName = _withUserFullName
         withUserId = _withUserId
         status = ""
         isIncoming = false
         callDate = Date()
        
    }
    
    init(_dictionary:NSDictionary) {
        objectID = _dictionary[kOBJECTID] as! String
        
        if let callerId = _dictionary[kCALLERID]{
            callerID = callerId as! String
        }else{
            callerID = ""
        }
        
        if let withid = _dictionary[kWITHUSERUSERID]{
            withUserId = withid as! String
        }else{
            withUserId = ""
        }
        
        if let callFName = _dictionary[kCALLERFULLNAME]{
            callerFullName = callFName as! String
        }else{
            callerFullName = "Unknown"
        }
        
        if let withIUserFName = _dictionary[kWITHUSERFULLNAME]{
            withUserFullName = withIUserFName as! String
        }else{
            withUserFullName = "Unknown"
        }
        
        if let callStatus = _dictionary[kCALLSTATUS]{
            status = callStatus as! String
        }else{
            status = ""
        }
        
        if let INC = _dictionary[kISINCOMING]{
            isIncoming = INC as! Bool
        }else{
            isIncoming = false
        }
        
        if let date = _dictionary[kDATE]{
            if (date as! String).count != 14{
                callDate = Date()
            }else{
                callDate = dateFormatter().date(from: date as! String)!
            }
        }else{
            callDate = Date()
        }
    }
    
    //MARK: - Functions
    func DictionaryFromCall() -> NSDictionary{
        let dateString = dateFormatter().string(from: callDate)
        return NSDictionary(objects: [objectID,callerID,callerFullName,withUserId,withUserFullName,status,isIncoming,dateString], forKeys: [kOBJECTID as NSCopying,kCALLERID as NSCopying,kCALLERFULLNAME as NSCopying,kWITHUSERUSERID as NSCopying,kWITHUSERFULLNAME as NSCopying,kSTATUS as NSCopying,kISINCOMING as NSCopying,kDATE as NSCopying
            ])
    }
    
    //doc -> collection -> doc -> .....
    
    //MARK: - Save
    func SaveCallInBackground(){
        //for caller
        reference(.Call).document(callerID).collection(callerID).document(objectID).setData(DictionaryFromCall() as! [String:Any])
        //for with user (reciever)
        reference(.Call).document(withUserId).collection(withUserId).document(objectID).setData(DictionaryFromCall() as! [String:Any])
    }
    
    //MARK: - Delete
    func DeleteCall(){
        reference(.Call).document(FUser.currentId()).collection(FUser.currentId()).document(objectID).delete()
    }
    
}
