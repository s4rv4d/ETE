//
//  BackgroundCollectionViewCell.swift
//  iChat
//
//  Created by Sarvad shetty on 12/30/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit

class BackgroundCollectionViewCell: UICollectionViewCell {
    
    //MARK: - IBOutlets
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    
    //MARK: - Functions
    func GenerateCell(image:UIImage){
        self.backgroundImageView.image = image
    }
}
