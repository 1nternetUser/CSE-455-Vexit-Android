//
//  MapViewController.swift
//  VEXTit Drop

import UIKit
import CoreLocation
import MapKit

class MapViewController: UIViewController {
    
    static let sharedInstance = MapViewController()
    
    let locationManager = CLLocationManager()
    @IBOutlet weak var simpleMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        simpleMapView.delegate = self
        setupViewLocationManager()
        initializeMapAtUserLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
//            
//        })
        self.drawAllDrops()
    }
    
    func drawSingleDrop(drop: Drop) {
        let dropCircle = MultiColorCircleOverlay(center: drop.centerCoordinate, radius: drop.dropRadius)
        if drop.sender == DataStore.sharedInstance.currentUser?.userId {
            dropCircle.colorChoiceTag = 1
        }
        simpleMapView?.addOverlay(dropCircle)
        let dropPopup = MultiColorPointAnnotation()
        if drop.sender == DataStore.sharedInstance.currentUser?.userId {
            dropPopup.colorChoiceTag = 1
        }
        if drop.sender == DataStore.sharedInstance.currentUser?.userId {
            let contactsListRecipientIndex = DataStore.sharedInstance.contactsList.index(where: {$0.userId == drop.recipient})
            dropPopup.title = "Your drop to \(DataStore.sharedInstance.contactsList[contactsListRecipientIndex!].name!)"
            if DataStore.sharedInstance.contactsList[contactsListRecipientIndex!].userPicture != nil {
                dropPopup.userPicture = (DataStore.sharedInstance.contactsList[contactsListRecipientIndex!].userPicture)!
            }
        } else if drop.sender != DataStore.sharedInstance.currentUser?.userId {
            let contactsListSenderIndex = DataStore.sharedInstance.contactsList.index(where: {$0.userId == drop.sender})
            dropPopup.title = "Your drop from \(DataStore.sharedInstance.contactsList[contactsListSenderIndex!].name!)"
        }
        dropPopup.coordinate = drop.centerCoordinate
        simpleMapView.addAnnotation(dropPopup)
    }
    
    func drawAllDrops() {
        for drop in DataStore.sharedInstance.dropsFromOthers {
            drawSingleDrop(drop: drop)
        }
        for drop in DataStore.sharedInstance.dropsForOthers {
            if drop.isPrivate == false {
                drawSingleDrop(drop: drop)
            }
        }
    }
    
    fileprivate func setupViewLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func zoomToUserLocation(_ sender: Any) {
        let userLocation = locationManager.location?.coordinate
        let zoomWidth = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let viewRegion = MKCoordinateRegion(center: userLocation!, span: zoomWidth)
        simpleMapView.setRegion(viewRegion, animated: true)
    }
    
    func initializeMapAtUserLocation() {
        let userLocation = locationManager.location?.coordinate
        let zoomWidth = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let viewRegion = MKCoordinateRegion(center: userLocation!, span: zoomWidth)
        simpleMapView.setRegion(viewRegion, animated: true)
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


extension MapViewController : CLLocationManagerDelegate {
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // print("There was an error somewhere: \(error)")
    }
}


extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let dropOverlay = MKCircleRenderer(overlay: overlay)
            let dropCircle = overlay as! MultiColorCircleOverlay
            dropOverlay.lineWidth = 1.5
            
            if dropCircle.colorChoiceTag == 1 {
                dropOverlay.strokeColor = UIColor(red: 0.0/255.0, green: 150.0/255.0, blue: 255.0/255.0, alpha: 0.6)
                dropOverlay.fillColor = UIColor(red: 0.0/255.0, green: 150.0/255.0, blue: 255.0/255.0, alpha: 0.2)
            } else {
                dropOverlay.strokeColor = UIColor(red: 255.0/255.0, green: 138.0/255.0, blue: 216.0/255.0, alpha: 0.6)
                dropOverlay.fillColor = UIColor(red: 255.0/255.0, green: 138.0/255.0, blue: 216.0/255.0, alpha: 0.2)
            }
            
            return dropOverlay
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView!, viewFor annotation: MKAnnotation!) -> MKAnnotationView! {
        if annotation is MKPointAnnotation {
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
            let pinAnnotation = annotation as! MultiColorPointAnnotation
            
            if pinAnnotation.colorChoiceTag == 1 {
                pinAnnotationView.pinTintColor = UIColor(red: 0.0/255.0, green: 150.0/255.0, blue: 255.0/255.0, alpha: 0.6)
            } else {
                pinAnnotationView.pinTintColor = UIColor(red: 255.0/255.0, green: 138.0/255.0, blue: 216.0/255.0, alpha: 0.6)
            }
            pinAnnotationView.canShowCallout = true
            var userImageCallout = UIImageView(frame: CGRect(x: 0, y: 0, width: 53, height: 53))
            userImageCallout.image = pinAnnotation.userPicture
            pinAnnotationView.leftCalloutAccessoryView = userImageCallout
            
            pinAnnotationView.isDraggable = false
            
            pinAnnotationView.animatesDrop = true
            return pinAnnotationView
        }
        return nil
    }
}
