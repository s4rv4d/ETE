//
//  Downloader.swift
//  iChat
//
//  Created by Sarvad shetty on 12/25/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import Foundation
import FirebaseStorage
import Firebase
import MBProgressHUD
import AVFoundation

let storage = Storage.storage()

//MARK: - Image
func UploadImage(image:UIImage, chatRoomId:String, view:UIView, completion:@escaping(_ imageLink:String?)->Void){
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    progressHUD.mode = .determinateHorizontalBar
    
    let dateString = dateFormatter().string(from: Date())
    
    let photoFileName = "Pictures/" + FUser.currentId() + "/" + chatRoomId + "/" + dateString + ".jpg"
    
    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(photoFileName)
    //converting data into jpeg
//    let imgDATA = UIImageJPEGRepresentation(image, 0.7)
    let imgDATA = image.jpegData(compressionQuality: 0.7)
    var task:StorageUploadTask!
    task = storageRef.putData(imgDATA!, metadata: nil, completion: { (metadata, error) in
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        
        if error != nil{
            print("error uploading \(error!.localizedDescription)")
        }
        
        storageRef.downloadURL(completion: { (url, error) in
            guard let downloadedURL = url else {completion(nil)
                return
            }
            
            completion(downloadedURL.absoluteString)
        })
    })
    //status amount of data uploaded in progress hud
    task.observe(.progress) { (snapshot) in
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
    }
}

func DownloadImage(imageURL:String, completion:@escaping(_ image:UIImage?)->Void){
    let imageUrl = NSURL(string: imageURL)
    print(imageURL)
    let imageFileName = (imageURL.components(separatedBy: "%").last!).components(separatedBy: "?").first
    print("file name \(imageFileName)")
    
    if FileExistInDocuments(filepath: imageFileName!){
        if let contentsOfFile = UIImage(contentsOfFile: FileInDocumentsDirectory(filename: imageFileName!)){
            completion(contentsOfFile)
        }else{
            print("couldnt generate image")
            completion(nil)
        }
    }else{
        //doesnt exist so have to downlaod
        //steps:
        //1.downlaod
        //2.savelocally
        //3.return
        let downloadQueue = DispatchQueue(label: "imageDownloadQueue")
        downloadQueue.async {
            let data = NSData(contentsOf: imageUrl! as URL)
            
            if data != nil{
                var docURL = GetDocumentsURL()
                //to save locally
                docURL = docURL.appendingPathComponent(imageFileName!, isDirectory:false)
                //atomically means if there was a corrupt file before after downloading the original file the corrupt file will be deleted
                data!.write(to: docURL, atomically: true)
                
                let imageToReturn = UIImage(data: data! as Data)
                
                DispatchQueue.main.async {
                    completion(imageToReturn!)
                }
                
            }else{
                //url empty
                DispatchQueue.main.async {
                    print("no image in database")
                    completion(nil)
                }
            }
        }
    }
}

//helpers
func FileInDocumentsDirectory(filename:String) -> String{
    let fileURL = GetDocumentsURL().appendingPathComponent(filename)
    return fileURL.path
}

func GetDocumentsURL() -> URL{
    let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    return documentURL!
}

func FileExistInDocuments(filepath:String) -> Bool{
    var doesExist = false
    
    let filePTH = FileInDocumentsDirectory(filename: filepath)
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: filePTH){
        doesExist = true
    }else{
        doesExist = false
    }
    
    return doesExist
}

//MARK: - Video
func UploadVideo(video:NSData, chatroomID:String, view:UIView, completion:@escaping(_ videoLink:String?)->Void){
    let progress = MBProgressHUD.showAdded(to: view, animated: true)
    progress.mode = .determinateHorizontalBar
    
    let dateString = dateFormatter().string(from: Date())
    
    let videoFileName = "VideoMessages/" + FUser.currentId() + "/" + chatroomID + "/" + "\(dateString).mov"
    
    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(videoFileName)
    
    var task:StorageUploadTask!
    
    task = storageRef.putData(video as Data, metadata: nil, completion: { (metadata, error) in
        task.removeAllObservers()
        
        progress.hide(animated: true)
        
        if error != nil{
            print("error couldn't upload video \(error?.localizedDescription)")
            return
        }
        
        storageRef.downloadURL(completion: { (url, error) in
            guard let URL = url else {completion(nil)
                return
            }
            
            completion(URL.absoluteString)
        })
    })
    
    //for the percentage of completion status
    task.observe(.progress) { (snapshot) in
        progress.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
    }
}

