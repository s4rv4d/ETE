//
//  UsersTableViewCell.swift
//  iChat
//
//  Created by Sarvad shetty on 11/21/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit

//creating our own custom delegate for passing data
protocol UsersTableViewCellDelegate {
    func DidTapProfilePic(IndexPath:IndexPath)
}

class UsersTableViewCell: UITableViewCell {
    
    //MARK:IBOutlets
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userName: UILabel!
    
    //MARK:Variables
    var indexPath:IndexPath!
    let tapGestureRecogniser = UITapGestureRecognizer()
    var delegate:UsersTableViewCellDelegate?
    

    override func awakeFromNib() {
        super.awakeFromNib()
        //add gesture recogniser to Self
        tapGestureRecogniser.addTarget(self, action: #selector(self.AvatarTapped))
        userImageView.isUserInteractionEnabled = true
        userImageView.addGestureRecognizer(tapGestureRecogniser)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    //MARK:Functions
    func GenerateCellWith(fuser:FUser,indexPath:IndexPath){
        
        self.indexPath = indexPath
        
        //setting logged in user profile
        self.userName.text = fuser.fullname
        
        if fuser.avatar != ""{
            imageFromData(pictureData: fuser.avatar) { (avatarImage) in
                if avatarImage != nil{
                    self.userImageView.image = avatarImage?.circleMasked
                }
            }
        }
        
    }
    
    @objc func AvatarTapped(){
        print("Avatar Tapped at IndexPath: \(indexPath)")
        
        //first you tap,then delegate get the indexValue and the view controller that has defined this function else where can access the indexpath
        delegate!.DidTapProfilePic(IndexPath: indexPath)
    }
}
