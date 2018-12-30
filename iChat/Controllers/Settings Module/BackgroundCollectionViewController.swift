//
//  BackgroundCollectionViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 12/30/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import ProgressHUD

private let reuseIdentifier = "cell"

class BackgroundCollectionViewController: UICollectionViewController {
    
    //MARK: - Variables
    var backgrounds:[UIImage] = []
    let userDef = UserDefaults.standard
    private let imageNames:[String] = ["bg0","bg1","bg2","bg3","bg4","bg5","bg6","bg7","bg8","bg9","bg10","bg11"]

    override func viewDidLoad() {
        super.viewDidLoad()
        GenerateImagesInArray()
        
        let resetButton = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(self.ResetToDefault))
        self.navigationItem.rightBarButtonItem = resetButton
    }
    
    //MARK: - Functions
    func GenerateImagesInArray(){
        backgrounds = []
        for imageName in imageNames{
            let image = UIImage(named: imageName)
            
            if image != nil{
                backgrounds.append(image!)
            }
        }
    }
    
    @objc func ResetToDefault(){
        userDef.removeObject(forKey: kBACKGROUBNDIMAGE)
        userDef.synchronize()
        ProgressHUD.showSuccess("Reset back to default!")
    }


    // MARK: - UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return backgrounds.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BackgroundCollectionViewCell
        cell.GenerateCell(image: backgrounds[indexPath.row])
        return cell
    }

    // MARK: - UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        userDef.set(imageNames[indexPath.row], forKey: kBACKGROUBNDIMAGE)
        userDef.synchronize()
        ProgressHUD.showSuccess("Set!")
    }

}
