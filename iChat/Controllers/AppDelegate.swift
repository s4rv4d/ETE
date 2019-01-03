//
//  AppDelegate.swift
//  iChat
//
//  Created by Sarvad shetty on 7/25/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import RNCryptor
import OneSignal
import PushKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, SINClientDelegate, SINCallClientDelegate, SINManagedPushDelegate, PKPushRegistryDelegate {

    var window: UIWindow?
    var authListener: AuthStateDidChangeListenerHandle?
    var locationManager:CLLocationManager?
    var coordinates:CLLocationCoordinate2D?
    var _client:SINClient!
    var push:SINManagedPush!
    var callKitProvider: SINCallKitProvider!
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        //Auto login
        authListener = Auth.auth().addStateDidChangeListener({ (auth, user) in
            //addStateDidChangeListener has to be called once so need to remove after first call
            Auth.auth().removeStateDidChangeListener(self.authListener!)
            
            //to check if user exists
            if user != nil{
//                print(user)
                if UserDefaults.standard.object(forKey: kCURRENTUSER) != nil{
                    //appdelegate runs on main thread
                    print("re",UserDefaults.standard.object(forKey: kCURRENTUSER))
                    DispatchQueue.main.async {
                        self.GoToApp()
                    }
                }
            }
        })
        
//        self.VoipRegistration()
        self.push = Sinch.managedPush(with: .development)
        self.push.delegate = self
        self.push.setDesiredPushTypeAutomatically()
    
        //one signal and sinch
        func UserDidLogin(userId:String){
            print("herererhbdagdgdadgashg")
            self.push.registerUserNotificationSettings()
            self.InitSinchWithUserID(userdID: userId)
            self.StartOneSignal()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(USER_DID_LOGIN_NOTIFICATION), object: nil, queue: nil) { (note) in
            let userID = note.userInfo![kUSERID] as! String
            print("user",userID)
            UserDefaults.standard.set(userID, forKey: kUSERID)
            UserDefaults.standard.synchronize()
//            print(userID)
            UserDidLogin(userId: userID)
        }
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound], completionHandler: { (granted, error) in
            })
            application.registerForRemoteNotifications()
        } else {
            let types: UIUserNotificationType = [.alert, .badge, .sound]
            let settings = UIUserNotificationSettings(types: types, categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        //to remove the inapp local notification
        OneSignal.initWithLaunchOptions(launchOptions, appId: kONESIGNALAPPID, handleNotificationAction: nil, settings: [kOSSettingsKeyInAppAlerts:false])
        
        return true
    }
    
    //MARK: - Custom function
    func GoToApp(){
        
        //posting a notification
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID:FUser.currentId()])
        
        //initialize a storyboard
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        //making root view controller
        self.window?.rootViewController = mainView
        
    }
    
    func LocationManagerStart(){
        if locationManager == nil{
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.requestWhenInUseAuthorization()
        }
        
        locationManager!.startUpdatingLocation()
    }
    
    func LocationManagerStop(){
        if locationManager != nil{
            locationManager!.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("fail to get location \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .authorizedAlways:
            manager.startUpdatingLocation()
        case .restricted:
            print("restricted for now")
        case .denied:
            locationManager = nil
            print("denied location access")
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coordinates = locations.last!.coordinate
    }
    
    //puah noti
    func StartOneSignal(){
        let status:OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let userID = status.subscriptionStatus.userId
        let pushToken = status.subscriptionStatus.pushToken
        
        if pushToken != nil{
            if let playerId = userID{
                print("after log player id is: \(playerId)")
                UserDefaults.standard.set(playerId, forKey: kPUSHID)
            }else{
                UserDefaults.standard.removeObject(forKey: kPUSHID)
            }
            UserDefaults.standard.synchronize()
        }
        //Upadte onesignal
        updateOneSignalId()
    }
    
    //MARK: - Sinch
    func InitSinchWithUserID(userdID:String){
        if _client == nil{
            _client = Sinch.client(withApplicationKey: kSINCHKEY, applicationSecret: kSINCHSECRET, environmentHost: "sandbox.sinch.com", userId: userdID)
            
            _client.delegate = self
            _client.call()?.delegate = self
            
            _client.setSupportCalling(true)
            _client.enableManagedPushNotifications()
            _client.start()
            _client.startListeningOnActiveConnection()
            callKitProvider = SINCallKitProvider(withClient: _client)
        }
    }
    
    func managedPush(_ managedPush: SINManagedPush!, didReceiveIncomingPushWithPayload payload: [AnyHashable : Any]!, forType pushType: String!) {
//        let result = SINPushHelper.queryPushNotificationPayload(payload)
        
//        //to check if call
//        if result!.isCall(){
//            print("Incoming push payload")
//
//            //handle remote notifications
//            self.HandleRemoteNotifications(userInfo: payload as NSDictionary)
//        }
        
        print("managed push")
        if pushType == "PKPushTypeVoIP" {
            self.HandleRemoteNotifications(userInfo: payload as NSDictionary)
        }
    }
    
    func HandleRemoteNotifications(userInfo:NSDictionary){
        if _client == nil{
            if let userId = UserDefaults.standard.object(forKey: kUSERID) {
                self.InitSinchWithUserID(userdID: userId as! String)
            }
        }
        
        let result = self._client.relayRemotePushNotification(userInfo as! [AnyHashable:Any])
        
        if result!.isCall(){
            print("handle call notification")
        }
        
        if result!.isCall() && result!.call()!.isCallCanceled{
            //present missed call
            self.PresentMissedCallNotificationWithRemoteUserID(userID: result!.call()!.callId)
        }
    }
    
    func PresentMissedCallNotificationWithRemoteUserID(userID:String){
        if UIApplication.shared.applicationState == .background{
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "Missed Call"
            content.body = "From \(userID)"
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            let request = UNNotificationRequest(identifier: "ContentIdentifier", content: content, trigger: trigger)
            center.add(request) { (error) in
                if error != nil{
                    print("error on noti \(error!.localizedDescription)")
                }
            }
        }
    }
    
    //sinch call client delegate
    func client(_ client: SINCallClient!, willReceiveIncomingCall call: SINCall!) {
        print("will receive incoming call")
        callKitProvider.reportNewIncomingCall(call: call)
        
    }
    
    func client(_ client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {
        print("did receive incoming call")
        //present call view
        var top = self.window?.rootViewController
        
        while (top?.presentedViewController != nil) {
            top = top?.presentedViewController
        }
        
        let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "call") as! CallViewController
        
        callVC._call = call
        top?.present(callVC, animated: true, completion: nil)    }
    
    func clientDidStart(_ client: SINClient!) {
        print("sinch did start")
    }
    
    func clientDidStop(_ client: SINClient!) {
        print("sinch did stop")
    }
    
    func clientDidFail(_ client: SINClient!, error: Error!) {
        print("sinch did fail \(error.localizedDescription)")
    }
    
    func VoipRegistration(){
        let voipRegistry:PKPushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        //used to silence the error
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        print("did get incoming push")
        
        self.HandleRemoteNotifications(userInfo: payload.dictionaryPayload as NSDictionary)
    }
    
    //MARK: - Push notification functions
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        self.push.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
         Auth.auth().setAPNSToken(deviceToken, type:AuthAPNSTokenType.sandbox)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let firebaseAuthentication = Auth.auth()
        if firebaseAuthentication.canHandleNotification(userInfo){
            return
        }else{
//            self.push.application(application, didReceiveRemoteNotification: userInfo)
        }
    }
    
    ////////////////////////////////////////

    //MARK: - Delegate functions
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        //badge listener
        recentBadgeHandler?.remove()
        
        //update user online status
        if FUser.currentUser() != nil{
            updateCurrentUserInFirestore(withValues: [kISONLINE:false]) { (success) in
            }
        }
        
        LocationManagerStop()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        if callKitProvider != nil {
            let call = callKitProvider.currentEstablishedCall()
            
            if call != nil {
                var top = self.window?.rootViewController
                
                while (top?.presentedViewController != nil) {
                    top = top?.presentedViewController
                }
                
                
                if !(top! is CallViewController) {
                    let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "call") as! CallViewController
                    
                    callVC._call = call
                    
                    top?.present(callVC, animated: true, completion: nil)
                }
            }
        }
        // If there is one established call, show the callView of the current call when the App is brought to foreground.
        // This is mainly to handle the UI transition when clicking the App icon on the lockscreen CallKit UI.

    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        var top = self.window?.rootViewController
        while top?.presentedViewController != nil{
            top = top?.presentedViewController
        }
        
        if top! is UITabBarController{
            SetBadges(controller: top as! UITabBarController)
        }
        
        //update user online status
        if FUser.currentUser() != nil{
            updateCurrentUserInFirestore(withValues: [kISONLINE:true]) { (success) in
                
            }
        }
        
        LocationManagerStart()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

