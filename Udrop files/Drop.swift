//
//  Drop.swift
//  regionTest


import Foundation
import UIKit
import AVKit
import MapKit
import CoreLocation

struct DropData {
    static let sender = "sender"
    static let recipient = "recipient"
    static let longitude = "longitude"
    static let latitude = "latitude"
    static let radius = "radius"
    static let date = "date"
    static let message = "message"
    static let droppedContent = "droppedContent"
    static let name = "name"
    static let isPrivate = "isPrivate"
    static let received = "received"
    static let isPictureOrVideo = "isPictureOrVideo"
    static let content = "content"
}

class Drop: NSObject, NSCoding {
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(sender, forKey: DropData.sender)
        aCoder.encode(recipient, forKey: DropData.recipient)
        aCoder.encode(centerCoordinate.latitude, forKey: DropData.latitude)
        aCoder.encode(centerCoordinate.longitude, forKey: DropData.longitude)
        aCoder.encode(dropRadius, forKey: DropData.radius)
        aCoder.encode(creationDate, forKey: DropData.date)
        aCoder.encode(droppedContent, forKey: DropData.droppedContent)
        aCoder.encode(droppedMessage, forKey: DropData.message)
        aCoder.encode(dropName, forKey: DropData.name)
        aCoder.encode(hasBeenReceived, forKey: DropData.received)
        aCoder.encode(isPrivate, forKey: DropData.isPrivate)
        aCoder.encode(isPictureOrVideo, forKey: DropData.isPictureOrVideo)
        aCoder.encode(content, forKey: DropData.content)
    }
    
    required init?(coder aDecoder: NSCoder) {
        sender = aDecoder.decodeObject(forKey: DropData.sender) as! String
        recipient = aDecoder.decodeObject(forKey: DropData.recipient) as! String
        let latitude = aDecoder.decodeDouble(forKey: DropData.latitude)
        let longitude = aDecoder.decodeDouble(forKey: DropData.longitude)
        centerCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        dropRadius = aDecoder.decodeDouble(forKey: DropData.radius)
        creationDate = aDecoder.decodeObject(forKey: DropData.date) as! NSNumber
        droppedMessage = aDecoder.decodeObject(forKey: DropData.message) as! String
        droppedContent = aDecoder.decodeObject(forKey: DropData.droppedContent) as! String
        dropName = aDecoder.decodeObject(forKey: DropData.name) as! String
        hasBeenReceived = aDecoder.decodeBool(forKey: DropData.received)
        isPrivate = aDecoder.decodeBool(forKey: DropData.isPrivate)
        isPictureOrVideo = aDecoder.decodeBool(forKey: DropData.isPictureOrVideo)
        content = aDecoder.decodeObject(forKey: DropData.content) as! URL
    }
    
    var sender: String = "dummyText"
    var recipient: String = "dummyText"
    var centerCoordinate: CLLocationCoordinate2D
    var dropRadius: CLLocationDistance
    var creationDate: NSNumber
    var dateForDisplay: String?
    var droppedMessage: String = "dummyText"
    var droppedContent: String = "dummyText"
    var dropName: String = "dummyText"
    var hasBeenReceived: Bool = false
    var isPrivate: Bool = false
    var isPictureOrVideo: Bool = false
    var content: URL = URL.init(string: "dummyText")!
    var pictureForDisplay: UIImage?
    var videoForDisplay: AVPlayer?
    var contentType: String?
    
    init(sender: String, recipient: String, centerCoordinate: CLLocationCoordinate2D, dropRadius: CLLocationDistance, creationDate: NSNumber, droppedMessage: String, droppedContent: String, dropName: String, hasBeenReceived: Bool, isPrivate: Bool, isPictureOrVideo: Bool, content: URL) {
        self.sender = sender
        self.recipient = recipient
        self.centerCoordinate = centerCoordinate
        self.dropRadius = dropRadius
        self.creationDate = creationDate
        self.droppedMessage = droppedMessage
        self.droppedContent = droppedContent
        self.dropName = dropName
        self.hasBeenReceived = hasBeenReceived
        self.isPrivate = isPrivate
        self.isPictureOrVideo = isPictureOrVideo
        self.content = content
    }
}
