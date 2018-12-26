//
//  PhotoMediaItem.swift
//  iChat
//
//  Created by Sarvad shetty on 12/26/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import Foundation
import JSQMessagesViewController


class PhotoMediaItem: JSQPhotoMediaItem{
    
    override func mediaViewDisplaySize() -> CGSize {
        let defaultSize:CGFloat = 256
        var thumbSize:CGSize = CGSize(width: defaultSize, height: defaultSize)
        
        //self.image is from JSQPhotoMediaItem
        if self.image != nil && self.image.size.height > 0 && self.image.size.width > 0{
            //aspect ratio
            let aspect:CGFloat = self.image.size.width / self.image.size.height
            
            //to check if landscape or not
            if self.image.size.width > self.image.size.height{
                //portrait
                    thumbSize = CGSize(width: defaultSize, height: defaultSize / aspect)
            }else{
                thumbSize = CGSize(width: defaultSize * aspect, height: defaultSize)
            }
        }
        
        return thumbSize
    }
}
