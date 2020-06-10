//
//  AddressDropSearchTable.swift
//  VEXTit Drop


import Foundation
import UIKit
import MapKit


class AddressDropSearchTable : UITableViewController {
    
    static let sharedInstance = AddressDropSearchTable()
    
    var addressMatches:[MKMapItem] = []
    var mapView: MKMapView? = nil
    var mapSearchHandlerDelegate:MKLocalSearch? = nil
    var searchHandlerDelegate:SearchHandler? = nil
    
    func parseDropAddress(chosenAddress:MKPlacemark) -> String {

        let firstAddressLineSpace = (chosenAddress.subThoroughfare != nil && chosenAddress.thoroughfare != nil) ? " " : ""
        let addressComma = (chosenAddress.subThoroughfare != nil || chosenAddress.thoroughfare != nil) && (chosenAddress.subAdministrativeArea != nil || chosenAddress.administrativeArea != nil) ? ", " : ""
        let secondSpace = (chosenAddress.subAdministrativeArea != nil && chosenAddress.administrativeArea != nil) ? " " : ""
        let addressToDropAt = String(format:"%@%@%@%@%@%@%@", chosenAddress.subThoroughfare ?? "", firstAddressLineSpace, chosenAddress.thoroughfare ?? "", addressComma,
                                        chosenAddress.locality ?? "", secondSpace, chosenAddress.administrativeArea ?? ""
        )
        return addressToDropAt
    }
}


extension AddressDropSearchTable {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chosenAddress = addressMatches[indexPath.row].placemark
        DataStore.sharedInstance.contactsList[DataStore.sharedInstance.selectedContactInDropMap!].selectedAddress = chosenAddress.coordinate
        DataStore.sharedInstance.contactsList[DataStore.sharedInstance.selectedContactInDropMap!].selectedDropMethod = 2
        DataStore.sharedInstance.contactsList[DataStore.sharedInstance.selectedContactInDropMap!].selectedAddressAlias = "\(chosenAddress.subThoroughfare!) \(chosenAddress.thoroughfare!)"
        //mapSearchHandlerDelegate.placePinAndZoomToUserLocation(placemark: chosenAddress)
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addressMatches.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let addressItem = tableView.dequeueReusableCell(withIdentifier: "addressItem")!
        let chosenAddress = addressMatches[indexPath.row].placemark
        addressItem.textLabel?.text = chosenAddress.name
        addressItem.detailTextLabel?.text = parseDropAddress(chosenAddress: chosenAddress)
        return addressItem
    }
}


extension AddressDropSearchTable : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView,
        let searchBarText = searchController.searchBar.text else { return }
        let addressSearchRequest = MKLocalSearch.Request()
        addressSearchRequest.naturalLanguageQuery = searchBarText
        addressSearchRequest.region = mapView.region
        let addressSearch = MKLocalSearch(request: addressSearchRequest)
        addressSearch.start { response, _ in
            guard let response = response else {
            return
            }
            self.addressMatches = response.mapItems
            self.tableView.reloadData()
        }
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
    }
}
