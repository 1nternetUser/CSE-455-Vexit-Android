//
//  Drops.swift
//  MySampleApp
//
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.19
//

import Foundation
import UIKit
import AWSDynamoDB

@objcMembers

class Drops: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    @objc var _userId: String?
    @objc var _identifier: String?
    @objc var _centerCoordinateLatitude: NSNumber?
    @objc var _centerCoordinateLongitude: NSNumber?
    @objc var _dropRadius: NSNumber?
    @objc var _droppedMessage: String?
    @objc var _recipientUserId: String?
    
    class func dynamoDBTableName() -> String {

        return "vextitdrop-mobilehub-1033980428-Drops"
    }
    
    class func hashKeyAttribute() -> String {

        return "_userId"
    }
    
    class func rangeKeyAttribute() -> String {

        return "_identifier"
    }
    
    override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
        return [
               "_userId" : "userId",
               "_identifier" : "identifier",
               "_centerCoordinateLatitude" : "centerCoordinateLatitude",
               "_centerCoordinateLongitude" : "centerCoordinateLongitude",
               "_dropRadius" : "dropRadius",
               "_droppedMessage" : "droppedMessage",
               "_recipientUserId" : "recipientUserId",
        ]
    }
}
