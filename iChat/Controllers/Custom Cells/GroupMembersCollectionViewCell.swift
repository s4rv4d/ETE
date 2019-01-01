//
//  GroupMembersCollectionViewCell.swift
//  iChat
//
//  Created by Sarvad shetty on 12/31/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit

//MARK: - Protocols
protocol GroupMembersCollectionViewCellDelegate {
    func DidTapDeleteButton(indexPath:IndexPath)
}

class GroupMembersCollectionViewCell: UICollectionViewCell {
    
    //MARK: - Variables
    var index:IndexPath!
    var delegate:GroupMembersCollectionViewCellDelegate?
    
    //MARK: - IBOutlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var memberAvatar: UIImageView!
    
    //MARK: - Functions
    func GenerateCell(user:FUser,index:IndexPath){
        self.index = index
        self.nameLabel.text = user.firstname
        
        if user.avatar != ""{
            imageFromData(pictureData: user.avatar) { (image) in
                if image != nil{
                    self.memberAvatar.image = image!.circleMasked
                }
            }
        }
    }
    
    //MARK: - IBActions
    @IBAction func DeleteButtonPressed(_ sender: UIButton) {
        delegate!.DidTapDeleteButton(indexPath: index)
    }
}
