//
//  PicturesCollectionViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 12/27/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import IDMPhotoBrowser

class PicturesCollectionViewController: UICollectionViewController {
    
    //MARK: - Variables
    var allImages:[UIImage] = []
    var allImageLinks:[String] = []
    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "All Pictures"
        
        if allImageLinks.count > 0 {
            //we have image links,so download images
            DownloadImages()

        }
        
    }

    // MARK: - UICollectionView DataSource functions
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return allImages.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PicturesCollectionViewCell
        // Configure the cell
        cell.GenerateCell(image: allImages[indexPath.row])
        return cell
    }
    
    //MARK: - UICollectionView Delegate functions
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //init a idm photo(should be of type images)
        let photos = IDMPhoto.photos(withImages: allImages)
        //init idm browser
        let browser = IDMPhotoBrowser(photos: photos)
        browser?.displayDoneButton = false
        //idm requires UInt only
        browser?.setInitialPageIndex(UInt(indexPath.row))
        self.present(browser!, animated: true, completion: nil)
    }

    //MARK: - Download Images
    func DownloadImages(){
        for imageLink in  allImageLinks{
            DownloadImage(imageURL: imageLink) { (image) in
                if image != nil{
                    self.allImages.append(image!)
                    self.collectionView.reloadData()
                }
            }
        }
    }
}
