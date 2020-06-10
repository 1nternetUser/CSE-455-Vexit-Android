//
//  BasicUser.swift
//  VEXTit Drop

import UIKit

class BasicUser: NSObject {

    var name: String?
    var userPictureURL: URL?
    var userPictureName: String?
    var userPicture: UIImage?
    
    init(name: String,
         userPictureName: String) {
        self.name = name
        self.userPictureName = userPictureName
    }
}
