//
//  PicturesCollectionViewCell.swift
//  iChat
//
//  Created by Sarvad shetty on 12/27/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit

class PicturesCollectionViewCell: UICollectionViewCell {
    
    //MARK: - IBOutlets
    @IBOutlet weak var collecImageView: UIImageView!
    
    
    //MARK: - Functions
    func GenerateCell(image:UIImage){
        self.collecImageView.image = image
    }
}