//to get the first frmae from video as thumbnail
func VideoThumbnail(video:NSURL) -> UIImage{
    //get video asset from video(basically video)
    let asset = AVURLAsset(url: video as URL, options: nil)
    
    //this will create the thumbnail
    let imgGenerator = AVAssetImageGenerator(asset: asset)
    imgGenerator.appliesPreferredTrackTransform = true
    
    let time = CMTimeMakeWithSeconds(0.5, preferredTimescale: 1000)
    var actualTime = CMTime.zero
    
    var image:CGImage?
    
    do{
        image = try imgGenerator.copyCGImage(at: time, actualTime: &actualTime)
    }catch let error as NSError{
        print(error.localizedDescription)
    }
    
    let thumbnail = UIImage(cgImage: image!)
    return thumbnail
}

func DownloadVideo(videoURL:String, completion:@escaping(_ isReadyToPlay:Bool,_ videoFileName:String)->Void){
    let videoUrl = NSURL(string: videoURL)
    print(videoURL)
    let VideoFileName = (videoURL.components(separatedBy: "%").last!).components(separatedBy: "?").first
    print("file name \(VideoFileName)")
    
    if FileExistInDocuments(filepath: VideoFileName!){
        //exist
        completion(true,VideoFileName!)
    }else{
        //doesnt exist so have to downlaod
        //steps:
        //1.downlaod
        //2.save locally
        //3.return
        let downloadQueue = DispatchQueue(label: "videoDownloadQueue")
        downloadQueue.async {
            let data = NSData(contentsOf: videoUrl! as URL)
            
            if data != nil{
                var docURL = GetDocumentsURL()
                //to save locally
                //is directory is false because its not a folder but its a file
                docURL = docURL.appendingPathComponent(VideoFileName!, isDirectory:false)
                //atomically means if there was a corrupt file before after downloading the original file the corrupt file will be deleted
                data!.write(to: docURL, atomically: true)
                
                DispatchQueue.main.async {
                    completion(true,VideoFileName!)
                }
                
            }else{
                //url empty
                DispatchQueue.main.async {
                    print("no video in database")
                }
            }
        }
    }
}

//MARK: - Audio messages
func UploadAudioMessage(audioPath:String, chatroomID:String, view:UIView, completion:@escaping(_ audioLink:String?)->Void){
    let progress = MBProgressHUD.showAdded(to: view, animated: true)
    progress.mode = .determinateHorizontalBar
    
    let dateString = dateFormatter().string(from: Date())
    
    let audioFileName = "AudioMessages/" + FUser.currentId() + "/" + chatroomID + "/" + "\(dateString).m4a"
    
    let audio = NSData(contentsOfFile: audioPath)
    
    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(audioFileName)
    
    var task:StorageUploadTask!
    
    task = storageRef.putData(audio! as Data, metadata: nil, completion: { (metadata, error) in
        task.removeAllObservers()
        
        progress.hide(animated: true)
        
        if error != nil{
            print("error couldn't upload audio \(error!.localizedDescription)")
            return
        }
        
        storageRef.downloadURL(completion: { (url, error) in
            guard let URL = url else {completion(nil)
                return
            }
            
            completion(URL.absoluteString)
        })
    })
    
    //for the percentage of completion status
    task.observe(.progress) { (snapshot) in
        progress.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
    }
}

func DownloadAudio(audioURL:String, completion:@escaping(_ audioFileName:String)->Void){
    let audioUrl = NSURL(string: audioURL)
    print(audioURL)
    let audioFileName = (audioURL.components(separatedBy: "%").last!).components(separatedBy: "?").first!
    print("file name \(audioFileName)")
    
    if FileExistInDocuments(filepath: audioFileName){
       completion(audioFileName)
    }else{
        //doesnt exist so have to downlaod
        //steps:
        //1.downlaod
        //2.savelocally
        //3.return
        let downloadQueue = DispatchQueue(label: "audioDownloadQueue")
        downloadQueue.async {
            let data = NSData(contentsOf: audioUrl! as URL)
            
            if data != nil{
                var docURL = GetDocumentsURL()
                //to save locally
                docURL = docURL.appendingPathComponent(audioFileName, isDirectory:false)
                //atomically means if there was a corrupt file before after downloading the original file the corrupt file will be deleted
                data!.write(to: docURL, atomically: true)
                DispatchQueue.main.async {
                    completion(audioFileName)
                }
                
            }else{
                //url empty
                DispatchQueue.main.async {
                    print("no audio file in database")
                }
            }
        }
    }
}
