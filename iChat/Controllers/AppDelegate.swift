//
//  AppDelegate.swift
//  iChat
//
//  Created by Sarvad shetty on 7/25/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var authListener: AuthStateDidChangeListenerHandle?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        //Auto login
        authListener = Auth.auth().addStateDidChangeListener({ (auth, user) in
            //addStateDidChangeListener has to be called once so need to remove after first call
            Auth.auth().removeStateDidChangeListener(self.authListener!)
            
            //to check if user exists
            if user != nil{
                print(user)
                if UserDefaults.standard.object(forKey: kCURRENTUSER) != nil{
                    //appdelegate runs on main thread
                    print(UserDefaults.standard.object(forKey: kCURRENTUSER))
                    DispatchQueue.main.async {
                        self.GoToApp()
                    }
                }
            }
        })
        
        return true
    }
    
    //MARK:Custom function
    func GoToApp(){
        
        //posting a notification
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID:FUser.currentId()])
        
        //initialize a storyboard
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        //making root view controller
        self.window?.rootViewController = mainView
        
    }
    ////////////////////////////////////////

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

