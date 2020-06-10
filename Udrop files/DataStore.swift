//
//  DataStore.swift
//  DropIt


import Foundation
import MapKit

class DataStore {
    
    static let sharedInstance = DataStore()
    
    var dropsForOthers: [Drop] = []
    var dropsFromOthers: [Drop] = []
    var selectedContactInDropMap: Int?
    var selectedAddressInSettings: Int?
    var selectedLocationInSettings: Int?
    var selectedCellInViewDrops: Int?
    var currentlySettingAddresses: Bool?
    var contactsList: [User] = []
    var dropRecipients: [User] = []
    var currentUser: User?
    var allUsers: [BasicUser] = []
    var usersToAddToContacts: [BasicUser] = []
    var imageToDropURL: URL?
    var dropType: Int?
    var tempDrop: Drop?
    var allDropsForViewing: [Drop]?
}
