//
//  BlockedUsersViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 12/30/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import ProgressHUD

class BlockedUsersViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var blockedUserTableView: UITableView!
    @IBOutlet weak var blockNotifyLabel: UILabel!
    
    //MARK: - Variables
    var blockedUsers:[FUser] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        blockedUserTableView.tableFooterView = UIView()
        navigationItem.largeTitleDisplayMode = .never
        LoadBlockedUsers()
    }
    
    //MARK: - Functions
    func LoadBlockedUsers(){
        if FUser.currentUser()!.blockedUsers.count > 0 {
            ProgressHUD.show()
            getUsersFromFirestore(withIds: FUser.currentUser()!.blockedUsers) { (blockedUsers) in
                ProgressHUD.dismiss()
                //completion handler blockedUser is FUser type, while locally stored FUser blocked is [String] type
                self.blockedUsers = blockedUsers
                self.TableViewSetup()
                self.blockedUserTableView.reloadData()
            }
        }
    }
    

}

//MARK: - Extensions
extension BlockedUsersViewController:UITableViewDelegate, UITableViewDataSource{
    
    //MARK: - Setup
    func TableViewSetup(){
        blockedUserTableView.delegate = self
        blockedUserTableView.dataSource = self
    }
    
    //MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        blockNotifyLabel.isHidden = blockedUsers.count != 0
        return blockedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //we are re-using usertableviewcell here
        let cell = blockedUserTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UsersTableViewCell
        cell.delegate = self
        cell.GenerateCellWith(fuser: blockedUsers[indexPath.row], indexPath: indexPath)
        return cell
    }
    
    //MARK: - Table view delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        blockedUserTableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "UnBlock"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        var tempBlockUsers = FUser.currentUser()!.blockedUsers
        let userIdToUnBlock = blockedUsers[indexPath.row].objectId
        //remove
        tempBlockUsers.remove(at: tempBlockUsers.index(of: userIdToUnBlock)!)
        self.blockedUsers.remove(at: indexPath.row)
        
        //save to firebase
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID:tempBlockUsers]) { (error) in
            if error != nil{
                ProgressHUD.showError("\(error!.localizedDescription)")
            }
            self.blockedUserTableView.reloadData()
        }
    }
}

extension BlockedUsersViewController: UsersTableViewCellDelegate{
    
    //delegate function
    func DidTapProfilePic(IndexPath: IndexPath) {
        
        //print to check
        print("User at \(IndexPath)")
        
        //to pass data
        let profileViewcontroller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileViewOfUser") as! ProfilePageTableViewController
        
        profileViewcontroller.user = blockedUsers[IndexPath.row]
        
        //present using navigation controller
        self.navigationController?.pushViewController(profileViewcontroller, animated: true)
    }
    
    
}
