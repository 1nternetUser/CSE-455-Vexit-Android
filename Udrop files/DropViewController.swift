//
//  DropViewController.swift
//  VEXTit Drop


import UIKit
import MapKit
import MobileCoreServices
//import AssetsLibrary
import Photos

class DropViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var dropName: CustomTextField!
    @IBOutlet weak var dropMessage: UITextView!
    @IBOutlet weak var dropSizeSwitch: UISwitch!
    @IBOutlet weak var dropSizeLabel: UILabel!
    @IBOutlet weak var dropTypeSelector: UISegmentedControl!
    @IBOutlet weak var messageKeyboardScroll: UIScrollView!
    
    let keyboardNotifier = NotificationCenter.default
    let imagePicker = UIImagePickerController()
    var imageURL = NSURL()
    var contentSourceChoice: UIAlertController?
    var contentName: String = "dummyText"
    var randomImageName: String?
    var dropsAlbum: PHAssetCollection = PHAssetCollection()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
     /*   keyboardNotifier.addObserver(self, selector: #selector(scrollForKeyboard), name: Notification.Name.UIResponder.keyboardWillHideNotification, object: nil)
        keyboardNotifier.addObserver(self, selector: #selector(scrollForKeyboard), name: Notification.Name.UIResponder.keyboardWillChangeFrameNotification, object: nil)
*/
        dropMessage.delegate = self
        dropMessage.layer.borderWidth = 1.0
        dropMessage.layer.borderColor = UIColor.lightGray.cgColor
        dropMessage.layer.cornerRadius = 16.0
        dropMessage.text = "Write your message here..."
