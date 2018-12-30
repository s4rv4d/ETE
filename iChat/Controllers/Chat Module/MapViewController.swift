//
//  MapViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 12/26/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    //MARK: - Location
    var location:CLLocation!
    
    //MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Map"
        
        SetupUI()
        CreateRightButton()
    }
    
    //MARK: - Setup UI
    func SetupUI(){
        var region = MKCoordinateRegion()
        region.center.longitude = location.coordinate.longitude
        region.center.latitude = location.coordinate.latitude
        
        region.span.latitudeDelta = 0.01
        region.span.longitudeDelta = 0.01
        
        //false so that it doesnt zoom into the place but just show it, true for the vice versa
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
        
        //to drop a pin on the map
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        mapView.addAnnotation(annotation)
    }

    //MARK: - Open in Maps app
    func CreateRightButton(){
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Open in Maps", style: .plain, target: self, action: #selector(self.OpenInMap))]
    }
    
    @objc func OpenInMap(){
        //setup for map app
        let regionDestination:CLLocationDistance = 10000
        let coordinates = location.coordinate
        //latitudinal and longitudinal meters is the amount of distance from current point
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDestination, longitudinalMeters: regionDestination)
        let options = [
            MKLaunchOptionsMapCenterKey:NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey:NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "User's location"
        mapItem.openInMaps(launchOptions: options)
    }

}
