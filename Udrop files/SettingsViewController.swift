//
//  SettingsViewController.swift
//  VEXTit Drop

import UIKit
import AWSAuthUI
import AWSAuthCore
import AWSUserPoolsSignIn
import AWSMobileClient
import MapKit
import Photos
import MobileCoreServices

class SettingsViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {
    
    static let sharedInstance = SettingsViewController()

    @IBOutlet weak var userPicture: UIImageView!
    @IBOutlet weak var firstAddress: UIButton!
    @IBOutlet weak var secondAddress: UIButton!
    @IBOutlet weak var firstAddressPrivacy: UILabel!
    @IBOutlet weak var secondAddressPrivacy: UILabel!
    @IBOutlet weak var firstPrivacySwitch: UISwitch!
    @IBOutlet weak var secondPrivacySwitch: UISwitch!
    @IBOutlet weak var firstAddressName: CustomTextField!
    @IBOutlet weak var secondAddressName: CustomTextField!
    @IBOutlet weak var firstLocation: UIButton!
    @IBOutlet weak var firstLocationName: CustomTextField!
    @IBOutlet weak var secondLocation: UIButton!
    @IBOutlet weak var secondLocationName: CustomTextField!
    @IBOutlet weak var thirdLocation: UIButton!
    @IBOutlet weak var thirdLocationName: CustomTextField!
    
    
    @IBOutlet weak var signInOrOut: UIBarButtonItem!
    @IBOutlet weak var keyboardScroll: UIScrollView!
    
