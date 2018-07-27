//
//  CollectionReference.swift
//  iChat
//
//  Created by Sarvad shetty on 7/27/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import Foundation
import FirebaseFirestore


enum FCollectionReference: String {
    case User
    case Typing
    case Recent
    case Message
    case Group
    case Call
}


func reference(_ collectionReference: FCollectionReference) -> CollectionReference{
    return Firestore.firestore().collection(collectionReference.rawValue)
}
