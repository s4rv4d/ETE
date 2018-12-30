//
//  SettingsTableViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 11/19/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import ProgressHUD

class SettingsTableViewController: UITableViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var deleteButtonOutlet: UIButton!
    @IBOutlet weak var avatarSwitch: UISwitch!
    @IBOutlet weak var appVersionLabel: UILabel!
    
    //MARK: - Variables
    var avatarSwitchStatus = false
    let userDefaults = UserDefaults.standard
    var firstLoad:Bool?
    
    override func viewDidAppear(_ animated: Bool) {
        if FUser.currentUser() != nil{
            SetupUI()
            LoadUserDefaults()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //navigation bar big titles
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.tableFooterView = UIView()
        
    }
    
    
    //MARK: - IBActions
    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        FUser.logOutCurrentUser { (success) in
            if success{
                //show login page now after logout
                self.ShowloginPage()
            }
        }
    }
    
    @IBAction func ShowAvatarSwitchTap(_ sender: UISwitch) {
        avatarSwitchStatus = sender.isOn
        //save to user defaults
        SaveUserDefaults()
    }
    
    @IBAction func ClearCacheButtonTapped(_ sender: UIButton) {
        //for deleting local saved file
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: GetDocumentsURL().path)
            for file in files{
               try FileManager.default.removeItem(atPath: "\(GetDocumentsURL().path)/\(file)")
            }
            ProgressHUD.showSuccess("Cache cleaned!")
        } catch  {
            ProgressHUD.showError("Could'nt clean media files")
        }
    }
    
    @IBAction func TellAFriendTapped(_ sender: UIButton) {
        let text = "Hey! lets chat on ETE \(kAPPURL)"
        let objectsToShare:[Any] = [text]
        
        //activity vc
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        activityVC.setValue("Lets Chat in ETE", forKey: "subject")
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @IBAction func DeleteAccTapped(_ sender: UIButton) {
        let optionMenu = UIAlertController(title: "Delete Account", message: "Are you sure, you want to delete your account?", preferredStyle: .actionSheet)
        let delAction = UIAlertAction(title: "Delete", style: .destructive) { (alert) in
            //delete the user
            self.DeleteAcc()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        optionMenu.addAction(delAction)
        optionMenu.addAction(cancelAction)
        
        //to check for iPads
        if (UI_USER_INTERFACE_IDIOM() == .pad){
            if let currentPopoverPresebtationController = optionMenu.popoverPresentationController{
                currentPopoverPresebtationController.sourceView = deleteButtonOutlet
                currentPopoverPresebtationController.sourceRect = deleteButtonOutlet.bounds
                currentPopoverPresebtationController.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        }else{
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
    

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        if section == 1{
            return 5
        }
        
        return 2
    }
    
    //MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0{
            return 0
        }else{
            return 30
        }
    }
    
    //MARK: - Functions
    func ShowloginPage(){
        
        //initialize storyboard
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginPage")
        self.present(mainView, animated: true, completion: nil)
    }
    
    func SetupUI(){
        //UI Setup
        let currentUser = FUser.currentUser()!
        fullNameLabel.text = currentUser.fullname
        if currentUser.avatar != ""{
            imageFromData(pictureData: currentUser.avatar) { (image) in
                if image != nil{
                    self.profileImageView.image = image!.circleMasked
                }
            }
        }
        
        //set app version
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String{
            appVersionLabel.text = version
        }
    }
    
    //User defaults
    
    func SaveUserDefaults(){
        userDefaults.set(avatarSwitchStatus, forKey: kSHOWAVATAR)
        userDefaults.synchronize()
    }
    
    func LoadUserDefaults(){
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        
        if !firstLoad!{
            userDefaults.set(true, forKey: kFIRSTRUN)
            userDefaults.set(avatarSwitchStatus, forKey: kSHOWAVATAR)
            userDefaults.synchronize()
        }
        
        avatarSwitchStatus = userDefaults.bool(forKey: kSHOWAVATAR)
        avatarSwitch.isOn = avatarSwitchStatus
    }
    
    func DeleteAcc(){
        //delete locally first
        userDefaults.removeObject(forKey: kPUSHID)
        userDefaults.removeObject(forKey: kCURRENTUSER)
        userDefaults.synchronize()
        //delete from firebase
        reference(.User).document(FUser.currentId()).delete()
        FUser.deleteUser { (error) in
            if error != nil{
                DispatchQueue.main.async {
                    ProgressHUD.showError("Could'nt delete user")
                }
                return
            }else{
                self.ShowloginPage()
            }
        }
    }
    

}