    var randomImageName: String?
    let imagePicker = UIImagePickerController()
    var contentSourceChoice: UIAlertController?
    let keyboardNotifier = NotificationCenter.default
    var firstIsPrivate: Bool?
    var secondIsPrivate: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        keyboardNotifier.addObserver(self, selector: #selector(scrollForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        keyboardNotifier.addObserver(self, selector: #selector(scrollForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        firstIsPrivate = false
        secondIsPrivate = false
        firstAddressName.delegate = self
        secondAddressName.delegate = self
        firstLocationName.delegate = self
        secondLocationName.delegate = self
        thirdLocationName.delegate = self
        firstAddressName.layer.borderWidth = 1.0
        firstAddressName.layer.borderColor = UIColor.lightGray.cgColor
        firstAddressName.layer.cornerRadius = 16.0
        secondAddressName.layer.borderWidth = 1.0
        secondAddressName.layer.borderColor = UIColor.lightGray.cgColor
        secondAddressName.layer.cornerRadius = 16.0
        firstLocationName.layer.borderWidth = 1.0
        firstLocationName.layer.borderColor = UIColor.lightGray.cgColor
        firstLocationName.layer.cornerRadius = 16.0
        secondLocationName.layer.borderWidth = 1.0
        secondLocationName.layer.borderColor = UIColor.lightGray.cgColor
        secondLocationName.layer.cornerRadius = 16.0
        thirdLocationName.layer.borderWidth = 1.0
        thirdLocationName.layer.borderColor = UIColor.lightGray.cgColor
        thirdLocationName.layer.cornerRadius = 16.0
        
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
            }))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        if DataStore.sharedInstance.currentUser != nil {
            if DataStore.sharedInstance.currentUser?.userPictureName != nil {
                let userPicturePath = documentsPath?.appendingPathComponent((DataStore.sharedInstance.currentUser?.userPictureName)!)
                print("The userPicturePath is: \(userPicturePath?.absoluteString).")
                if let imageData = NSData(contentsOf: userPicturePath!) {
                    userPicture.image = UIImage(data: imageData as Data)
                }
            }
            firstAddress.setTitle(DataStore.sharedInstance.currentUser?.addressNames![0], for: .normal)
            secondAddress.setTitle(DataStore.sharedInstance.currentUser?.addressNames![1], for: .normal)
            firstPrivacySwitch.isOn = (DataStore.sharedInstance.currentUser?.addressPrivacyChoices![0])!
            if firstPrivacySwitch.isOn {
                firstAddressPrivacy.text = "Private"
            } else {
                firstAddressPrivacy.text = "Public"
            }
            secondPrivacySwitch.isOn = (DataStore.sharedInstance.currentUser?.addressPrivacyChoices![1])!
            if secondPrivacySwitch.isOn {
                secondAddressPrivacy.text = "Private"
            } else {
                secondAddressPrivacy.text = "Public"
            }
            firstAddressName.text = DataStore.sharedInstance.currentUser?.addressAliases![0]
            secondAddressName.text = DataStore.sharedInstance.currentUser?.addressAliases![1]
            firstLocation.setTitle(DataStore.sharedInstance.currentUser?.locationNames![0], for: .normal)
            firstLocationName.text = DataStore.sharedInstance.currentUser?.locationAliases![0]
            secondLocation.setTitle(DataStore.sharedInstance.currentUser?.locationNames![1], for: .normal)
            secondLocationName.text = DataStore.sharedInstance.currentUser?.locationAliases![1]
            thirdLocation.setTitle(DataStore.sharedInstance.currentUser?.locationNames![2], for: .normal)
            thirdLocationName.text = DataStore.sharedInstance.currentUser?.locationAliases![2]
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if isMovingFromParent {
            AppDelegate.sharedInstance.saveCurrentUser()
            AppDelegate.sharedInstance.uploadCurrentUser(endpointArn: (DataStore.sharedInstance.currentUser?.endpointArn![0])!)
            if randomImageName != nil {
                AppDelegate.sharedInstance.uploadContent(with: randomImageName!, type: "png")
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == firstAddressName {
            DataStore.sharedInstance.currentUser?.addressAliases![0] = textField.text!
        } else if textField == secondAddressName {
            DataStore.sharedInstance.currentUser?.addressAliases![1] = textField.text!
        } else if textField == firstLocationName {
            DataStore.sharedInstance.currentUser?.locationAliases![0] = textField.text!
        } else if textField == secondLocationName {
            DataStore.sharedInstance.currentUser?.locationAliases![1] = textField.text!
        } else if textField == thirdLocationName {
            DataStore.sharedInstance.currentUser?.locationAliases![2] = textField.text!
        }
    }
    
    @objc func scrollForKeyboard(notification: Notification) {
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            keyboardScroll.contentInset = UIEdgeInsets.zero
        } else {
            keyboardScroll.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }
        
        keyboardScroll.scrollIndicatorInsets = keyboardScroll.contentInset
    }
    
    
    @IBAction func tappedUserPicture(_ sender: Any) {
        imagePicker.mediaTypes = [kUTTypeImage as String]
        present(contentSourceChoice!, animated: true, completion: nil)
    }
    
    @IBAction func pressedFirstAddress(_ sender: Any) {
        DataStore.sharedInstance.selectedAddressInSettings = 0
        DataStore.sharedInstance.currentlySettingAddresses = true
    }
    
    @IBAction func pressedSecondAddress(_ sender: Any) {
        DataStore.sharedInstance.selectedAddressInSettings = 1
        DataStore.sharedInstance.currentlySettingAddresses = true
    }
    
    @IBAction func pressedFirstLocation(_ sender: Any) {
        DataStore.sharedInstance.selectedLocationInSettings = 0
        DataStore.sharedInstance.currentlySettingAddresses = false
    }
    
    @IBAction func pressedSecondLocation(_ sender: Any) {
        DataStore.sharedInstance.selectedLocationInSettings = 1
        DataStore.sharedInstance.currentlySettingAddresses = false
    }
    
    @IBAction func pressedThirdLocation(_ sender: Any) {
        DataStore.sharedInstance.selectedLocationInSettings = 2
        DataStore.sharedInstance.currentlySettingAddresses = false
    }
    
    
    
    @IBAction func changedFirstAddressSwitch(_ sender: Any) {
        if self.firstPrivacySwitch.isOn == true {
            self.firstAddressPrivacy.text = "Private"
            DataStore.sharedInstance.currentUser?.addressPrivacyChoices![0] = true
        } else {
            self.firstAddressPrivacy.text = "Public"
            DataStore.sharedInstance.currentUser?.addressPrivacyChoices![0] = false
        }
    }
    
    @IBAction func changedSecondAddressSwitch(_ sender: Any) {
        if self.secondPrivacySwitch.isOn == true {
            self.secondAddressPrivacy.text = "Private"
            DataStore.sharedInstance.currentUser?.addressPrivacyChoices![1] = true
        } else {
            self.secondAddressPrivacy.text = "Public"
            DataStore.sharedInstance.currentUser?.addressPrivacyChoices![1] = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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


extension SettingsViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        randomImageName = UUID().uuidString
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        var imagePath: URL?
        
        if imagePicker.mediaTypes == [kUTTypeImage as String] {
            imagePath = documentsPath?.appendingPathComponent(randomImageName!).appendingPathExtension("png")
            
            var pickedImage: UIImage
            var resizedImage: UIImage
            
            if let possibleImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
                pickedImage = possibleImage
                resizedImage = pickedImage.resized(withPercentage: 0.25)!
                try! resizedImage.pngData()?.write(to: imagePath!, options: .atomicWrite)
                userPicture.image = pickedImage
            } else if let possibleImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
                pickedImage = possibleImage
                resizedImage = pickedImage.resized(withPercentage: 0.25)!
                try! resizedImage.pngData()?.write(to: imagePath!, options: .atomicWrite)
                userPicture.image = pickedImage
            } else {
                return
            }
        }
        DataStore.sharedInstance.currentUser?.userPictureName = randomImageName?.appending(".png")
        DataStore.sharedInstance.currentUser?.userPictureUrl = imagePath
        DataStore.sharedInstance.imageToDropURL = imagePath
        
        dismiss(animated: true)
    }
}

