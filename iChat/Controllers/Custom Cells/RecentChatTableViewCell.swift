//
//  RecentChatTableViewCell.swift
//  iChat
//
//  Created by Sarvad shetty on 12/17/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit

//MARK:Protocol
protocol RecentChatTableViewCellDelegate {
    func ProfilePicTapped(index:IndexPath)
}

class RecentChatTableViewCell: UITableViewCell {
    
    //MARK:Variables
    var indexPath:IndexPath!
    let tapGestureRecog = UITapGestureRecognizer()
    var delegate:RecentChatTableViewCellDelegate?
    
    //MARK:IBOutlets
    @IBOutlet weak var profilePicImageview: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var messageCounterLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageCounterView: UIView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        messageCounterView.layer.cornerRadius = messageCounterView.frame.width/2
        tapGestureRecog.addTarget(self, action: #selector(self.PicTap))
        profilePicImageview.isUserInteractionEnabled = true
        profilePicImageview.addGestureRecognizer(tapGestureRecog)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //MARK:Cell Functions
    func CellGenerate(recentChat:NSDictionary,index:IndexPath){
        self.indexPath = index
        //assigning values
        self.fullNameLabel.text = recentChat[kWITHUSERFULLNAME] as? String
        
        //decrypting
        let decryptedText = Encryotion.DecryptText(chatroomID: recentChat[kCHATROOMID] as! String, messageEncrypted: recentChat[kLASTMESSAGE] as! String)
        
        self.lastMessageLabel.text = decryptedText
        self.messageCounterLabel.text = recentChat[kCOUNTER] as? String
        
        //for date
        var date:Date!
        if let created = recentChat[kDATE]{
            if (created as! String).count != 14{
                date = Date()
            }else{
                date = dateFormatter().date(from: created as! String)
            }
        }else{
            date = Date()
        }
        self.dateLabel.text = timeElapsed(date: date)
        //for avatar
        if let avatarString = recentChat[kAVATAR]{
            imageFromData(pictureData: avatarString as! String) { (image) in
                if image != nil{
                    self.profilePicImageview.image = image!.circleMasked
                }
            }
        }
        //for counter
        if recentChat[kCOUNTER] as! Int != 0{
            self.messageCounterLabel.text = "\(recentChat[kCOUNTER] as! Int)"
            self.messageCounterLabel.isHidden = false
            self.messageCounterView.isHidden = false
        }else{
            self.messageCounterLabel.isHidden = true
            self.messageCounterView.isHidden = true
        }
    }
    
    @objc func PicTap(){
     print("profile picture tapped at \(indexPath)")
        delegate?.ProfilePicTapped(index: indexPath)
    }

}
