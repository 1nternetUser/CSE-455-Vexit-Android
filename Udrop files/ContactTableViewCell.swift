//
//  ContactTableViewCell.swift
//  VEXTit Drop

import UIKit

class ContactTableViewCell: UITableViewCell {

    var delegate: MyCustomCellDelegator!
    
    @IBOutlet weak var userPicture: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var dropMethodSelection: DeselectableSegmentedControl!
    
    @IBAction func dropMethodSelected(_ sender: DeselectableSegmentedControl) {
        if (sender.selectedSegmentIndex == self.dropMethodSelection.previousSelectedSegmentIndex) {
            DataStore.sharedInstance.contactsList[tag].hasBeenSelectedForDrop = false
            sender.selectedSegmentIndex = UISegmentedControl.noSegment;
            self.dropMethodSelection.selectedSegmentIndex = UISegmentedControl.noSegment;
        }
        else {
            self.dropMethodSelection.selectedSegmentIndex = sender.selectedSegmentIndex;
        }
        if dropMethodSelection.selectedSegmentIndex == 0 {
            DataStore.sharedInstance.contactsList[tag].hasBeenSelectedForDrop = true
            DataStore.sharedInstance.contactsList[tag].selectedDropMethod = 3
        } else if dropMethodSelection.selectedSegmentIndex == 1 {
            DataStore.sharedInstance.contactsList[tag].hasBeenSelectedForDrop = true
            DataStore.sharedInstance.contactsList[tag].selectedDropMethod = 4
        } else if dropMethodSelection.selectedSegmentIndex == 2 {
            DataStore.sharedInstance.contactsList[tag].hasBeenSelectedForDrop = true
            DataStore.sharedInstance.contactsList[tag].selectedDropMethod = nil
            DataStore.sharedInstance.selectedContactInDropMap = self.tag
            self.delegate.callSegueFromCell(myData: 1)
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
