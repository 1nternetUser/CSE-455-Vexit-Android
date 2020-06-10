//
//  AddUsersTableViewController.swift
//  VEXTit Drop

import UIKit
import AWSAuthUI
import AWSAuthCore
import AWSUserPoolsSignIn
import AWSMobileClient

class AddUsersTableViewController: UITableViewController {
    
    static let sharedInstance = AddUsersTableViewController()
    
    var addedUserAlert: UIAlertController?
    var didFinishLoading: Bool?
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var contactsButton: UIBarButtonItem!
    @IBOutlet weak var reloadButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var signOutButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        didFinishLoading = false
        settingsButton.isEnabled = false
        contactsButton.isEnabled = false
//        reloadButton.isEnabled = false
        addButton.isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: .reload, object: nil)
        if !AWSSignInManager.sharedInstance().isLoggedIn {
            presentAuthUIViewController()
        }
        
        self.tableView.allowsMultipleSelection = true
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func reloadTableData(_ notification: Notification) {
        didFinishLoading = true
        tableView.reloadData()
        settingsButton.isEnabled = true
        contactsButton.isEnabled = true
//        reloadButton.isEnabled = true
        addButton.isEnabled = true
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataStore.sharedInstance.allUsers.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> AllUsersTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as? AllUsersTableViewCell
        cell?.userPicture?.image = DataStore.sharedInstance.allUsers[indexPath.row].userPicture
        cell?.userName.text = DataStore.sharedInstance.allUsers[indexPath.row].name
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (didFinishLoading == false) {
            return "Loading..."
        } else if (didFinishLoading == true) {
            return "Select VEXTit users and tap ➕ to add contacts."
        }
        return "Default"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let customCell = self.tableView.cellForRow(at: indexPath) as! AllUsersTableViewCell
        let selectedBasicUser = DataStore.sharedInstance.allUsers.filter({$0.name == customCell.userName.text}).first
        DataStore.sharedInstance.usersToAddToContacts.append(selectedBasicUser!)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let customCell = self.tableView.cellForRow(at: indexPath) as! AllUsersTableViewCell
        let selectedContactName = customCell.userName.text
        if let deselectedUser = DataStore.sharedInstance.usersToAddToContacts.firstIndex(where: {$0.name == selectedContactName}) {
            DataStore.sharedInstance.usersToAddToContacts.remove(at: deselectedUser)
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func addToContacts(_ sender: Any) {
//        print(DataStore.sharedInstance.usersToAddToContacts.count)
        if DataStore.sharedInstance.usersToAddToContacts.count > 0 {
            AppDelegate.sharedInstance.addSelectedContacts(usersToAdd: DataStore.sharedInstance.usersToAddToContacts)
            addedUserAlert = UIAlertController(title: "You added users..." , message: "You added \(DataStore.sharedInstance.usersToAddToContacts.count) users to your Contacts List.", preferredStyle: .alert)
            addedUserAlert?.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Added Users"), style: .`default`, handler: { _ in
            }))
            present(addedUserAlert!, animated: true, completion: nil)
            DataStore.sharedInstance.usersToAddToContacts.removeAll()
        }
    }
    
//    @IBAction func reloadTable(_ sender: Any) {
//        self.tableView.reloadData()
//    }
    
    func presentAuthUIViewController() {
        let config = AWSAuthUIConfiguration()
        config.enableUserPoolsUI = true
        config.backgroundColor = UIColor(red: 200.0/255.0, green: 90.0/255.0, blue: 236.0/255.0, alpha: 0.6)
        config.logoImage = #imageLiteral(resourceName: "VEXTit-Login.png")
        config.font = UIFont (name: "Helvetica Neue", size: 20)
        config.isBackgroundColorFullScreen = true
        config.canCancel = true
        
        AWSAuthUIViewController.presentViewController(
            with: self.navigationController!,
            configuration: config, completionHandler: { (provider: AWSSignInProvider, error: Error?) in
                if error == nil {
                    // SignIn succeeded.
                    UIApplication.shared.registerForRemoteNotifications()
                    print("called registerForRemoteNotifications from sign-in code")
                } else {
                    // end user faced error while loggin in, take any required action here.
                }
        })
    }
    
    @IBAction func signOut(_ sender: Any) {
        if (AWSSignInManager.sharedInstance().isLoggedIn) {
            AWSSignInManager.sharedInstance().logout(completionHandler: {(result: Any?, error: Error?) in
                DataStore.sharedInstance.contactsList.removeAll()
                DataStore.sharedInstance.allUsers.removeAll()
                DataStore.sharedInstance.dropsForOthers.removeAll()
                DataStore.sharedInstance.dropsFromOthers.removeAll()
                DataStore.sharedInstance.dropRecipients.removeAll()
                self.presentAuthUIViewController()
            })
        } else {
            assert(false)
        }
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

}