//        dropMessage.isHidden = true
        dropMessage.textColor = UIColor.darkGray
        dropMessage.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        dropName.delegate = self
        dropName.text = nil
        dropName.layer.borderWidth = 1.0
        dropName.layer.borderColor = UIColor.lightGray.cgColor
        dropName.layer.cornerRadius = 16.0
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        imagePicker.videoMaximumDuration = 20.0
        dropTypeSelector.selectedSegmentIndex = -1
        
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            contentSourceChoice = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            contentSourceChoice?.addAction(UIAlertAction(title: NSLocalizedString("Capture", comment: "Capture Media"), style: .`default`, handler: { _ in
                self.imagePicker.sourceType = .camera
                self.present(self.imagePicker, animated: true)
            }))
            contentSourceChoice?.addAction(UIAlertAction(title: NSLocalizedString("Library", comment: "Find in Library"), style: .`default`, handler: { _ in
                self.imagePicker.sourceType = .savedPhotosAlbum
                self.present(self.imagePicker, animated: true)
            }))
            contentSourceChoice?.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Dismiss Choices"), style: .`destructive`, handler: { _ in
                self.dropTypeSelector.selectedSegmentIndex = -1
                if self.dropMessage.text == "Write your message here..." {
//                    self.dropMessage.isHidden = true
                }
            }))
        } else if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone {
            contentSourceChoice = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            contentSourceChoice?.addAction(UIAlertAction(title: NSLocalizedString("Capture", comment: "Capture Media"), style: .`default`, handler: { _ in
                self.imagePicker.sourceType = .camera
                self.present(self.imagePicker, animated: true)
            }))
            contentSourceChoice?.addAction(UIAlertAction(title: NSLocalizedString("Library", comment: "Find in Library"), style: .`default`, handler: { _ in
                self.imagePicker.sourceType = .savedPhotosAlbum
                self.present(self.imagePicker, animated: true)
            }))
            contentSourceChoice?.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Dismiss Choices"), style: .`destructive`, handler: { _ in
                self.dropTypeSelector.selectedSegmentIndex = -1
                if self.dropMessage.text == "Write your message here..." {
//                    self.dropMessage.isHidden = true
                }
            }))
        }
        randomImageName = UUID().uuidString
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Write your message here..." {
            textView.text = nil
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write your message here..."
        }
    }
    
    @objc func scrollForKeyboard(notification: Notification) {
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if Notfication.Name == UIResponder.keyboardWillHideNotification {
            messageKeyboardScroll.contentOffset = CGPoint.zero
        } else {
            messageKeyboardScroll.contentOffset = CGPoint.init(x: 0, y: keyboardViewEndFrame.height / 3)
        }
        messageKeyboardScroll.scrollIndicatorInsets = messageKeyboardScroll.contentInset
    }
    
    @IBAction func changedDropSizeSwitch(_ sender: Any) {
        if self.dropSizeSwitch.isOn == true {
            self.dropSizeLabel.text = "108 Feet"
        } else {
            self.dropSizeLabel.text = "18 Feet"
        }
    }
    
    @IBAction func selectedDropType(_ sender: Any) {
        if dropTypeSelector.selectedSegmentIndex == 0 {
//            if dropMessage.isHidden == true {
//                dropMessage.isHidden = false
//            }
            DataStore.sharedInstance.dropType = 0
            imagePicker.mediaTypes = [kUTTypeImage as String]
            present(contentSourceChoice!, animated: true, completion: nil)
        } else if dropTypeSelector.selectedSegmentIndex == 1 {
//            if dropMessage.isHidden == true {
//                dropMessage.isHidden = false
//            }
            DataStore.sharedInstance.dropType = 1
            imagePicker.mediaTypes = [kUTTypeMovie as String]
            present(contentSourceChoice!, animated: true, completion: nil)
        } else if dropTypeSelector.selectedSegmentIndex == 2 {
            DataStore.sharedInstance.dropType = 2
//            if dropMessage.isHidden == true {
//                dropMessage.isHidden = false
//            }
        }
    }
    
    @IBAction func handleSendDrop(_ sender: Any) {
        sendDrop()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func sendDrop () {
        DataStore.sharedInstance.dropRecipients = DataStore.sharedInstance.contactsList.filter({$0.hasBeenSelectedForDrop == true})
        
        if dropName.text != "" {
            print("dropName.text is not nil")
//            print(dropName?.text)
            if DataStore.sharedInstance.dropType == 0 || DataStore.sharedInstance.dropType == 1 {
                if DataStore.sharedInstance.dropType == 1 {
//                    let randomImageName = UUID().uuidString
                    AppDelegate.sharedInstance.uploadContent(with: randomImageName!, type: "mp4")
                    contentName = "\(randomImageName!).mp4"
                } else if DataStore.sharedInstance.dropType == 0 {
//                    let randomImageName = UUID().uuidString
                    AppDelegate.sharedInstance.uploadContent(with: randomImageName!, type: "png")
                    contentName = "\(randomImageName!).png"
                }
                
                for dropRecipient in DataStore.sharedInstance.dropRecipients {
                    if dropRecipient.selectedDropMethod == 0 {
                        makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropName.text!, messageToDrop: dropMessage.text!,
                                 contentToDrop: contentName, dropCoordinate: dropRecipient.placeToDrop!, isPrivate: false, isPictureOrVideo: true,
                                 content: DataStore.sharedInstance.imageToDropURL!)
                    } else if dropRecipient.selectedDropMethod == 1 {
                        makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropName.text!, messageToDrop: dropMessage.text!,
                                 contentToDrop: contentName, dropCoordinate: (dropRecipient.userLocationForDrop)!, isPrivate: false, isPictureOrVideo: true,
                                 content: DataStore.sharedInstance.imageToDropURL!)
                    } else if dropRecipient.selectedDropMethod == 2 {
                        makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropName.text!, messageToDrop: dropMessage.text!,
                                 contentToDrop: contentName, dropCoordinate: dropRecipient.selectedAddress!, isPrivate: false, isPictureOrVideo: true,
                                 content: DataStore.sharedInstance.imageToDropURL!)
                    } else if dropRecipient.selectedDropMethod == 3 {
                        if dropRecipient.addressPrivacyChoices![0] == true {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropName.text!, messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![0], isPrivate: true, isPictureOrVideo: true,
                                     content: DataStore.sharedInstance.imageToDropURL!)
                        } else if dropRecipient.addressPrivacyChoices![0] == false {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropName.text!, messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![0], isPrivate: false, isPictureOrVideo: true,
                                     content: DataStore.sharedInstance.imageToDropURL!)
                        }
                    } else if dropRecipient.selectedDropMethod == 4 {
                        if dropRecipient.addressPrivacyChoices![1] == true {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropName.text!, messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![1], isPrivate: true, isPictureOrVideo: true,
                                     content: DataStore.sharedInstance.imageToDropURL!)
                        } else if dropRecipient.addressPrivacyChoices![1] == false {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropName.text!, messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![1], isPrivate: false, isPictureOrVideo: true,
                                     content: DataStore.sharedInstance.imageToDropURL!)
                        }
                    } else {
                    }
                }
            } else {
                for dropRecipient in DataStore.sharedInstance.dropRecipients {
                    if dropRecipient.selectedDropMethod == 0 {
                        makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropName.text!, messageToDrop: dropMessage.text!,
                                 contentToDrop: contentName, dropCoordinate: dropRecipient.placeToDrop!, isPrivate: false, isPictureOrVideo: false,
                                 content: URL(string: "noImage")!)
                    } else if dropRecipient.selectedDropMethod == 1 {
                        makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropName.text!, messageToDrop: dropMessage.text!,
                                 contentToDrop: contentName, dropCoordinate: (dropRecipient.userLocationForDrop)!, isPrivate: false, isPictureOrVideo: false,
                                 content: URL(string: "noImage")!)
                    } else if dropRecipient.selectedDropMethod == 2 {
                        makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropName.text!, messageToDrop: dropMessage.text!,
                                 contentToDrop: contentName, dropCoordinate: dropRecipient.selectedAddress!, isPrivate: false, isPictureOrVideo: false,
                                 content: URL(string: "noImage")!)
                    } else if dropRecipient.selectedDropMethod == 3 {
                        if dropRecipient.addressPrivacyChoices![0] == true {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropName.text!, messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![0], isPrivate: true, isPictureOrVideo: false,
                                     content: URL(string: "noImage")!)
                        } else if dropRecipient.addressPrivacyChoices![0] == false {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropName.text!, messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![0], isPrivate: false, isPictureOrVideo: false,
                                     content: URL(string: "noImage")!)
                        }
                    } else if dropRecipient.selectedDropMethod == 4 {
                        if dropRecipient.addressPrivacyChoices![1] == true {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropName.text!, messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![1], isPrivate: true, isPictureOrVideo: false,
                                     content: URL(string: "noImage")!)
                        } else if dropRecipient.addressPrivacyChoices![1] == false {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropName.text!, messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![1], isPrivate: false, isPictureOrVideo: false,
                                     content: URL(string: "noImage")!)
                        }
                    } else {
                    }
                }
            }
        } else if dropName.text == "" {
            if DataStore.sharedInstance.dropType == 0 || DataStore.sharedInstance.dropType == 1 {
                if DataStore.sharedInstance.dropType == 1 {
//                    let randomImageName = UUID().uuidString
                    AppDelegate.sharedInstance.uploadContent(with: randomImageName!, type: "mp4")
                    contentName = "\(randomImageName!).mp4"
                } else if DataStore.sharedInstance.dropType == 0 {
//                    let randomImageName = UUID().uuidString
                    AppDelegate.sharedInstance.uploadContent(with: randomImageName!, type: "png")
                    contentName = "\(randomImageName!).png"
                }
                
                for dropRecipient in DataStore.sharedInstance.dropRecipients {
                    if dropRecipient.selectedDropMethod == 0 {
                        makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropRecipient.placeToDropAlias!, messageToDrop: dropMessage.text!,
                                 contentToDrop: contentName, dropCoordinate: dropRecipient.placeToDrop!, isPrivate: false, isPictureOrVideo: true,
                                 content: DataStore.sharedInstance.imageToDropURL!)
                    } else if dropRecipient.selectedDropMethod == 1 {
                        makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropRecipient.userLocationForDropAlias!, messageToDrop: dropMessage.text!,
                                 contentToDrop: contentName, dropCoordinate: (dropRecipient.userLocationForDrop)!, isPrivate: false, isPictureOrVideo: true,
                                 content: DataStore.sharedInstance.imageToDropURL!)
                    } else if dropRecipient.selectedDropMethod == 2 {
                        makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropRecipient.selectedAddressAlias!, messageToDrop: dropMessage.text!,
                                 contentToDrop: contentName, dropCoordinate: dropRecipient.selectedAddress!, isPrivate: false, isPictureOrVideo: true,
                                 content: DataStore.sharedInstance.imageToDropURL!)
                    } else if dropRecipient.selectedDropMethod == 3 {
                        if dropRecipient.addressPrivacyChoices![0] == true {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropRecipient.addressAliases![0], messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![0], isPrivate: true, isPictureOrVideo: true,
                                     content: DataStore.sharedInstance.imageToDropURL!)
                        } else if dropRecipient.addressPrivacyChoices![0] == false {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropRecipient.addressAliases![0], messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![0], isPrivate: false, isPictureOrVideo: true,
                                     content: DataStore.sharedInstance.imageToDropURL!)
                        }
                    } else if dropRecipient.selectedDropMethod == 4 {
                        if dropRecipient.addressPrivacyChoices![1] == true {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropRecipient.addressAliases![1], messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![1], isPrivate: true, isPictureOrVideo: true,
                                     content: DataStore.sharedInstance.imageToDropURL!)
                        } else if dropRecipient.addressPrivacyChoices![1] == false {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropRecipient.addressAliases![1], messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![1], isPrivate: false, isPictureOrVideo: true,
                                     content: DataStore.sharedInstance.imageToDropURL!)
                        }
                    } else {
                    }
                }
            } else {
                for dropRecipient in DataStore.sharedInstance.dropRecipients {
                    if dropRecipient.selectedDropMethod == 0 {
                        makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropRecipient.placeToDropAlias!, messageToDrop: dropMessage.text!,
                                 contentToDrop: contentName, dropCoordinate: dropRecipient.placeToDrop!, isPrivate: false, isPictureOrVideo: false,
                                 content: URL(string: "noImage")!)
                    } else if dropRecipient.selectedDropMethod == 1 {
                        makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropRecipient.userLocationForDropAlias!, messageToDrop: dropMessage.text!,
                                 contentToDrop: contentName, dropCoordinate: (dropRecipient.userLocationForDrop)!, isPrivate: false, isPictureOrVideo: false,
                                 content: URL(string: "noImage")!)
                    } else if dropRecipient.selectedDropMethod == 2 {
                        makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropRecipient.selectedAddressAlias!, messageToDrop: dropMessage.text!,
                                 contentToDrop: contentName, dropCoordinate: dropRecipient.selectedAddress!, isPrivate: false, isPictureOrVideo: false,
                                 content: URL(string: "noImage")!)
                    } else if dropRecipient.selectedDropMethod == 3 {
                        if dropRecipient.addressPrivacyChoices![0] == true {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropRecipient.addressAliases![0], messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![0], isPrivate: true, isPictureOrVideo: false,
                                     content: URL(string: "noImage")!)
                        } else if dropRecipient.addressPrivacyChoices![0] == false {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropRecipient.addressAliases![0], messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![0], isPrivate: false, isPictureOrVideo: false,
                                     content: URL(string: "noImage")!)
                        }
                    } else if dropRecipient.selectedDropMethod == 4 {
                        if dropRecipient.addressPrivacyChoices![1] == true {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropRecipient.addressAliases![1], messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![1], isPrivate: true, isPictureOrVideo: false,
                                     content: URL(string: "noImage")!)
                        } else if dropRecipient.addressPrivacyChoices![1] == false {
                            makeDrop(recipient: dropRecipient.userId!, nameOfDrop: dropRecipient.addressAliases![1], messageToDrop: dropMessage.text!,
                                     contentToDrop: contentName, dropCoordinate: dropRecipient.addresses![1], isPrivate: false, isPictureOrVideo: false,
                                     content: URL(string: "noImage")!)
                        }
                    } else {
                    }
                }
            }
        }
        
        if dropMessage.text !=  "Write your message here..."{
            dropMessage.text = "Write your message here..."
        }
        if contentName != "dummyText" {
            contentName = "dummyText"
        }
        DataStore.sharedInstance.dropRecipients.removeAll()
        performSegue(withIdentifier: "unwindSegueToVC1", sender: self)
    }

    fileprivate func makeDrop(recipient: String, nameOfDrop: String, messageToDrop: String, contentToDrop: String,
                              dropCoordinate: CLLocationCoordinate2D, isPrivate: Bool, isPictureOrVideo: Bool, content: URL) {
        var newDrop: Drop?
        var creationDate: Date?
        var intervalSince1970: TimeInterval?
        var intervalSince1970NS: NSNumber?
        let dropRadiusChoice: Double?
        if dropSizeSwitch.isOn == true {
            dropRadiusChoice = 18.0
        } else {
            dropRadiusChoice = 3.0
        }
        creationDate = Date()
        intervalSince1970 = creationDate?.timeIntervalSince1970.magnitude
        intervalSince1970NS = NSNumber(floatLiteral: intervalSince1970!)
        newDrop = Drop(sender: (DataStore.sharedInstance.currentUser?.userId)!, recipient: recipient, centerCoordinate: dropCoordinate,
                       dropRadius: dropRadiusChoice!, creationDate: intervalSince1970NS!, droppedMessage: messageToDrop, droppedContent: contentToDrop,
                       dropName: nameOfDrop, hasBeenReceived: false, isPrivate: isPrivate, isPictureOrVideo: isPictureOrVideo, content: content)
        DataStore.sharedInstance.dropsForOthers.append(newDrop!)
        print("Appended a drop to dropsForOthers in makeDrop.")
        AppDelegate.sharedInstance.uploadNewestDrop()
        AppDelegate.sharedInstance.saveDrops()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension DropViewController: UINavigationControllerDelegate {
    
}


extension DropViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        var imagePath: URL?
        
        if imagePicker.mediaTypes == [kUTTypeImage as String] {
            imagePath = documentsPath?.appendingPathComponent(randomImageName!).appendingPathExtension("png")

            var pickedImage: UIImage

            if let possibleImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
                pickedImage = possibleImage
                try! pickedImage.pngData()?.write(to: imagePath!, options: .atomicWrite)
            } else if let possibleImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
                pickedImage = possibleImage
                try! pickedImage.pngData()?.write(to: imagePath!, options: .atomicWrite)
            } else {
                return
            }
        } else if imagePicker.mediaTypes == [kUTTypeMovie as String]{
            imagePath = documentsPath?.appendingPathComponent(randomImageName!).appendingPathExtension("mp4")

            let pickedVideo = info["UIImagePickerControllerMediaURL"] as? URL
            let movieData = NSData(contentsOf: pickedVideo!)
            movieData?.write(to: imagePath!, atomically: false)
        }
        DataStore.sharedInstance.imageToDropURL = imagePath
        
        dismiss(animated: true)
    }
}
