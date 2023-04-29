//
//  MapViewViewController.swift
//  faer
//
//  Created by pluto on 18.04.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class MapViewController: UIViewController {

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
        
    @IBOutlet weak var mapKitView: MKMapView!
    
    var stores: [Store]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapKitView.delegate = self
        
         self.setupMapKitView()

    }
    
    private func setupMapKitView() {
        
        self.registerAnnotations()
        
        let storeAnnotations: [StoreAnnotation] = stores?.map { StoreAnnotation(store: $0) } ?? []
        self.mapKitView.addAnnotations(storeAnnotations)
        
        self.centerMapOnLocation(location: User.shared.lastLocation)

    }
    
    private func registerAnnotations() {
        if #available(iOS 11.0, *) {
            self.mapKitView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(StoreAnnotation.self))
        }
    }
    
    
    private func centerMapOnLocation(location: CLLocation?) {
        
        let initialLocation: CLLocation
        let regionRadius: CLLocationDistance
        
        if let _ = location {
            initialLocation = location!
            regionRadius = 50000
        } else {
            initialLocation = CLLocation(latitude: 10.6476053, longitude: -33.136415)
            regionRadius = 1000000
        }
        
        let coordinateRegion = MKCoordinateRegion(center: initialLocation.coordinate,
                                                  latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        
        mapKitView.setRegion(coordinateRegion, animated: true)
        
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - CLLocationManagerDelegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
       // print("did tap marker")
    }
    
    /// Called whent he user taps the disclosure button in the bridge callout.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let annotation = view.annotation as? StoreAnnotation {
            
            guard let url: URL = URL(string:"https://www.google.com/maps/dir/?api=1&destination=\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)") else {
                return
            }
            if (UIApplication.shared.canOpenURL(url)) {
                UIApplication.shared.open(url, options: [:]) { (success) in
                }
            } else {
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: annotation.coordinate, addressDictionary: nil))
                mapItem.name = annotation.title
                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let storeAnnotation = annotation as? StoreAnnotation, !annotation.isKind(of: MKUserLocation.self) else {
            // Make a fast exit if the annotation is the `MKUserLocation`, as it's not an annotation view we wish to customize.
            return nil
        }
        
        var annotationView: MKAnnotationView?
        
        if #available(iOS 11.0, *) {
            annotationView = setupMarker(for: storeAnnotation, on: mapView)
        } else {
            annotationView = setupLegacyMarker(for: storeAnnotation, on: mapView)
        }
        
        return annotationView
        
    }
    
    private func setupLegacyMarker(for annotation: StoreAnnotation, on mapView: MKMapView) -> MKAnnotationView? {
        
        let reuseIdentifier = NSStringFromClass(StoreAnnotation.self)
        
        var annotationView: MKAnnotationView?
        
        if let dequedView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) {
            annotationView = dequedView
        } else{
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        }
        
        annotationView?.image = UIImage(named: "map-marker-store")
        
        annotationView?.canShowCallout = true
        let imageView: UIImageView = UIImageView(image: UIImage(named: "map-directions"))
        let button: UIControl = UIControl(frame: imageView.frame)
        button.addSubview(imageView)
        annotationView?.rightCalloutAccessoryView = button
        
        return annotationView
        
    }
    
    @available(iOS 11.0, *)
    private func setupMarker(for annotation: StoreAnnotation, on mapView: MKMapView) -> MKAnnotationView? {
        
        let reuseIdentifier = NSStringFromClass(StoreAnnotation.self)
        
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier, for: annotation)
        
        if let markerAnnotationView = view as? MKMarkerAnnotationView {
            markerAnnotationView.glyphTintColor = .black
            markerAnnotationView.glyphImage = UIImage(named: "map-marker-dot")
            markerAnnotationView.markerTintColor = .white
            markerAnnotationView.displayPriority = .required
            markerAnnotationView.titleVisibility = .visible
            
            markerAnnotationView.animatesWhenAdded = true
            markerAnnotationView.canShowCallout = true
            
            let imageView: UIImageView = UIImageView(image: UIImage(named: "map-directions"))
            let button: UIControl = UIControl(frame: imageView.frame)
            button.addSubview(imageView)
            markerAnnotationView.rightCalloutAccessoryView = button
        }
        
        return view
        
    }
}
