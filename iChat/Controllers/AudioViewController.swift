//
//  AudioViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 12/26/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import Foundation
import IQAudioRecorderController

class AudioViewController{
    
    //MARK: - Variables
    var delegate:IQAudioRecorderViewControllerDelegate
    
    init(delegate_:IQAudioRecorderViewControllerDelegate) {
        delegate = delegate_
    }
    
    //MARK: - Functions
    func PresentAudioRecorder(target:UIViewController){
        let controller = IQAudioRecorderViewController()
        controller.delegate = delegate
        
        controller.title = "Record"
        controller.maximumRecordDuration = kAUDIOMAXDURATION
        controller.allowCropping = true
        
        target.presentBlurredAudioRecorderViewControllerAnimated(controller)
    }
}
