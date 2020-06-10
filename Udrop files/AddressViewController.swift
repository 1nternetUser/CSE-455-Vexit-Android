//
//  AddressViewController.swift
//  VEXTit Drop

import UIKit
import MapKit

protocol SearchHandler {
    func placePinAndZoomToSearchedLocation(placemark:MKPlacemark)
}

class AddressViewController: UIViewController, MKMapViewDelegate, SearchHandler {
    func placePinAndZoomToSearchedLocation(placemark: MKPlacemark) {
        addressPin = placemark
        addressMapView.removeAnnotations(addressMapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        addressMapView.addAnnotation(annotation)
        let zoomWidth = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let viewRegion = MKCoordinateRegion(center: placemark.coordinate, span: zoomWidth)
        addressMapView.setRegion(viewRegion, animated: true)    }
    
    
    
    static let sharedInstance = AddressViewController()

    var addressPin: MKPlacemark? = nil
    let locationManager = CLLocationManager()
    var addressSearchController: UISearchController? = nil
    var previousLocation: CLLocationCoordinate2D?
    @IBOutlet weak var addressMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpAddressFeature()
        if DataStore.sharedInstance.currentUser?.addresses?.first?.latitude == 0 &&
            DataStore.sharedInstance.currentUser?.addresses?.first?.longitude == 0 {
            initializeMapAtUserLocation()
        } else {
            initializeMapAtStoredLocation()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func setUpAddressFeature() {
        let addressSearchTable = storyboard!.instantiateViewController(withIdentifier: "AddressSearchTable") as! AddressSearchTable
        addressSearchController = UISearchController(searchResultsController: addressSearchTable)
        addressSearchController?.searchResultsUpdater = addressSearchTable as UISearchResultsUpdating
        
        let searchBar = addressSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for address.."
        navigationItem.titleView = addressSearchController?.searchBar
        
        addressSearchController?.hidesNavigationBarDuringPresentation = false
        addressSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        addressSearchTable.mapView = addressMapView
        addressSearchTable.searchHandlerDelegate = self
        addressMapView.delegate = self
    }
    
    fileprivate func setupViewLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestAlwaysAuthorization()
        locationManager.requestLocation()
    }
    
    @IBAction func zoomToUserLocation(_ sender: Any) {
        let userLocation = locationManager.location?.coordinate
        let zoomWidth = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let viewRegion = MKCoordinateRegion(center: userLocation!, span: zoomWidth)
        addressMapView.setRegion(viewRegion, animated: true)
    }
    
    func initializeMapAtUserLocation() {
        let userLocation = locationManager.location?.coordinate
        let zoomWidth = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let viewRegion = MKCoordinateRegion(center: userLocation!, span: zoomWidth)
        addressMapView.setRegion(viewRegion, animated: true)
    }
    
    func initializeMapAtStoredLocation() {
        if DataStore.sharedInstance.currentlySettingAddresses == true {
            previousLocation = DataStore.sharedInstance.currentUser?.addresses![DataStore.sharedInstance.selectedAddressInSettings!]
        } else if DataStore.sharedInstance.currentlySettingAddresses == false {
            previousLocation = DataStore.sharedInstance.currentUser?.locations![DataStore.sharedInstance.selectedLocationInSettings!]
            let zoomWidth = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let viewRegion = MKCoordinateRegion(center: previousLocation!, span: zoomWidth)
        addressMapView.setRegion(viewRegion, animated: true)
    }
    }
        
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//        print("Moved map.")
        if DataStore.sharedInstance.currentlySettingAddresses == false {
            DataStore.sharedInstance.currentUser?.locations![DataStore.sharedInstance.selectedLocationInSettings!] = mapView.centerCoordinate
            geocodeMapLocation(center: mapView.centerCoordinate)
        }
    }
    
    fileprivate func geocodeMapLocation(center: CLLocationCoordinate2D) {
        let convertedLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let geocoder = CLGeocoder()
        
        // Look up the location and pass it to the completion handler
        geocoder.reverseGeocodeLocation(convertedLocation) { (placemarks, error) in
            if error == nil {
                let firstLocation = placemarks?[0]
//                print(firstLocation?.subLocality)
                
                if firstLocation?.subLocality != nil {
                    DataStore.sharedInstance.currentUser?.locationNames![DataStore.sharedInstance.selectedLocationInSettings!] = "Near \(firstLocation?.subLocality! ?? "someplace")"
                } else if firstLocation?.thoroughfare != nil {
                    DataStore.sharedInstance.currentUser?.locationNames![DataStore.sharedInstance.selectedLocationInSettings!] = "Near \(firstLocation?.thoroughfare! ?? "someplace")"
                } else if firstLocation?.subAdministrativeArea != nil {
                    DataStore.sharedInstance.currentUser?.locationNames![DataStore.sharedInstance.selectedLocationInSettings!] = "Near \(firstLocation?.subAdministrativeArea! ?? "someplace")"
                } else {
                    DataStore.sharedInstance.currentUser?.locationNames![DataStore.sharedInstance.selectedLocationInSettings!] = "Unknown Location"
                }
            }
            
        }
        
    }
}

extension AddressViewController : CLLocationManagerDelegate {
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            locationManager.requestLocation()
        }
        else if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}

