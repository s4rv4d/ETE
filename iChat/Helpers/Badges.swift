//
//  Badges.swift
//  iChat
//
//  Created by Sarvad shetty on 1/3/19.
//  Copyright © 2019 Sarvad shetty. All rights reserved.
//

import Foundation
import FirebaseFirestore


//MARK: - Functions
func RecentBadgeCount(withBlock:@escaping(_ badgeNumber:Int)->Void){
    recentBadgeHandler = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener({ (snapshot, error) in
        guard let snapshot = snapshot else {return}
        
        var badge = 0
        var counter = 0
        
        if !snapshot.isEmpty{
            let recents = snapshot.documents
            
            for recent in recents{
                let currentRecent = recent.data() as NSDictionary
                badge += currentRecent[kCOUNTER] as! Int
                counter += 1
                
                if counter == recents.count{
                    withBlock(badge)
                }
            }
        }else{
            withBlock(badge)
        }
    })
}

func SetBadges(controller:UITabBarController){
    RecentBadgeCount { (count) in
        if count != 0{
            controller.tabBar.items![0].badgeValue = "\(count)"
        }else{
            controller.tabBar.items![0].badgeValue = nil
        }
    }
}
