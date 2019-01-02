//
//  PastCallsTableViewCell.swift
//  iChat
//
//  Created by Sarvad shetty on 1/2/19.
//  Copyright © 2019 Sarvad shetty. All rights reserved.
//

import UIKit

class PastCallsTableViewCell: UITableViewCell {
    
    //MARK: - IBOutlets
    @IBOutlet weak var avatarImagview: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    //MARK: - Functions
    func CellGenerate(call:Call){
//        dateLabel.text
    }
    
}
