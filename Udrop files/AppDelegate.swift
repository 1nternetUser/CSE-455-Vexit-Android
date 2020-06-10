//
//  AppDelegate.swift
//  VEXTit Drop

import MapKit
import UserNotifications
import Dispatch
import CoreLocation
import UIKit
import AVKit
import AssetsLibrary
import Photos
import AWSMobileClient
import AWSCore
import AWSS3
import AWSCognito
import AWSDynamoDB
import AWSCognitoIdentityProvider
import AWSPinpoint
import AWSUserPoolsSignIn
import AWSSNS
import AWSAuthCore

struct PreferencesKeys {
    static let storedSentDrops = "storedSentDrops"
    static let storedReceivedDrops = "storedReceivedDrops"
    static let storedUser = "storedUser"
    static let storedContacts = "storedContacts"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITableViewDelegate {
    
    static let sharedInstance = AppDelegate()

    var window: UIWindow?
    let locationManager = CLLocationManager()
    let center = UNUserNotificationCenter.current()
    let content = UNMutableNotificationContent()
    var regions: [CLRegion] = []
    var pinpoint: AWSPinpoint?
    var convertedUserId: String?
    var convertedUsername: String?
    static let remoteNotificationKey = "RemoteNotification"
    let platformApplicationArn: String = "arn:aws:sns:us-west-2:793118309924:app/APNS/VEXTit"
    let bucketName = "vextitdrop-hosting-mobilehub-744279733"
    var isInitialized: Bool = false
    var firstLaunch: Bool?

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return AWSMobileClient.sharedInstance().interceptApplication(
        application, open: url,
        sourceApplication: sourceApplication,
        annotation: annotation)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        firstLaunch = UserDefaults.standard.bool(forKey: "firstLaunch")
        
        pinpoint = AWSPinpoint(configuration: AWSPinpointConfiguration.defaultPinpointConfiguration(launchOptions: launchOptions))
        if (!isInitialized) {
            AWSSignInManager.sharedInstance().resumeSession(completionHandler: { (result: Any?, error: Error?) in
            })
            isInitialized = true
        }
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USWest2,
                                                                identityPoolId:"us-west-2:fffb9bbe-d007-4fd0-9afd-1348e5831908")
        let configuration = AWSServiceConfiguration(region:.USWest2, credentialsProvider:credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        let syncClient = AWSCognito.default()
        
        // Create a record in a dataset and synchronize with the server
        let dataset = syncClient.openOrCreateDataset("myDataset")
        dataset.setString("myValue", forKey:"myKey")
        dataset.synchronize().continueWith {(task: AWSTask!) -> AnyObject? in
            // Your handler code here
            return nil
            
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) { [weak self] in
            self?.prepareLocationAndNotifications()
        }
        
        return AWSMobileClient.sharedInstance().interceptApplication(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        if firstLaunch! {
            print("Not first launch.")
            print("CALLED DIDREGISTERFORREMOTENOTIFICATIONSWITHDEVICETOKEN")
            let tokenString = deviceToken.reduce("", {$0 + String(format: "%02X",    $1)})
            let sns = AWSSNS.default()
            let request = AWSSNSCreatePlatformEndpointInput()
            request?.token = tokenString
            request?.platformApplicationArn = platformApplicationArn
            sns.createPlatformEndpoint(request!).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask!) -> AnyObject? in
                if task.error != nil {
                    print("Error, SNS: \(String(describing: task.error))")
                } else {
                    let createEndpointResponse = task.result! as AWSSNSCreateEndpointResponse
                    if let endpointArnForSNS = createEndpointResponse.endpointArn {
                        print("endpointArn: \(endpointArnForSNS)")
                        self.downloadUser(endpointArn: endpointArnForSNS)
                        self.loadUserContacts()
                        self.loadDrops()
                        self.getAllUsers()
                        UserDefaults.standard.set(endpointArnForSNS, forKey: "endpointArnForSNS")
                    }
                }
                return nil
            })
            pinpoint!.notificationManager.interceptDidRegisterForRemoteNotifications(withDeviceToken: deviceToken)
            NotificationCenter.default.post(name: Notification.Name(rawValue: AppDelegate.remoteNotificationKey), object: deviceToken)
        } else {
            UserDefaults.standard.set(true, forKey: "firstLaunch")
            guard let snsKey = UserDefaults.standard.object(forKey: "endpointArnForSNS") else {
                print("CALLED DIDREGISTERFORREMOTENOTIFICATIONSWITHDEVICETOKEN")
                let tokenString = deviceToken.reduce("", {$0 + String(format: "%02X",    $1)})
                let sns = AWSSNS.default()
                let request = AWSSNSCreatePlatformEndpointInput()
                request?.token = tokenString
                request?.platformApplicationArn = platformApplicationArn
                sns.createPlatformEndpoint(request!).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask!) -> AnyObject? in
                    if task.error != nil {
                        print("Error, SNS: \(String(describing: task.error))")
                    } else {
                        let createEndpointResponse = task.result! as AWSSNSCreateEndpointResponse
                        if let endpointArnForSNS = createEndpointResponse.endpointArn {
                            print("endpointArn: \(endpointArnForSNS)")
                            self.downloadUser(endpointArn: endpointArnForSNS)
                            self.getAllUsers()
                            UserDefaults.standard.set(endpointArnForSNS, forKey: "endpointArnForSNS")
                        }
                    }
                    return nil
                })
                pinpoint!.notificationManager.interceptDidRegisterForRemoteNotifications(withDeviceToken: deviceToken)
                NotificationCenter.default.post(name: Notification.Name(rawValue: AppDelegate.remoteNotificationKey), object: deviceToken)
                return
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        downloadLatestReceivedDrop()
        completionHandler(.newData)
        pinpoint!.notificationManager.interceptDidReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//        saveDrops()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//        saveDrops()
    }
    
    func saveDrops() {
        UserDefaults.standard.removeObject(forKey: "storedSentDrops")
        var sentDrops: [Data] = []
        for drop in DataStore.sharedInstance.dropsForOthers {
            let item = NSKeyedArchiver.archivedData(withRootObject: drop)
            sentDrops.append(item)
        }
        UserDefaults.standard.set(sentDrops, forKey: PreferencesKeys.storedSentDrops)
        
        UserDefaults.standard.removeObject(forKey: "storedReceivedDrops")
        var receivedDrops: [Data] = []
        for drop in DataStore.sharedInstance.dropsFromOthers {
            let item = NSKeyedArchiver.archivedData(withRootObject: drop)
            receivedDrops.append(item)
        }
        UserDefaults.standard.set(receivedDrops, forKey: PreferencesKeys.storedReceivedDrops)
    }
    
    func loadDrops() {
        print("called loadDrops")
        DataStore.sharedInstance.dropsFromOthers.removeAll()
        DataStore.sharedInstance.dropsForOthers.removeAll()
        
        guard let storedSentData = UserDefaults.standard.array(forKey: PreferencesKeys.storedSentDrops) else { return }
        for storedDatum in storedSentData {
            guard let drop = NSKeyedUnarchiver.unarchiveObject(with: storedDatum as! Data) as? Drop else { continue }
            DataStore.sharedInstance.dropsForOthers.append(drop)
            print("Appended a drop to dropsForOthers in loadDrops.")
        }
        DataStore.sharedInstance.dropsForOthers.sort(by: { $0.creationDate.intValue < $1.creationDate.intValue })
        
        guard let storedReceivedData = UserDefaults.standard.array(forKey: PreferencesKeys.storedReceivedDrops) else { return }
        for storedDatum in storedReceivedData {
            guard let drop = NSKeyedUnarchiver.unarchiveObject(with: storedDatum as! Data) as? Drop else { continue }
            if drop.isPictureOrVideo == true {
                let loadingFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let imageFileURL = loadingFileURL.appendingPathComponent(drop.droppedContent)
                drop.content = imageFileURL
            }
            DataStore.sharedInstance.dropsFromOthers.append(drop)
        }
        DataStore.sharedInstance.dropsFromOthers.sort(by: { $0.creationDate.intValue < $1.creationDate.intValue })
        
        for drop in DataStore.sharedInstance.dropsFromOthers {
            print(drop.creationDate)
        }
    }
    
    func uploadContent(with resource: String, type: String) {
        let key = "\(resource).\(type)"
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()!
        uploadRequest.bucket = bucketName
        uploadRequest.key = key
        uploadRequest.body = DataStore.sharedInstance.imageToDropURL!
        uploadRequest.acl = .publicReadWrite
        
        let transferManager = AWSS3TransferManager.default()
        transferManager.upload(uploadRequest).continueWith(executor: AWSExecutor.mainThread()) { (task) -> Any? in
            if let error = task.error {
                print("Uh-Oh!: \(error)")
            }
            if task.result != nil {
                print("Uploaded \(key)")
            }
            return nil
        }
    }
    
    func downloadContent(with resource: String, drop: Drop, isSent: Bool) {
        
        let downloadingFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageFileURL = downloadingFileURL.appendingPathComponent(resource)
        
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        
        downloadRequest?.bucket = bucketName
        downloadRequest?.key = resource
        downloadRequest?.downloadingFileURL = imageFileURL
        
        let transferManager = AWSS3TransferManager.default()
        transferManager.download(downloadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
            
            if let error = task.error as? NSError {
                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                    switch code {
                    case .cancelled, .paused:
                        break
                    default:
                        print("Error downloading: \(downloadRequest?.key) Error: \(error)")
                    }
                } else {
                    print("Error downloading: \(downloadRequest?.key) Error: \(error)")
                }
                return nil
            }
            drop.content = imageFileURL
            if isSent == true {
                DataStore.sharedInstance.dropsForOthers.append(drop)
                print("Appended a drop to dropsForOthers in downloadContent.")
            } else if isSent == false {
                DataStore.sharedInstance.dropsFromOthers.append(drop)
            }
            
            self.saveDrops()
            let fileExtensionSplit = resource.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: true)
            let fileExtension = fileExtensionSplit.last
            if let downloadedImage = NSData(contentsOf: drop.content) {
                if drop.sender != DataStore.sharedInstance.currentUser?.userId {
                    if fileExtension == "png" {
                        let image = UIImage(data: downloadedImage as Data)
                        UIImageWriteToSavedPhotosAlbum(image!, { (path:NSURL!, error:NSError!) -> Void in
                            print("The image was saved at: \(path)")
                        }, nil, nil)
                        // print(image?.size)
                    } else if fileExtension == "mp4" {
                        let assetsLibrary: ALAssetsLibrary = ALAssetsLibrary()
                        assetsLibrary.writeVideoAtPath(toSavedPhotosAlbum: drop.content, completionBlock: nil)
                    }
                }
            }
            return nil
        })
    }
    
    func downloadContactPicture(with resource: String, basicUser: BasicUser) {
        
        let downloadingFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageFileURL = downloadingFileURL.appendingPathComponent(resource)
        
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        
        downloadRequest?.bucket = bucketName
        downloadRequest?.key = resource
        downloadRequest?.downloadingFileURL = imageFileURL
        
        
        
        let transferManager = AWSS3TransferManager.default()
        transferManager.download(downloadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
            
            if let error = task.error as? NSError {
                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                    switch code {
                    case .cancelled, .paused:
                        break
                    default:
                        print("Error downloading: \(downloadRequest?.key) Error: \(error)")
                    }
                } else {
                    print("Error downloading: \(downloadRequest?.key) Error: \(error)")
                }
                return nil
            }
            basicUser.userPictureURL = imageFileURL

            if let downloadedImage = NSData(contentsOf: basicUser.userPictureURL!) {
                let image = UIImage(data: downloadedImage as Data)
                basicUser.userPicture = image
                print(image.debugDescription)
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .reload, object: nil)
            }
            return nil
        })
    }
    
    func downloadCurrentUserPicture(with resource: String, currentUser: User) {
        let downloadingFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageFileURL = downloadingFileURL.appendingPathComponent(resource)
        
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        
        downloadRequest?.bucket = bucketName
        downloadRequest?.key = resource
        downloadRequest?.downloadingFileURL = imageFileURL
        
        
        
        let transferManager = AWSS3TransferManager.default()
        transferManager.download(downloadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
            
            if let error = task.error as? NSError {
                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                    switch code {
                    case .cancelled, .paused:
                        break
                    default:
                        print("Big Ol' Error downloading: \(downloadRequest?.key) Error: \(error)")
                    }
                } else {
                    print("Big Ol' Error downloading: \(downloadRequest?.key) Error: \(error)")
                }
                return nil
            }
            print("Download complete for: \(downloadRequest?.key)")
            
            currentUser.userPictureUrl = imageFileURL
            currentUser.userPictureName = resource
            print("The resource name is: \(resource)")
            if let downloadedImage = NSData(contentsOf: imageFileURL) {
                print("Recovered User's Picture")
                let image = UIImage(data: downloadedImage as Data)
                currentUser.userPicture = image
                print(image.debugDescription)
                DataStore.sharedInstance.currentUser = currentUser
            }
            return nil
        })
    }

    func uploadNewestDrop() {
        // This code saves the user's Drops to the AWS DynamoDB
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        let newestDrop: DropStorageTable = DropStorageTable()
        
        var centerCoordinateTemp: [NSNumber]?
        
        newestDrop._userId = AWSIdentityManager.default().identityId
        newestDrop._recipientUserId = DataStore.sharedInstance.dropsForOthers.last?.recipient as String?
        
        centerCoordinateTemp = [(DataStore.sharedInstance.dropsForOthers.last?.centerCoordinate.latitude as NSNumber?)!,
                                (DataStore.sharedInstance.dropsForOthers.last?.centerCoordinate.longitude as NSNumber?)!]
        newestDrop._centerCoordinate = centerCoordinateTemp
        
        newestDrop._dropRadius = DataStore.sharedInstance.dropsForOthers.last?.dropRadius as NSNumber?
        newestDrop._droppedContent = DataStore.sharedInstance.dropsForOthers.last?.droppedContent as String?
        newestDrop._droppedMessage = DataStore.sharedInstance.dropsForOthers.last?.droppedMessage as String?
        newestDrop._dropName = DataStore.sharedInstance.dropsForOthers.last?.dropName as String?
        newestDrop._creationDate = DataStore.sharedInstance.dropsForOthers.last?.creationDate as NSNumber?
        newestDrop._hasBeenReceived = DataStore.sharedInstance.dropsForOthers.last?.hasBeenReceived as NSNumber?
        newestDrop._isPrivate = DataStore.sharedInstance.dropsForOthers.last?.isPrivate as NSNumber?
        newestDrop._isPictureOrVideo = DataStore.sharedInstance.dropsForOthers.last?.isPictureOrVideo as NSNumber?
        
        dynamoDbObjectMapper.save(newestDrop, completionHandler: {
            (error: Error?) -> Void in
            if let error = error {
                 print("Amazon DynamoDB Save Error: \(error)")
                return
            }
             print("The newest drop was saved.")
        })
    }
    
    func downloadAllDropsInvolvingUser(user: String) {
        downloadReceivedDropsFromUser(user: user)
        downloadSentDropsForUser(user: user)
    }
    
    func downloadReceivedDropsFromUser(user: String) {
        print("Currently downloading recieved drops from \(user).")
        // 1) Configure the query
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.keyConditionExpression = "#recipientUserId = :recipientUserId AND #creationDate > :creationDate"
        
        queryExpression.indexName = "recipientUserId-creationDate"
        
        if DataStore.sharedInstance.dropsForOthers.count == 0 {
            queryExpression.expressionAttributeNames = [
                "#recipientUserId": "recipientUserId",
                "#creationDate": "creationDate"
            ]
            queryExpression.expressionAttributeValues = [
                ":recipientUserId": DataStore.sharedInstance.currentUser?.userId,
                ":creationDate": 0
            ]
        } else {
            queryExpression.expressionAttributeNames = [
                "#recipientUserId": "recipientUserId",
                "#creationDate": "creationDate"
            ]
            queryExpression.expressionAttributeValues = [
                ":recipientUserId": DataStore.sharedInstance.currentUser?.userId,
                ":creationDate": DataStore.sharedInstance.dropsFromOthers.last?.creationDate
            ]
            print("Last dropForOthers creationDate from DataStore is: \(DataStore.sharedInstance.dropsFromOthers.last?.creationDate).")
        }
        
        // 2) Make the query
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDbObjectMapper.query(DropStorageTable.self, expression: queryExpression) { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if error != nil {
                print("The request failed. Error: \(String(describing: error))")
            }
            if output != nil {
                for drop in output!.items {
                    let dropItem = drop as? DropStorageTable
                    if /*dropItem?._hasBeenReceived == false &&*/ dropItem?._userId == user {
                        let currentRetrievedDrop: Drop = Drop(sender: dropItem!._userId!,
                                                              recipient: dropItem!._recipientUserId!,
                                                              centerCoordinate: CLLocationCoordinate2DMake(dropItem!._centerCoordinate![0] as! CLLocationDegrees,  dropItem!._centerCoordinate![1] as! CLLocationDegrees),
                                                              dropRadius: dropItem!._dropRadius as! CLLocationDistance,
                                                              creationDate: dropItem!._creationDate!,
                                                              droppedMessage: dropItem!._droppedMessage!,
                                                              droppedContent: dropItem!._droppedContent!,
                                                              dropName: dropItem!._dropName!,
                                                              hasBeenReceived: (dropItem?._hasBeenReceived)! as! Bool,
                                                              isPrivate: (dropItem?._isPrivate)! as! Bool,
                                                              isPictureOrVideo: (dropItem?._isPictureOrVideo)! as! Bool,
                                                              content: URL(string: "dummyText")!)
                        print("creationDate of currently downloading received drop is: \(currentRetrievedDrop.creationDate)")
                        if dropItem?._isPictureOrVideo == true {
                            DataStore.sharedInstance.tempDrop = currentRetrievedDrop
                            self.downloadContent(with: (dropItem?._droppedContent)!, drop: currentRetrievedDrop, isSent: false)
                        } else if dropItem?._isPictureOrVideo == false {
                            DataStore.sharedInstance.dropsFromOthers.append(currentRetrievedDrop)
                            self.saveDrops()
                        }
                        print("Downloaded and saved a drop received from \(user).")
                    }
                }
            }
        }
    }
    
    func downloadSentDropsForUser(user: String) {
        print("Currently downloading sent drops for \(user).")
        // 1) Configure the query
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.keyConditionExpression = "#userId = :userId AND #creationDate > :creationDate"
        
        if DataStore.sharedInstance.dropsFromOthers.count == 0 {
            queryExpression.expressionAttributeNames = [
                "#userId": "userId",
                "#creationDate": "creationDate"
            ]
            queryExpression.expressionAttributeValues = [
                ":userId": DataStore.sharedInstance.currentUser?.userId,
                ":creationDate": 0
            ]
        } else {
            queryExpression.expressionAttributeNames = [
                "#userId": "userId",
                "#creationDate": "creationDate"
            ]
            queryExpression.expressionAttributeValues = [
                ":userId": DataStore.sharedInstance.currentUser?.userId,
                ":creationDate": DataStore.sharedInstance.dropsForOthers.last?.creationDate
            ]
            print("Last dropFromOthers creationDate from DataStore is: \(DataStore.sharedInstance.dropsForOthers.last?.creationDate).")
        }
        
        // 2) Make the query
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDbObjectMapper.query(DropStorageTable.self, expression: queryExpression) { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if error != nil {
                print("The request failed. Error: \(String(describing: error))")
            }
            if output != nil {
                for drop in output!.items {
                    let dropItem = drop as? DropStorageTable
                    if /*dropItem?._hasBeenReceived == false &&*/ dropItem?._recipientUserId == user {
                        let currentRetrievedDrop: Drop = Drop(sender: dropItem!._userId!,
                                                              recipient: dropItem!._recipientUserId!,
                                                              centerCoordinate: CLLocationCoordinate2DMake(dropItem!._centerCoordinate![0] as! CLLocationDegrees,  dropItem!._centerCoordinate![1] as! CLLocationDegrees),
                                                              dropRadius: dropItem!._dropRadius as! CLLocationDistance,
                                                              creationDate: dropItem!._creationDate!,
                                                              droppedMessage: dropItem!._droppedMessage!,
                                                              droppedContent: dropItem!._droppedContent!,
                                                              dropName: dropItem!._dropName!,
                                                              hasBeenReceived: (dropItem?._hasBeenReceived)! as! Bool,
                                                              isPrivate: (dropItem?._isPrivate)! as! Bool,
                                                              isPictureOrVideo: (dropItem?._isPictureOrVideo)! as! Bool,
                                                              content: URL(string: "dummyText")!)
                        print("creationDate of currently downloading sent drop is: \(currentRetrievedDrop.creationDate)")
                        if dropItem?._isPictureOrVideo == true {
                            DataStore.sharedInstance.tempDrop = currentRetrievedDrop
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
                                self.downloadContent(with: (dropItem?._droppedContent)!, drop: currentRetrievedDrop, isSent: true)
                            })
                        } else if dropItem?._isPictureOrVideo == false {
                            DataStore.sharedInstance.dropsForOthers.append(currentRetrievedDrop)
                            print("Appended a drop to dropsForOthers in downloadSentDropsForUser.")
                            self.saveDrops()
                        }
                        print("Downloaded and saved a drop sent for \(user).")
                    }
                }
            }
        }
    }
    
    func downloadLatestReceivedDrop() {
        
        // 1) Configure the query
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.keyConditionExpression = "#recipientUserId = :recipientUserId AND #creationDate > :creationDate"
        
        queryExpression.indexName = "recipientUserId-creationDate"
        
        if DataStore.sharedInstance.dropsFromOthers.count == 0 {
            queryExpression.expressionAttributeNames = [
                "#recipientUserId": "recipientUserId",
                "#creationDate": "creationDate"
            ]
            queryExpression.expressionAttributeValues = [
                ":recipientUserId": DataStore.sharedInstance.currentUser?.userId,
                ":creationDate": 0
            ]
        } else {
            queryExpression.expressionAttributeNames = [
                "#recipientUserId": "recipientUserId",
                "#creationDate": "creationDate"
            ]
            queryExpression.expressionAttributeValues = [
                ":recipientUserId": DataStore.sharedInstance.currentUser?.userId,
                ":creationDate": DataStore.sharedInstance.dropsFromOthers.last?.creationDate
            ]
        }
        
        // 2) Make the query
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDbObjectMapper.query(DropStorageTable.self, expression: queryExpression) { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if error != nil {
                print("The request failed. Error: \(String(describing: error))")
            }
            if output != nil {
                for drop in output!.items {
                    let dropItem = drop as? DropStorageTable
                    if dropItem?._hasBeenReceived == false {
                        let currentRetrievedDrop: Drop = Drop(sender: dropItem!._userId!,
                                                              recipient: dropItem!._recipientUserId!,
                                                              centerCoordinate: CLLocationCoordinate2DMake(dropItem!._centerCoordinate![0] as! CLLocationDegrees,  dropItem!._centerCoordinate![1] as! CLLocationDegrees),
                                                              dropRadius: dropItem!._dropRadius as! CLLocationDistance,
                                                              creationDate: dropItem!._creationDate!,
                                                              droppedMessage: dropItem!._droppedMessage!,
                                                              droppedContent: dropItem!._droppedContent!,
                                                              dropName: dropItem!._dropName!,
                                                              hasBeenReceived: (dropItem?._hasBeenReceived)! as! Bool,
                                                              isPrivate: (dropItem?._isPrivate)! as! Bool,
                                                              isPictureOrVideo: (dropItem?._isPictureOrVideo)! as! Bool,
                                                              content: URL(string: "dummyText")!)
                        if dropItem?._isPictureOrVideo == true {
                            DataStore.sharedInstance.tempDrop = currentRetrievedDrop
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
                                self.downloadContent(with: (dropItem?._droppedContent)!, drop: currentRetrievedDrop, isSent: false)
                            })
                        } else if dropItem?._isPictureOrVideo == false {
                            DataStore.sharedInstance.dropsFromOthers.append(currentRetrievedDrop)
                            self.saveDrops()
                        }
                        print("Downloaded and saved a drop.")
                    }
                }
            }
        }
    }
    
    func updateDrop(drop: Drop) {
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        var centerCoordinateTemp: [NSNumber]?
        
        let updatedDrop: DropStorageTable = DropStorageTable();

        updatedDrop._userId = AWSIdentityManager.default().identityId
        updatedDrop._recipientUserId = drop.recipient as String?
        centerCoordinateTemp = [(drop.centerCoordinate.latitude as NSNumber?)!,
                                (drop.centerCoordinate.longitude as NSNumber?)!]
        updatedDrop._centerCoordinate = centerCoordinateTemp
        updatedDrop._dropRadius = drop.dropRadius as NSNumber?
        updatedDrop._droppedMessage = drop.droppedMessage as String?
        updatedDrop._droppedContent = drop.droppedContent as String?
        updatedDrop._dropName = drop.dropName as String?
        updatedDrop._creationDate = drop.creationDate as NSNumber?
        updatedDrop._hasBeenReceived = true
        updatedDrop._isPrivate = drop.isPrivate as NSNumber?
        updatedDrop._isPictureOrVideo = drop.isPictureOrVideo as NSNumber?
        
        dynamoDbObjectMapper.save(updatedDrop, completionHandler: {(error: Error?) -> Void in
            if let error = error {
                print(" Amazon DynamoDB Save Error: \(error)")
                return
            }
             print("A drop was updated.")
        })
    }
    
    func saveUserContacts() {
        UserDefaults.standard.removeObject(forKey: "storedContacts")
        var contacts: [Data] = []
        for contact in DataStore.sharedInstance.contactsList {
            let item = NSKeyedArchiver.archivedData(withRootObject: contact)
            contacts.append(item)
        }
        UserDefaults.standard.set(contacts, forKey: PreferencesKeys.storedContacts)
    }
    
    func loadUserContacts() {
        guard let storedContactData = UserDefaults.standard.array(forKey: PreferencesKeys.storedContacts) else { return }
        for storedDatum in storedContactData {
            guard let contact = NSKeyedUnarchiver.unarchiveObject(with: storedDatum as! Data) as? User else { continue }
            DataStore.sharedInstance.contactsList.append(contact)
        }
    }
    
    func downloadContacts() {
        
        DataStore.sharedInstance.contactsList.removeAll()
        
        // 1) Configure the query
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.keyConditionExpression = "#userId = :userId AND #phone = :phone"
        
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
            "#phone": "phone",
        ]
        
        for contact in (DataStore.sharedInstance.currentUser?.contacts)! {
        
            queryExpression.expressionAttributeValues = [
                ":phone": "12345678910",
                ":userId": contact
            ]
            
            // 2) Make the query
            
            let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
            
            dynamoDbObjectMapper.query(UsersTable.self, expression: queryExpression) { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
                if error != nil {
                    print("The request for getAllUsers failed. Error: \(String(describing: error))")
                }
                if output != nil {
                    for user in output!.items {
                        let userItem = user as? UsersTable
                        let currentRetrievedContact: User = User(userId: (userItem?._userId)!,
                                                                 phone: (userItem?._phone)!,
                                                                 addressPrivacyChoices: (userItem?._addressPrivacyChoices)! as! [Bool],
                                                                 addresses: [CLLocationCoordinate2DMake(userItem?._firstAddressCoordinate![0] as! CLLocationDegrees,
                                                                                                        userItem?._firstAddressCoordinate![1] as! CLLocationDegrees),
                                                                             CLLocationCoordinate2DMake(userItem?._secondAddressCoordinate![0] as! CLLocationDegrees,
                                                                                                        userItem?._secondAddressCoordinate![1] as! CLLocationDegrees)],
                                                                 addressNames: ["dummyText"],
                                                                 addressAliases: (userItem?._addressAliases)!,
                                                                 locations: [CLLocationCoordinate2DMake(0,
                                                                                                        0),
                                                                             CLLocationCoordinate2DMake(0,
                                                                                                        0),
                                                                             CLLocationCoordinate2DMake(0,
                                                                                                        0)],
                                                                 locationNames: ["dummyText"],
                                                                 locationAliases: ["dummyText"],
                                                                 contacts: (userItem?._contacts)!,
                                                                 name: (userItem?._name)!,
                                                                 endpointArn: (userItem?._endpointArn)!,
                                                                 userPictureName: (userItem?._userPictureName)!)
                        DataStore.sharedInstance.contactsList.append(currentRetrievedContact)
                        if self.firstLaunch! == false {
                           self.downloadAllDropsInvolvingUser(user: currentRetrievedContact.userId!)
                        }
                    }
                }
                self.saveUserContacts()
            }
        }
    }
    
    func downloadUser(endpointArn: String) {
        
        var endpointArnArray: [String] = []
        endpointArnArray.append(endpointArn)
        
        // 1) Configure the query
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = "name-phone"
        queryExpression.keyConditionExpression = "#name = :name AND #phone = :phone"
        
        queryExpression.expressionAttributeNames = [
            "#name": "name",
            "#phone": "phone",
        ]
        
        queryExpression.expressionAttributeValues = [
            ":phone": "12345678910",
            ":name": AWSCognitoUserPoolsSignInProvider.sharedInstance().getUserPool().currentUser()?.username
        ]
        
        // 2) Make the query
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDbObjectMapper.query(UsersTable.self, expression: queryExpression) { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if error != nil {
                print("The request for getAllUsers failed. Error: \(String(describing: error))")
            }
            else if output != nil {
                self.createNewUser(endpointArn: endpointArn)
                for user in output!.items {
                    let userItem = user as? UsersTable
                    if userItem?._addressNames != nil && userItem?._contacts != nil {
                        let currentRetrievedUser: User = User(userId: (userItem?._userId)!,
                                                                 phone: (userItem?._phone)!,
                                                                 addressPrivacyChoices: (userItem?._addressPrivacyChoices)! as! [Bool],
                                                                 addresses: [CLLocationCoordinate2DMake(userItem?._firstAddressCoordinate![0] as! CLLocationDegrees,
                                                                                                        userItem?._firstAddressCoordinate![1] as! CLLocationDegrees),
                                                                             CLLocationCoordinate2DMake(userItem?._secondAddressCoordinate![0] as! CLLocationDegrees,
                                                                                                        userItem?._secondAddressCoordinate![1] as! CLLocationDegrees)],
                                                                 addressNames: (userItem?._addressNames)!,
                                                                 addressAliases: (userItem?._addressAliases)!,
                                                                 locations: [CLLocationCoordinate2DMake(userItem?._firstLocationCoordinate![0] as! CLLocationDegrees,
                                                                                                        userItem?._firstLocationCoordinate![1] as! CLLocationDegrees),
                                                                             CLLocationCoordinate2DMake(userItem?._secondLocationCoordinate![0] as! CLLocationDegrees,
                                                                                                        userItem?._secondLocationCoordinate![1] as! CLLocationDegrees),
                                                                             CLLocationCoordinate2DMake(userItem?._thirdLocationCoordinate![0] as! CLLocationDegrees,
                                                                                                        userItem?._thirdLocationCoordinate![1] as! CLLocationDegrees)],
                                                                 locationNames: (userItem?._locationNames)!,
                                                                 locationAliases: (userItem?._locationAliases)!,
                                                                 contacts: (userItem?._contacts)!,
                                                                 name: (userItem?._name)!,
                                                                 endpointArn: endpointArnArray,
                                                                 userPictureName: (userItem?._userPictureName)!)
                        DataStore.sharedInstance.currentUser = currentRetrievedUser
                        self.downloadCurrentUserPicture(with: currentRetrievedUser.userPictureName!, currentUser: DataStore.sharedInstance.currentUser!)
                        self.saveCurrentUser()
                        self.uploadCurrentUser(endpointArn: endpointArn)
                        self.downloadContacts()
                    }
                }
            }
        }
    }
    
    func addSelectedContacts(usersToAdd: [BasicUser]) {
        print("Add Called")
        // 1) Configure the query
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = "name-phone"
        queryExpression.keyConditionExpression = "#name = :name AND #phone = :phone"

        queryExpression.expressionAttributeNames = [
                        "#name": "name",
                        "#phone": "phone",
        ]
        
        for selectedUser in usersToAdd {
            queryExpression.expressionAttributeValues = [
                ":phone": "12345678910",
                ":name": selectedUser.name!
            ]
            
            // 2) Make the query
            
            let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
            
            dynamoDbObjectMapper.query(UsersTable.self, expression: queryExpression) { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
                if error != nil {
                    print("The request for getAllUsers failed. Error: \(String(describing: error))")
                }
                if output != nil {
                    for user in output!.items {
                        let userItem = user as? UsersTable
                        let currentRetrievedContact: User = User(userId: (userItem?._userId)!,
                                                                 phone: (userItem?._phone)!,
                                                                 addressPrivacyChoices: (userItem?._addressPrivacyChoices)! as! [Bool],
                                                                 addresses: [CLLocationCoordinate2DMake(userItem?._firstAddressCoordinate![0] as! CLLocationDegrees,
                                                                                                        userItem?._firstAddressCoordinate![1] as! CLLocationDegrees),
                                                                             CLLocationCoordinate2DMake(userItem?._secondAddressCoordinate![0] as! CLLocationDegrees,
                                                                                                        userItem?._secondAddressCoordinate![1] as! CLLocationDegrees)],
                                                                 addressNames: ["dummyText"],
                                                                 addressAliases: (userItem?._addressAliases)!,
                                                                 locations: [CLLocationCoordinate2DMake(0,
                                                                                                        0),
                                                                             CLLocationCoordinate2DMake(0,
                                                                                                        0),
                                                                             CLLocationCoordinate2DMake(0,
                                                                                                        0)],
                                                                 locationNames: ["dummyText"],
                                                                 locationAliases: ["dummyText"],
                                                                 contacts: (userItem?._contacts)!,
                                                                 name: (userItem?._name)!,
                                                                 endpointArn: (userItem?._endpointArn)!,
                                                                 userPictureName: "dummyText")
                        currentRetrievedContact.userPictureName = selectedUser.userPictureName
                        DataStore.sharedInstance.contactsList.append(currentRetrievedContact)
                        DataStore.sharedInstance.currentUser?.contacts?.append(currentRetrievedContact.userId!)
                        self.downloadAllDropsInvolvingUser(user: currentRetrievedContact.userId!)
                    }
                }
                self.saveUserContacts()
                self.uploadCurrentUser(endpointArn: (DataStore.sharedInstance.currentUser?.endpointArn![0])!)
            }
        }
    }
    
    func getAllUsers() {
        if DataStore.sharedInstance.allUsers.count > 0 {
            DataStore.sharedInstance.allUsers.removeAll()
        }
        
        // 1) Configure the query
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.limit = 100
        
        // 2) Make the scan
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDbObjectMapper.scan(UsersTable.self, expression: scanExpression) { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if error != nil {
                print("The request for getAllUsers failed. Error: \(String(describing: error))")
            }
            if output != nil {
                for user in output!.items {
                    let userItem = user as? UsersTable
                    let currentRetrievedBasicUser = BasicUser(name: (userItem?._name)!,
                                                         userPictureName: (userItem?._userPictureName)!)
                    DataStore.sharedInstance.allUsers.append(currentRetrievedBasicUser)
                    if userItem?._userPictureName != "dummyText" {
                        self.downloadContactPicture(with: (userItem?._userPictureName)!, basicUser: currentRetrievedBasicUser)
                    }
                }
            }
        }
    }
    
    func saveCurrentUser() {
        let user = DataStore.sharedInstance.currentUser
        UserDefaults.standard.removeObject(forKey: "storedUser")
        let currentUser = NSKeyedArchiver.archivedData(withRootObject: user)
        UserDefaults.standard.set(currentUser, forKey: PreferencesKeys.storedUser)
    }
    
    func loadCurrentUser(endpointArn: String) {
        
        if UserDefaults.standard.object(forKey: "storedUser") != nil {
            let storedUser = UserDefaults.standard.data(forKey: PreferencesKeys.storedUser)
            let currentUser = NSKeyedUnarchiver.unarchiveObject(with: storedUser!) as? User
            DataStore.sharedInstance.currentUser = currentUser
        } else {
            let currentUserId = AWSIdentityManager.default().identityId!
            let currentUserPhone = "12345678910"
            let currentUserAddressPrivacyChoices = [NSNumber(value: 0),NSNumber(value: 0)]
            let currentUserAddresses = [CLLocationCoordinate2DMake(34.1033, -117.5759), CLLocationCoordinate2DMake(34.1033, -117.5759)]
            let currentAddressNames = ["Tap this text to enter your first address..", "Tap this text to enter your second address.."]
            let currentAddressAliases = ["Name this address. Ex: Home", "Name this address. Ex: Work"]
            let currentUserLocations = [CLLocationCoordinate2DMake(34.1033, -117.5759), CLLocationCoordinate2DMake(34.1033, -117.5759), CLLocationCoordinate2DMake(34.1033, -117.5759)]
            let currentLocationNames = ["Tap this text to enter your first location..", "Tap this text to enter your second location..", "Tap this text to enter your third location.."]
            let currentLocationAliases = ["Name this location.", "Name this location.", "Name this location."]
            let currentUserContacts = ["us-west-2:4b84ab5b-a6f6-496d-a877-dc9ab7682fc4"]
            let currentUserName = AWSCognitoUserPoolsSignInProvider.sharedInstance().getUserPool().currentUser()?.username
            var currentUserEndpointArn: [String] = []
            currentUserEndpointArn.append(endpointArn)
            let currentUserPictureName = "dummyText"
            
            let currentUser = User(userId: currentUserId,
                                   phone: currentUserPhone,
                                   addressPrivacyChoices: currentUserAddressPrivacyChoices as! [Bool],
                                   addresses: currentUserAddresses,
                                   addressNames: currentAddressNames,
                                   addressAliases: currentAddressAliases,
                                   locations: currentUserLocations,
                                   locationNames: currentLocationNames,
                                   locationAliases: currentLocationAliases,
                                   contacts: currentUserContacts,
                                   name: currentUserName!,
                                   endpointArn: currentUserEndpointArn,
                                   userPictureName: currentUserPictureName)
            DataStore.sharedInstance.currentUser = currentUser
        }
    }
    
    func uploadCurrentUser(endpointArn: String) {
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        let newestUser: UsersTable = UsersTable()
        
        var firstAddressCoordinateTemp: [NSNumber]?
        var secondAddressCoordinateTemp: [NSNumber]?
        var firstLocationCoordinateTemp: [NSNumber]?
        var secondLocationCoordinateTemp: [NSNumber]?
        var thirdLocationCoordinateTemp: [NSNumber]?
        
        newestUser._userId = DataStore.sharedInstance.currentUser?.userId
        newestUser._phone = DataStore.sharedInstance.currentUser?.phone
        newestUser._name = DataStore.sharedInstance.currentUser?.name
        newestUser._contacts = DataStore.sharedInstance.currentUser?.contacts
        firstAddressCoordinateTemp = [(DataStore.sharedInstance.currentUser?.addresses![0].latitude as NSNumber?)!,
                               (DataStore.sharedInstance.currentUser?.addresses![0].longitude as NSNumber?)!]
        newestUser._firstAddressCoordinate = firstAddressCoordinateTemp
        secondAddressCoordinateTemp = [(DataStore.sharedInstance.currentUser?.addresses![1].latitude as NSNumber?)!,
                                (DataStore.sharedInstance.currentUser?.addresses![1].longitude as NSNumber?)!]
        newestUser._secondAddressCoordinate = secondAddressCoordinateTemp
        newestUser._addressPrivacyChoices = DataStore.sharedInstance.currentUser?.addressPrivacyChoices
        newestUser._addressAliases = DataStore.sharedInstance.currentUser?.addressAliases
        newestUser._addressNames = DataStore.sharedInstance.currentUser?.addressNames
        firstLocationCoordinateTemp = [(DataStore.sharedInstance.currentUser?.locations![0].latitude as NSNumber?)!,
                                      (DataStore.sharedInstance.currentUser?.locations![0].longitude as NSNumber?)!]
        newestUser._firstLocationCoordinate = firstLocationCoordinateTemp
        secondLocationCoordinateTemp = [(DataStore.sharedInstance.currentUser?.locations![1].latitude as NSNumber?)!,
                                       (DataStore.sharedInstance.currentUser?.locations![1].longitude as NSNumber?)!]
        newestUser._secondLocationCoordinate = secondLocationCoordinateTemp
        thirdLocationCoordinateTemp = [(DataStore.sharedInstance.currentUser?.locations![2].latitude as NSNumber?)!,
                                       (DataStore.sharedInstance.currentUser?.locations![2].longitude as NSNumber?)!]
        newestUser._thirdLocationCoordinate = thirdLocationCoordinateTemp
        newestUser._locationAliases = DataStore.sharedInstance.currentUser?.locationAliases
        newestUser._locationNames = DataStore.sharedInstance.currentUser?.locationNames
        newestUser._endpointArn = DataStore.sharedInstance.currentUser?.endpointArn
        newestUser._userPictureName = DataStore.sharedInstance.currentUser?.userPictureName

        dynamoDbObjectMapper.save(newestUser, completionHandler: {
            (error: Error?) -> Void in
            if let error = error {
                 print("Amazon DynamoDB Save Error: \(error)")
                return
            }
             print("The current user was saved.")
        })
    }
    
    func createNewUser(endpointArn: String) {
        let currentUserId = AWSIdentityManager.default().identityId!
        let currentUserPhone = "12345678910"
        let currentUserAddressPrivacyChoices = [NSNumber(value: 0),NSNumber(value: 0)]
        let currentUserAddresses = [CLLocationCoordinate2DMake(34.1033, -117.5759), CLLocationCoordinate2DMake(34.1033, -117.5759)]
        let currentAddressNames = ["Tap this text to enter your first address..", "Tap this text to enter your second address.."]
        let currentAddressAliases = ["Name this address. Ex: Home", "Name this address. Ex: Work"]
        let currentUserLocations = [CLLocationCoordinate2DMake(34.1033, -117.5759), CLLocationCoordinate2DMake(34.1033, -117.5759), CLLocationCoordinate2DMake(34.1033, -117.5759)]
        let currentLocationNames = ["Tap this text to enter your first location..", "Tap this text to enter your second location..", "Tap this text to enter your third location.."]
        let currentLocationAliases = ["Name this location.", "Name this location.", "Name this location."]
        let currentUserContacts = ["us-west-2:4b84ab5b-a6f6-496d-a877-dc9ab7682fc4"]
        let currentUserName = AWSCognitoUserPoolsSignInProvider.sharedInstance().getUserPool().currentUser()?.username
        var currentUserEndpointArn: [String] = []
        currentUserEndpointArn.append(endpointArn)
        let currentUserPictureName = "dummyText"
        
        let currentUser = User(userId: currentUserId,
                               phone: currentUserPhone,
                               addressPrivacyChoices: currentUserAddressPrivacyChoices as! [Bool],
                               addresses: currentUserAddresses,
                               addressNames: currentAddressNames,
                               addressAliases: currentAddressAliases,
                               locations: currentUserLocations,
                               locationNames: currentLocationNames,
                               locationAliases: currentLocationAliases,
                               contacts: currentUserContacts,
                               name: currentUserName!,
                               endpointArn: currentUserEndpointArn,
                               userPictureName: currentUserPictureName)
        DataStore.sharedInstance.currentUser = currentUser
    }
    
    func prepareLocationAndNotifications() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 3.0
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if AWSSignInManager.sharedInstance().isLoggedIn {
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let options: UNAuthorizationOptions = [.alert, .sound];
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                print("Unable to register for local notifications.")
            }
        }
        
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
            } else {
            }
        }
    }
    
    func alertUser(drop: Drop) {
        let result = DataStore.sharedInstance.contactsList.filter{$0.userId == drop.sender}
        
        if drop.isPictureOrVideo == true {
            let imageData = NSData(contentsOf: drop.content)
            guard let imageOrVideoAttachment = UNNotificationAttachment.create(imageFileIdentifier: drop.droppedContent, data: imageData!, options: nil) else { return }
            var attachmentsArray: [UNNotificationAttachment] = []
            attachmentsArray.append(imageOrVideoAttachment)
            // print(content.attachments)
            content.attachments = attachmentsArray
            if drop.droppedMessage != "Write your message here..." {
                content.body = drop.droppedMessage
            }
        } else if drop.isPictureOrVideo == false {
            content.body = drop.droppedMessage
        }
        
        if result.count > 0 {
            content.title = "Your drop from \(result.last!.name!):"
            content.sound = UNNotificationSound.default
            let contentIdentifier = "UYLLocalNotificationContent"
            let requestEnter = UNNotificationRequest(identifier: contentIdentifier, content: content, trigger: nil)
            center.add(requestEnter)
            
            content.body = ""
            content.attachments = []
            updateDrop(drop: drop)
        }
    }

    func monitorDropEntry() {
        for drop in DataStore.sharedInstance.dropsFromOthers {
            let dropPointLocation = CLLocation(latitude: drop.centerCoordinate.latitude, longitude: drop.centerCoordinate.longitude)
            if dropPointLocation.distance(from: locationManager.location!) < drop.dropRadius {
                alertUser(drop: drop)
                if let index = DataStore.sharedInstance.dropsFromOthers.index(of: drop) {
                    DataStore.sharedInstance.dropsFromOthers.remove(at: index)
                }
                saveDrops()
            }
        }
    }
}



extension AppDelegate: CLLocationManagerDelegate {
//    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
//        if region is CLCircularRegion {
//          // Keeping these region functions around in case region monitoring is ever used in the future
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
//        if region is CLCircularRegion {
//          // Keeping these region functions around in case region monitoring is ever used in the future
//        }
//    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if DataStore.sharedInstance.dropsFromOthers.count > 0 {
            monitorDropEntry()
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent content: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}

extension Notification.Name {
    static let reload = Notification.Name("reload")
}

extension UNNotificationAttachment {
    static func create(imageFileIdentifier: String, data: NSData, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: tmpSubFolderURL!, withIntermediateDirectories: true, attributes: nil)
            let fileURL = tmpSubFolderURL?.appendingPathComponent(imageFileIdentifier)
            try data.write(to: fileURL!, options: [])
            let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL!, options: options)
            return imageAttachment
        } catch let error {
            print("error \(error)")
        }
        return nil
    }
}
