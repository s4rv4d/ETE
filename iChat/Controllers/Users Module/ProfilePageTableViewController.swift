//
//  ProfilePageTableViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 11/24/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import ProgressHUD

class ProfilePageTableViewController: UITableViewController {
    
    //MARK:IBOutlets
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var phoneNo: UILabel!
    @IBOutlet weak var messageButtonOutlet: UIButton!
    @IBOutlet weak var callButtonOutlet: UIButton!
    @IBOutlet weak var blockUserButtonOutlet: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    
    //MARK:Variables
    var user:FUser?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()

        SetupUI()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0{
            //for first header
            return 0
        }
        return 30
    }
    
    //MARK:IBActions
    @IBAction func CallButtonTapped(_ sender: UIButton) {
        print("call button tapped for user \(user!.fullname)")
        //call user
        CallUser()
        let currentUser = FUser.currentUser()!
        let call = Call(_callerID: currentUser.objectId, _withUserId: user!.objectId, _callerFullName: currentUser.fullname, _withUserFullName: user!.fullname)
        call.SaveCallInBackground()
    }
    @IBAction func MessageButtonPressed(_ sender: UIButton) {
        print("message button pressed for user \(user!.fullname)")
        //start chat
        
        if !CheckBlockedStatus(user: user!){
            let chatVC = MessageViewController()
            chatVC.memberToPush = [FUser.currentId(),user!.objectId]
            chatVC.memberids = [FUser.currentId(),user!.objectId]
            chatVC.chatRoomId = StartPrivateChat(user1: FUser.currentUser()!, user2: user!)
            chatVC.isGroup = false
            chatVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(chatVC, animated: true)
        }else{
            ProgressHUD.showError("This is user is not available for chat!")
        }
        
    }
    @IBAction func BlockUserButtonPressed(_ sender: UIButton) {
        //get current blocked users
        var currentBlockedUsers = FUser.currentUser()!.blockedUsers
        
        //to check if user in current blocked list,if present then remove else append
        if currentBlockedUsers.contains(user!.objectId){
            //get index of selected user id in blocked list
            let index = currentBlockedUsers.index(of:user!.objectId)!
            currentBlockedUsers.remove(at: index)
        }else{
            currentBlockedUsers.append(user!.objectId)
        }
        //update current user in firestore
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID:currentBlockedUsers]) { (error) in
            print("blocked users:",currentBlockedUsers)
            
            if error != nil{
                print("error updating user: \(error!.localizedDescription)")
                return
            }
            
            self.UpdateBlockStatus()
        }
        
        BlockUser(userToBlock: user!)
    }
    
    //MARK:Functions
    func SetupUI(){
        //first check if user isnt nil
        if user != nil{
            self.title = "Profile"
            //setup names
            fullName.text = user!.fullname
            phoneNo.text = user!.phoneNumber
            
            //check if user is blocked
            UpdateBlockStatus()
            
            //setup image from data
            imageFromData(pictureData: user!.avatar) { (profilePic) in
                if profilePic != nil{
                    self.profileImageView.image = profilePic!.circleMasked
                }
            }
        }
    }
    
    func UpdateBlockStatus(){
        //check if we arent checking our current user
        if user!.objectId != FUser.currentId(){
            //if not current user no need to hide
            blockUserButtonOutlet.isHidden = false
            messageButtonOutlet.isHidden = false
            callButtonOutlet.isHidden = false
        }else{
            //if current user need to hide
            blockUserButtonOutlet.isHidden = true
            messageButtonOutlet.isHidden = true
            callButtonOutlet.isHidden = true
        }
        
        //to check if this user is in current users blocked id
        if (FUser.currentUser()?.blockedUsers.contains(user!.objectId))!{
            blockUserButtonOutlet.setTitle("Unblock User", for: .normal)
        }else{
            blockUserButtonOutlet.setTitle("Block User", for: .normal)
        }
    }
    
    //MARK: - Call
    func CallUser(){
        let userToCall = user!.objectId
        let call = CallClient().callUser(withId: userToCall)
        let callVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "call") as! CallViewController
        callVC._call = call!
        self.present(callVC, animated: true, completion: nil)
    }
    
    func CallClient() -> SINCallClient{
        return appDelegate._client.call()
    }

}
