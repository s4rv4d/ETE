//
//  Encryptor.swift
//  iChat
//
//  Created by Sarvad shetty on 1/1/19.
//  Copyright © 2019 Sarvad shetty. All rights reserved.
//

import Foundation
import RNCryptor

class Encryotion{
    
    //MARK: - Functions
    class func EncryptText(chatroomID:String,message:String) -> String{
        let data = message.data(using: String.Encoding.utf8)
        let encryptedData = RNCryptor.encrypt(data: data!, withPassword: chatroomID)
        return encryptedData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }
    
    class func DecryptText(chatroomID:String,messageEncrypted:String) -> String{
        let decryptor = RNCryptor.Decryptor(password: chatroomID)
        //created data from encrypted string
        let encryptedData = NSData(base64Encoded: messageEncrypted, options: NSData.Base64DecodingOptions(rawValue: 0))
        var message:NSString = ""
        if encryptedData != nil{
            do{
                let decryptedData = try decryptor.decrypt(data: encryptedData! as Data)
                message = NSString(data: decryptedData, encoding: String.Encoding.utf8.rawValue)!
            }catch{
                print("error decrypting text \(error.localizedDescription)")
            }
        }
        
        return message as String
    }
}
