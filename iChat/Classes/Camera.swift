//
//  Camera.swift
//  iChat
//
//  Created by Sarvad shetty on 12/25/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

class Camera{
    
    //MARK: - Delegate setup
    var delegate:UIImagePickerControllerDelegate & UINavigationControllerDelegate
    
    init(delegate_:UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
        delegate = delegate_
    }
    
    func PresentPhotoLibrary(target:UIViewController, canEdit:Bool){
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) && !UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            return
        }
        
        let type = kUTTypeImage as String
        let imagePicker = UIImagePickerController()
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            imagePicker.sourceType = .photoLibrary
            
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary){
                if (availableTypes as NSArray).contains(type){
                    //set up defaults
                    imagePicker.mediaTypes = [type]
                    imagePicker.allowsEditing = canEdit
                }
            }
        }else if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            imagePicker.sourceType = .savedPhotosAlbum
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .savedPhotosAlbum){
                if (availableTypes as NSArray).contains(type){
                    imagePicker.mediaTypes = [type]
                    
                }
            }
        }else{
            return
        }
        
        imagePicker.allowsEditing = canEdit
        imagePicker.delegate = delegate
        //present image picker
        target.present(imagePicker, animated: true, completion: nil)
        
        return
    }
    
    func PresentMultiCamera(target:UIViewController, canEdit:Bool){
        if !UIImagePickerController.isSourceTypeAvailable(.camera){
            return
        }
        
        let type1 = kUTTypeImage as String
        let type2 = kUTTypeMovie as String
        
        let imagePicker = UIImagePickerController()
        
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera){
                if(availableTypes as NSArray).contains(type1){
                    imagePicker.mediaTypes = [type1,type2]
                    imagePicker.sourceType = .camera
                }
            }
        }
        
        if UIImagePickerController.isCameraDeviceAvailable(.rear){
            imagePicker.cameraDevice = .rear
        }else if UIImagePickerController.isCameraDeviceAvailable(.front){
            imagePicker.cameraDevice = .front
        }else{
            //show alert
            return
        }
        
        imagePicker.allowsEditing = canEdit
        imagePicker.showsCameraControls = true
        imagePicker.delegate = delegate
        target.present(imagePicker, animated: true, completion: nil)
        
    }
    
    func PresentPhotoCamera(target:UIViewController, canEdit:Bool){
        if !UIImagePickerController.isSourceTypeAvailable(.camera){
            return
        }
        
        let type1 = kUTTypeImage as String
        let imagePicker = UIImagePickerController()
        
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera){
                if(availableTypes as NSArray).contains(type1){
                    imagePicker.mediaTypes = [type1]
                    imagePicker.sourceType = .camera
                }
            }
        }
        
        if UIImagePickerController.isCameraDeviceAvailable(.rear){
            imagePicker.cameraDevice = .rear
        }else if UIImagePickerController.isCameraDeviceAvailable(.front){
            imagePicker.cameraDevice = .front
        }else{
            //show alert
            return
        }
        
        imagePicker.allowsEditing = canEdit
        imagePicker.showsCameraControls = true
        imagePicker.delegate = delegate
        target.present(imagePicker, animated: true, completion: nil)
        
    }
    
    func PresentVideoCamera(target:UIViewController, canEdit:Bool){
        if !UIImagePickerController.isSourceTypeAvailable(.camera){
            return
        }
        
        let type1 = kUTTypeMovie as String
        let imagePicker = UIImagePickerController()
        
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera){
                if(availableTypes as NSArray).contains(type1){
                    imagePicker.mediaTypes = [type1]
                    imagePicker.sourceType = .camera
                    imagePicker.videoMaximumDuration = kMAXDURATION
                }
            }
        }
        
        if UIImagePickerController.isCameraDeviceAvailable(.rear){
            imagePicker.cameraDevice = .rear
        }else if UIImagePickerController.isCameraDeviceAvailable(.front){
            imagePicker.cameraDevice = .front
        }else{
            //show alert
            return
        }
        
        imagePicker.allowsEditing = canEdit
        imagePicker.showsCameraControls = true
        imagePicker.delegate = delegate
        target.present(imagePicker, animated: true, completion: nil)
        
    }
    
    func PresentVideoLibrary(target:UIViewController, canEdit:Bool){
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) && !UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            return
        }
        
        let type = kUTTypeMovie as String
        let imagePicker = UIImagePickerController()
        imagePicker.videoMaximumDuration = kMAXDURATION
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            imagePicker.sourceType = .photoLibrary
            
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary){
                if (availableTypes as NSArray).contains(type){
                    //set up defaults
                    imagePicker.mediaTypes = [type]
                    imagePicker.allowsEditing = canEdit
                }
            }
        }else if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            imagePicker.sourceType = .savedPhotosAlbum
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .savedPhotosAlbum){
                if (availableTypes as NSArray).contains(type){
                    imagePicker.mediaTypes = [type]
                    
                }
            }
        }else{
            return
        }
        
        imagePicker.allowsEditing = canEdit
        imagePicker.delegate = delegate
        target.present(imagePicker, animated: true, completion: nil)
        return
        
    }
}
