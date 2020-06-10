//
//  MyDrops.swift
//  VEXTit Drop

import UIKit
import AVKit
import AVFoundation
import MobileCoreServices

private let reuseIdentifier = "Cell"

class MyDrops: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    static let sharedInstance = MyDrops()
    
    var usernamesForDisplay: [String] = []
    var dateToString = DateFormatter()
    var navBarHeight: CGFloat?
    var bottomBarHeight: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.dataSource = self
        navBarHeight = UIApplication.shared.keyWindow?.safeAreaInsets.top
        bottomBarHeight = UIApplication.shared.keyWindow?.safeAreaInsets.bottom
        prepareDropsForViewing()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.register(MyDropsCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return DataStore.sharedInstance.allDropsForViewing!.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> MyDropsCollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MyDropsCollectionViewCell
        // Configure the cell
        cell.dropImage.isHidden = true
        cell.tapToWatch.isHidden = true

        
        if DataStore.sharedInstance.allDropsForViewing![indexPath.row].sender == DataStore.sharedInstance.currentUser?.userId {
            let contactsListRecipientIndex = DataStore.sharedInstance.contactsList.index(where: {$0.userId == DataStore.sharedInstance.allDropsForViewing![indexPath.row].recipient})
            cell.dropInfo.text = "Your drop to \(DataStore.sharedInstance.contactsList[contactsListRecipientIndex!].name!) at \(DataStore.sharedInstance.allDropsForViewing![indexPath.row].dropName) on \(DataStore.sharedInstance.allDropsForViewing![indexPath.row].dateForDisplay!)"
        } else {
            let contactsListSenderIndex = DataStore.sharedInstance.contactsList.index(where: {$0.userId == DataStore.sharedInstance.allDropsForViewing![indexPath.row].sender})
            cell.dropInfo.text = "Your drop from \(DataStore.sharedInstance.contactsList[contactsListSenderIndex!].name!) at \(DataStore.sharedInstance.allDropsForViewing![indexPath.row].dropName) on \(DataStore.sharedInstance.allDropsForViewing![indexPath.row].dateForDisplay!)"
        }
        if DataStore.sharedInstance.allDropsForViewing![indexPath.row].isPictureOrVideo == false {
            cell.dropMessage.isHidden = true
            cell.bigDropMessage.isHidden = false
            if DataStore.sharedInstance.allDropsForViewing![indexPath.row].droppedMessage != "Write your message here..." {
                cell.bigDropMessage.text = DataStore.sharedInstance.allDropsForViewing![indexPath.row].droppedMessage
            } else {
                cell.bigDropMessage.text = ""
            }
        }
        else if DataStore.sharedInstance.allDropsForViewing![indexPath.row].isPictureOrVideo == true {
            cell.bigDropMessage.isHidden = true
            cell.dropImage.isHidden = false
            cell.dropMessage.isHidden = false
            if DataStore.sharedInstance.allDropsForViewing![indexPath.row].contentType == "png" {
                cell.dropImage.image = DataStore.sharedInstance.allDropsForViewing![indexPath.row].pictureForDisplay
            } else if DataStore.sharedInstance.allDropsForViewing![indexPath.row].contentType == "mp4" {
                cell.dropImage.image = DataStore.sharedInstance.allDropsForViewing![indexPath.row].pictureForDisplay
                cell.tapToWatch.isHidden = false
            }
            if DataStore.sharedInstance.allDropsForViewing![indexPath.row].droppedMessage != "Write your message here..." {
                cell.dropMessage.text = DataStore.sharedInstance.allDropsForViewing![indexPath.row].droppedMessage
            } else {
                cell.dropMessage.text = ""
            }
        }
        return cell
    }

    // MARK: UICollectionViewDelegate

    
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
 

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if DataStore.sharedInstance.allDropsForViewing![indexPath.row].contentType == "mp4" {
            DataStore.sharedInstance.selectedCellInViewDrops = indexPath.row
            self.present((VideoViewController() as UIViewController), animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: self.view.layoutMargins.top,
                            left: 0,
                            bottom: self.view.layoutMargins.bottom,
                            right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: self.view.frame.height - self.view.layoutMargins.top - self.view.layoutMargins.bottom)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */
    

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    
    func prepareDropsForViewing() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        var contentId: String?
        
        dateToString.timeZone = TimeZone(abbreviation: "PST")
        dateToString.locale = NSLocale.current
        dateToString.timeStyle = .short
        dateToString.dateStyle = .long
        
        DataStore.sharedInstance.allDropsForViewing?.removeAll()
        DataStore.sharedInstance.allDropsForViewing = [DataStore.sharedInstance.dropsFromOthers, DataStore.sharedInstance.dropsForOthers].reduce([], { (result: [Drop], element: [Drop]) -> [Drop] in
            return result + element
        })
        DataStore.sharedInstance.allDropsForViewing?.sort(by: { $0.creationDate.intValue < $1.creationDate.intValue })
        
        for drop in DataStore.sharedInstance.allDropsForViewing! {
            let dropCreationDate = Date(timeIntervalSince1970: TimeInterval(truncating: drop.creationDate))
            drop.dateForDisplay = dateToString.string(from: dropCreationDate)
            
            if drop.isPictureOrVideo {
                contentId = drop.droppedContent.split(separator: ".").first?.description
                drop.content = (documentsPath?.appendingPathComponent(contentId!).appendingPathExtension("png"))!
                
                drop.contentType = drop.droppedContent.split(separator: ".").last?.description
                if drop.contentType == "png" {
                    if let imageData = NSData(contentsOf: drop.content) {
                        let convertedImage = UIImage(data: imageData as Data)
                        let resizedImage = convertedImage?.resized(withPercentage: 0.50)
                        drop.pictureForDisplay = resizedImage
                    }
                } else if drop.contentType == "mp4" {
                    contentId = drop.droppedContent
                    drop.content = (documentsPath?.appendingPathComponent(contentId!))!
                    drop.pictureForDisplay = videoPreviewUiimage(videoURL: drop.content)
                }
            }
        }
        //        for sentDrop in DataStore.sharedInstance.dropsForOthers {
        //            print(sentDrop.creationDate)
        //        }
        //        print("break")
        //        for receivedDrop in DataStore.sharedInstance.dropsFromOthers {
        //            print(receivedDrop.creationDate)
        //        }
    }
    
    func videoPreviewUiimage(videoURL: URL) -> UIImage? {
        
        let vidURL = videoURL
        let asset = AVURLAsset(url: vidURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let timestamp = CMTime(seconds: 2, preferredTimescale: 60)
        
        do {
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            return UIImage(cgImage: imageRef)
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
            return nil
        }
    }
}


extension UIImage {
    
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
