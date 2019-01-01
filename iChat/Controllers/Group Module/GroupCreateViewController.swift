//
//  GroupCreateViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 12/31/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker

class GroupCreateViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var participantsCollec: UICollectionView!
    @IBOutlet weak var editButtonOutlet: UIButton!
    @IBOutlet weak var groupIconImageView: UIImageView!
    @IBOutlet weak var groupNameTextfield: UITextField!
    @IBOutlet weak var particiCount: UILabel!
    @IBOutlet var iconTappedOutlet: UITapGestureRecognizer!
    
    //MARK: - Variables
    var memberIds:[String] = []
    var allMembers:[FUser] = []
    var groupIcon:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        CollectioViewSetup()
        navigationItem.largeTitleDisplayMode = .never
        groupIconImageView.isUserInteractionEnabled = true
        groupIconImageView.addGestureRecognizer(iconTappedOutlet)
        UpdateParticipantsLabel()
        editButtonOutlet.isHidden = true
    }
    
    //MARK: - Helper Functions
    func dismissKeyboard() {
        self.view.endEditing(false)
    }
    
    func ShowIconOption(){
        let optionMenu = UIAlertController(title: "Choose Group Icon", message: nil, preferredStyle: .actionSheet)
        let takePhoto = UIAlertAction(title: "Take/Choose Photo", style: .default) { (action) in
            print("camera")
            let imgPickerController = ImagePickerController()
            imgPickerController.delegate = self
            imgPickerController.imageLimit = 1
            
            //dismiss keyboard
            self.dismissKeyboard()
            self.present(imgPickerController, animated: true, completion: nil)
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        if groupIcon != nil{
            let resetAction = UIAlertAction(title: "Reset", style: .default) { (action) in
                self.groupIcon = nil
                self.groupIconImageView.image = UIImage(named: "cameraIcon")
                self.editButtonOutlet.isHidden = true
            }
            optionMenu.addAction(resetAction)
        }
        
        optionMenu.addAction(takePhoto)
        optionMenu.addAction(cancelAction)
        
        //to check for iPads
        if (UI_USER_INTERFACE_IDIOM() == .pad){
            if let currentPopoverPresebtationController = optionMenu.popoverPresentationController{
                currentPopoverPresebtationController.sourceView = editButtonOutlet
                currentPopoverPresebtationController.sourceRect = editButtonOutlet.bounds
                currentPopoverPresebtationController.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        }else{
            self.present(optionMenu, animated: true, completion: nil)
        }
        
    }
    
    
    func UpdateParticipantsLabel(){
        particiCount.text = "PARTICIPANTS: \(allMembers.count)"
        
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(self.CreateButtonTapped))]
        self.navigationItem.rightBarButtonItem?.isEnabled = allMembers.count > 0
    }
    
    @objc func CreateButtonTapped(_ sender:Any){
        print("Create button tapped")
        
        if groupNameTextfield.text != ""{
            //add current user to group
            //keep in mind only user ids is used to create chat notb FUser
            memberIds.append(FUser.currentId())
            var avatarData = UIImage(named:"groupIcon")?.jpegData(compressionQuality: 0.7)
            var avatar = avatarData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            
            if groupIcon != nil{
                 avatarData = groupIcon!.jpegData(compressionQuality: 0.7)!
                avatar = avatarData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            }
            
            let groupID = UUID().uuidString
            
            //create group
            let group = Group(groupID: groupID, subject: groupNameTextfield.text!, owner: FUser.currentId(), members: memberIds, avatar: avatar!)
            group.SaveGroup()
            
            //create group recent
            StartgroupChat(group: group)
            
            //go to message view controller
            let chatVC = MessageViewController()
            chatVC.titleName = group.groupDictionary[kNAME] as! String
            chatVC.memberids = group.groupDictionary[kMEMBERS] as! [String]
            chatVC.memberToPush = group.groupDictionary[kMEMBERS] as! [String]
            chatVC.chatRoomId = groupID
            chatVC.isGroup = true
            chatVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(chatVC, animated: true)
            
        }else{
            ProgressHUD.showError("Subject is required")
        }
    }
    
    @IBAction func IconTappedAction(_ sender: UITapGestureRecognizer) {
        print("icon tapped")
        ShowIconOption()
    }
    
    @IBAction func EditButtonTapped(_ sender: UIButton) {
        ShowIconOption()
    }
}

//MARK: - Extensions
extension GroupCreateViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    
    func CollectioViewSetup(){
        participantsCollec.delegate = self
        participantsCollec.dataSource = self
    }
    
    //MARK: - Collection view datasource functions
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allMembers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = participantsCollec.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GroupMembersCollectionViewCell
        cell.delegate = self
        cell.GenerateCell(user: allMembers[indexPath.row], index: indexPath)
        return cell
    }
    
}

extension GroupCreateViewController: GroupMembersCollectionViewCellDelegate{
    
    //MARK: - Delegate function
    func DidTapDeleteButton(indexPath: IndexPath) {
        allMembers.remove(at: indexPath.row)
        memberIds.remove(at: indexPath.row)
        self.participantsCollec.reloadData()
        UpdateParticipantsLabel()
    }    
}

extension GroupCreateViewController: ImagePickerDelegate{
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        //do nothing here, just dismiss
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        
        if images.count > 0{
            self.editButtonOutlet.isHidden = false
            self.groupIcon = images.first!
            self.groupIconImageView.image = self.groupIcon!.circleMasked
        }else{
            self.editButtonOutlet.isHidden = true
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        //do nothing here, just dismiss
        self.dismiss(animated: true, completion: nil)
    }
    
    
}
