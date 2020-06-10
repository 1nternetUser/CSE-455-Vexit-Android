//
//  ContactListTableViewController.swift
//  VEXTit Drop

import UIKit

protocol MyCustomCellDelegator {
    func callSegueFromCell(myData dataobject: Int)
}

class ContactListTableViewController: UITableViewController, MyCustomCellDelegator {
    
    static let sharedInstance = ContactListTableViewController()
    
    @IBAction func unwindToVC1(segue:UIStoryboardSegue) { }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        print("ContactsList contains \(DataStore.sharedInstance.contactsList.count) elements.")

        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        
        for contact in DataStore.sharedInstance.contactsList {
            if contact.userPictureName != nil {
                contact.userPictureUrl = documentsPath?.appendingPathComponent(contact.userPictureName!)//.appendingPathExtension("png")
                if let imageData = NSData(contentsOf: contact.userPictureUrl!) {
                    contact.userPicture = UIImage(data: imageData as Data)
                }
            }
        }
        
        
        self.tableView?.allowsSelection = false
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataStore.sharedInstance.contactsList.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactTableViewCell
        cell.userPicture.image = DataStore.sharedInstance.contactsList[indexPath.row].userPicture
        cell.userName.text = DataStore.sharedInstance.contactsList[indexPath.row].name
        cell.tag = indexPath.item
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Choose contacts and press Drop when done."
    }
    
//    @IBAction func reloadContacts(_ sender: Any) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
//            self.tableView.reloadData()
//        })
//    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 5.0
    }
    
    func callSegueFromCell(myData dataobject: Int) {
        self.performSegue(withIdentifier: "showMapForDrop", sender:dataobject )
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
