//
//  AddressSearchTable.swift
//  VEXTit Drop

import Foundation
import UIKit
import MapKit


class AddressSearchTable : UITableViewController {
    
    static let sharedInstance = AddressSearchTable()
    
    var addressMatches:[MKMapItem] = []
    var mapView: MKMapView? = nil
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


extension AddressSearchTable {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chosenAddress = addressMatches[indexPath.row].placemark
        
        
        if DataStore.sharedInstance.currentlySettingAddresses! {
//            if DataStore.sharedInstance.selectedAddressInSettings == 0 {
//                DataStore.sharedInstance.currentUser?.addresses![0] = chosenAddress.coordinate
//                DataStore.sharedInstance.currentUser?.addressNames![0] = chosenAddress.name!
//            }
//            if DataStore.sharedInstance.selectedAddressInSettings == 1 {
//                DataStore.sharedInstance.currentUser?.addresses![1] = chosenAddress.coordinate
//                DataStore.sharedInstance.currentUser?.addressNames![1] = chosenAddress.name!
//            }
            DataStore.sharedInstance.currentUser?.addresses![DataStore.sharedInstance.selectedAddressInSettings!] = chosenAddress.coordinate
            DataStore.sharedInstance.currentUser?.addressNames![DataStore.sharedInstance.selectedAddressInSettings!] = chosenAddress.name!

        } else {
//            if DataStore.sharedInstance.selectedLocationInSettings == 0 {
//                DataStore.sharedInstance.currentUser?.locations![0] = chosenAddress.coordinate
//                DataStore.sharedInstance.currentUser?.locationNames![0] = "Near \(chosenAddress.name!)"
//            }
//            if DataStore.sharedInstance.selectedLocationInSettings == 1 {
//                DataStore.sharedInstance.currentUser?.locations![1] = chosenAddress.coordinate
//                DataStore.sharedInstance.currentUser?.locationNames![1] = "Near \(chosenAddress.name!)"
//            }
//            if DataStore.sharedInstance.selectedLocationInSettings == 2 {
//                DataStore.sharedInstance.currentUser?.locations![2] = chosenAddress.coordinate
//                DataStore.sharedInstance.currentUser?.locationNames![2] = "Near \(chosenAddress.name!)"
//            }
            DataStore.sharedInstance.currentUser?.locations![DataStore.sharedInstance.selectedLocationInSettings!] = chosenAddress.coordinate
            DataStore.sharedInstance.currentUser?.locationNames![DataStore.sharedInstance.selectedLocationInSettings!] = "Near \(chosenAddress.name!)"
        }

        searchHandlerDelegate?.placePinAndZoomToSearchedLocation(placemark: chosenAddress)
        dismiss(animated: true, completion: nil)
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addressMatches.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let addressItem = tableView.dequeueReusableCell(withIdentifier: "address")!
        let chosenAddress = addressMatches[indexPath.row].placemark
        addressItem.textLabel?.text = chosenAddress.name
        addressItem.detailTextLabel?.text = parseDropAddress(chosenAddress: chosenAddress)
        return addressItem
    }
}


extension AddressSearchTable : UISearchResultsUpdating {
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
