//
//  VideoMessage.swift
//  iChat
//
//  Created by Sarvad shetty on 12/26/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class VideoMessage:JSQMediaItem{
    
    //MARK: - Variables
    var image:UIImage?
    var videoImageView:UIImageView?
    var status:Int?
    var fileURL:NSURL?
    
    //MARK: - Initializers
     init(withFileURL: NSURL, maskOutgoing: Bool) {
        super.init(maskAsOutgoing:maskOutgoing)
        
        fileURL = withFileURL
        videoImageView = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Functions
    override func mediaView() -> UIView! {
        if let status = status{
            if status == 1{
                return  nil
            }
            if status == 2 && self.videoImageView == nil{
                let size = self.mediaViewDisplaySize()
                //to check if message is outgoing
                let outgoing = self.appliesMediaViewMaskAsOutgoing
                //play button icon
                let icon = UIImage.jsq_defaultPlay()?.jsq_imageMasked(with: .white)
                let iconView = UIImageView(image: icon)
                
                iconView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                //to center out the icon
                iconView.contentMode = .center
                
                //imageview for the thumbnail
                let imageView = UIImageView(image: self.image!)
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.addSubview(iconView)
                
                JSQMessagesMediaViewBubbleImageMasker.applyBubbleImageMask(toMediaView: imageView, isOutgoing: outgoing)
                self.videoImageView = imageView
            }
        }
        
        return self.videoImageView
    }
}
