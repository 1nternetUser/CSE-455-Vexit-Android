//
//  User.swift
//  VEXTit Drop

import Foundation
import MapKit

struct UserData {
    static let userId = "userId"
    static let phone = "phone"
    static let addressPrivacyChoices = "addressPrivacyChoices"
    static let firstAddressLatitude = "firstAddressLatitude"
    static let firstAddressLongitude = "firstAddressLongitude"
    static let secondAddressLatitude = "secondAddressLatitude"
    static let secondAddressLongitude = "secondAddressLongitude"
    static let firstLocationLatitude = "firstLocationLatitude"
    static let firstLocationLongitude = "firstLocationLongitude"
    static let secondLocationLatitude = "secondLocationLatitude"
    static let secondLocationLongitude = "secondLocationLongitude"
    static let thirdLocationLatitude = "thirdLocationLatitude"
    static let thirdLocationLongitude = "thirdLocationLongitude"
    static let addressNames = "addressNames"
    static let addressAliases = "addressAliases"
    static let locationNames = "locationNames"
    static let locationAliases = "locationAliases"
    static let contacts = "ontacts"
    static let name = "name"
    static let endpointArn = "endpointArn"
    static let userPictureName = "userPictureName"
}

class User: NSObject, NSCoding {
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(userId, forKey: UserData.userId)
        aCoder.encode(phone, forKey: UserData.phone)
        aCoder.encode(addressPrivacyChoices, forKey: UserData.addressPrivacyChoices)
        aCoder.encode(addresses![0].latitude, forKey: UserData.firstAddressLatitude)
        aCoder.encode(addresses![0].longitude, forKey: UserData.firstAddressLongitude)
        aCoder.encode(addresses![1].latitude, forKey: UserData.secondAddressLatitude)
        aCoder.encode(addresses![1].longitude, forKey: UserData.secondAddressLongitude)
        aCoder.encode(addressNames, forKey: UserData.addressNames)
        aCoder.encode(addressAliases, forKey: UserData.addressAliases)
        aCoder.encode(locations![0].latitude, forKey: UserData.firstLocationLatitude)
        aCoder.encode(locations![0].longitude, forKey: UserData.firstLocationLongitude)
        aCoder.encode(locations![1].latitude, forKey: UserData.secondLocationLatitude)
        aCoder.encode(locations![1].longitude, forKey: UserData.secondLocationLongitude)
        aCoder.encode(locations![2].latitude, forKey: UserData.thirdLocationLatitude)
        aCoder.encode(locations![2].longitude, forKey: UserData.thirdLocationLongitude)
        aCoder.encode(locationNames, forKey: UserData.locationNames)
        aCoder.encode(locationAliases, forKey: UserData.locationAliases)
        aCoder.encode(contacts, forKey: UserData.contacts)
        aCoder.encode(name, forKey: UserData.name)
        aCoder.encode(endpointArn, forKey: UserData.endpointArn)
        aCoder.encode(userPictureName, forKey: UserData.userPictureName)
    }
    
    required init?(coder aDecoder: NSCoder) {
        userId = aDecoder.decodeObject(forKey: UserData.userId) as? String
        phone = aDecoder.decodeObject(forKey: UserData.phone) as? String
        addressPrivacyChoices = aDecoder.decodeObject(forKey: UserData.addressPrivacyChoices) as? [Bool]
        let firstAddressLatitudeTemp = aDecoder.decodeDouble(forKey: UserData.firstAddressLatitude)
        let firstAddressLongitudeTemp = aDecoder.decodeDouble(forKey: UserData.firstAddressLongitude)
        let secondAddressLatitudeTemp = aDecoder.decodeDouble(forKey: UserData.secondAddressLatitude)
        let secondAddressLongitudeTemp = aDecoder.decodeDouble(forKey: UserData.secondAddressLongitude)
        addresses![0] = CLLocationCoordinate2D(latitude: firstAddressLatitudeTemp, longitude: firstAddressLongitudeTemp)
        addresses![1] = CLLocationCoordinate2D(latitude: secondAddressLatitudeTemp, longitude: secondAddressLongitudeTemp)
        addressNames = aDecoder.decodeObject(forKey: UserData.addressNames) as? [String]
        addressAliases = aDecoder.decodeObject(forKey: UserData.addressAliases) as? [String]
        let firstLocationLatitudeTemp = aDecoder.decodeDouble(forKey: UserData.firstLocationLatitude)
        let firstLocationLongitudeTemp = aDecoder.decodeDouble(forKey: UserData.firstLocationLongitude)
        let secondLocationLatitudeTemp = aDecoder.decodeDouble(forKey: UserData.secondLocationLatitude)
        let secondLocationLongitudeTemp = aDecoder.decodeDouble(forKey: UserData.secondLocationLongitude)
        let thirdLocationLatitudeTemp = aDecoder.decodeDouble(forKey: UserData.thirdLocationLatitude)
        let thirdLocationLongitudeTemp = aDecoder.decodeDouble(forKey: UserData.thirdLocationLongitude)
        locations![0] = CLLocationCoordinate2D(latitude: firstLocationLatitudeTemp, longitude: firstLocationLongitudeTemp)
        locations![1] = CLLocationCoordinate2D(latitude: secondLocationLatitudeTemp, longitude: secondLocationLongitudeTemp)
        locations![2] = CLLocationCoordinate2D(latitude: thirdLocationLatitudeTemp, longitude: thirdLocationLongitudeTemp)
        locationNames = aDecoder.decodeObject(forKey: UserData.locationNames) as? [String]
        locationAliases = aDecoder.decodeObject(forKey: UserData.locationAliases) as? [String]
        contacts = aDecoder.decodeObject(forKey: UserData.contacts) as? [String]
        name = aDecoder.decodeObject(forKey: UserData.name) as? String
        endpointArn = aDecoder.decodeObject(forKey: UserData.endpointArn) as? [String]
        userPictureName = aDecoder.decodeObject(forKey: UserData.userPictureName) as? String
    }

    var userId: String?
    var phone: String?
    var addressPrivacyChoices: [Bool]? = [false, false]
    var addresses: [CLLocationCoordinate2D]? = [CLLocationCoordinate2DMake(1, 2), CLLocationCoordinate2DMake(3, 4)]
    var addressNames: [String]?
    var addressAliases: [String]?
    var locations: [CLLocationCoordinate2D]? = [CLLocationCoordinate2DMake(1, 2), CLLocationCoordinate2DMake(3, 4), CLLocationCoordinate2DMake(5, 6)]
    var locationNames: [String]?
    var locationAliases: [String]?
    var contacts: [String]?
    var name: String?
    var selectedDropMethod: Int?
    var selectedAddress: CLLocationCoordinate2D?
    var selectedAddressAlias: String? = "dummyText"
    var placeToDrop: CLLocationCoordinate2D?
    var placeToDropAlias: String? = "dummyText"
    var userLocationForDrop: CLLocationCoordinate2D?
    var userLocationForDropAlias: String? = "dummyText"
    var hasBeenSelectedForDrop: Bool?
    var endpointArn: [String]? = ["dummyText"]
    var userPictureName: String? = "dummyText"
    var userPicture: UIImage?
    var userPictureUrl: URL?
    
    init(userId: String,
         phone: String,
         addressPrivacyChoices: [Bool],
         addresses: [CLLocationCoordinate2D],
         addressNames: [String],
         addressAliases: [String],
         locations: [CLLocationCoordinate2D],
         locationNames: [String],
         locationAliases: [String],
         contacts: [String],
         name: String,
         endpointArn: [String],
         userPictureName: String) {
        self.userId = userId
        self.phone = phone
        self.addressPrivacyChoices = addressPrivacyChoices
        self.addresses = addresses
        self.addressNames = addressNames
        self.addressAliases = addressAliases
        self.locations = locations
        self.locationNames = locationNames
        self.locationAliases = locationAliases
        self.contacts = contacts
        self.name = name
        self.selectedDropMethod = nil
        self.selectedAddress = nil
        self.selectedAddressAlias = nil
        self.placeToDrop = nil
        self.placeToDropAlias = nil
        self.userLocationForDrop = nil
        self.userLocationForDropAlias = nil
        self.hasBeenSelectedForDrop = nil
        self.endpointArn = endpointArn
        self.userPictureName = userPictureName
    }
}
