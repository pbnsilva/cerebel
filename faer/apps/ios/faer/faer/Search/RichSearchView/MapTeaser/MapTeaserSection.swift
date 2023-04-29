//
//  BrandSpotlightSection.swift
//  faer
//
//  Created by pluto on 31.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit



class MapTeaserSection: RichSection {
    
    var dataSource: [Store]?
    
    private static let mapTeaserCacheKey: String = "mapTeaserCacheKey"
    
    private lazy var locationManager: CLLocationManager = CLLocationManager()
    
    private var isRefreshingBackground: Bool = false
    
    var isRefreshing: Bool = false
    
    convenience init(name: String = "Shops around you", parent: UICollectionView?) {
        self.init(name: name, cellNibName: MapTeaserCollectionViewCell.nibName, cellReuseIdentifier: MapTeaserCollectionViewCell.reuseIdentifier, parent: parent)
        self.totalItems = 1
        NotificationCenter.default.addObserver(self, selector: #selector(backgroundMake), name: .userLocationUpdated, object: nil)
    }
    
    
    convenience init(parent: UICollectionView?, json: [String: Any]) throws {
        
        guard
            let name = json["name"] as? String
            else {
                throw SerializationError.missing("Failed to nserialize MapTeaserSection json: name or items missing")
        }
        
        self.init(name: name, parent: parent)

        // get stores

        guard let teaserItems = json["items"] as? [[String: Any]] else {
            return
        }
        
        self.dataSource = teaserItems.compactMap { return Store(json: $0) }
    }
    
    
    convenience init(parent: UICollectionView?, stores: [Store]) {
        self.init(parent: parent)
        self.dataSource = stores
    }

    //MARK: NSCoding
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(self.dataSource, forKey: PropertyKey.stores)
        aCoder.encode(self.isRefreshing, forKey: PropertyKey.isRefreshing)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard
            let stores = aDecoder.decodeObject(forKey: PropertyKey.stores) as? [Store],
            let isRefreshing = aDecoder.decodeObject(forKey: PropertyKey.isRefreshing) as? Bool

        else {
            return nil
        }
        self.init(parent: aDecoder.decodeObject(forKey: PropertyKey.parent) as? UICollectionView, stores: stores)
        self.isRefreshing = isRefreshing
    }
    
    struct PropertyKey {
        static let stores = "stores"
        static let isRefreshing = "isRefreshing"
    }

    // Implementation
    
    override func sizeForItem(minimumInteritemSpacing: CGFloat = 10, maxSize: CGSize) -> CGSize {
        return CGSize(width: maxSize.width, height: maxSize.height / 3)
    }
    
    private func handleTapOnSection() {
        // To be override by subclasses
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            
            let refreshAlert = UIAlertController(title: "Open settings", message: "Enable location for Faer in your settings.", preferredStyle: UIAlertController.Style.alert)
            
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            
            self.parent?.parentViewController?.present(refreshAlert, animated: true, completion: {
            })
            
            break
            
        case .authorizedWhenInUse, .authorizedAlways:
            //TODO handle if no store around
            parent?.parentViewController?.performSegue(withIdentifier: CommonSegues.map.rawValue, sender: self.dataSource)
        }
    }
    
    override func segue(at indexPath: IndexPath) {
        self.handleTapOnSection()
    }
    
    private func initialLocation() -> MKCoordinateRegion? {
        
        guard let location = User.shared.lastLocation else {
            return nil
        }
        
        return MKCoordinateRegion(center: location.coordinate,
                                  latitudinalMeters: 10000, longitudinalMeters: 10000) // show area of 10km around current location
        
    }
    
    @objc
    private func backgroundMake() {
        self.makeBackground(nil)
    }
    
    @objc
    private func makeBackground(_ completion: ((UIImage?)->())?) {
        guard
            let fileURL = self.backgroundImageURL(),
            !self.isRefreshingBackground
        else {
                return
        }
        
        self.isRefreshingBackground = true
        
        let mapSnapshotOptions = MKMapSnapshotter.Options()
        
        // Set the region of the map that is rendered.
        
        if let initialRegion = self.initialLocation() {
            mapSnapshotOptions.region = initialRegion
        }
        
        mapSnapshotOptions.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 3)
        
        if #available(iOS 11.0, *) {
            mapSnapshotOptions.mapType = .mutedStandard
        }
        
        let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)
        
        DispatchQueue.global(qos: .background).async {
            snapShotter.start { (snapshot, error) in
                if
                    let snap = snapshot,
                    let data: Data = snap.image.jpegData(compressionQuality: 0.6) {
                    try? data.write(to: fileURL)
                }
                
                completion?(snapshot?.image)
                self.isRefreshingBackground = false
            }
        }
    }
    
    //
    private func getBackground(completion: @escaping (UIImage?) -> Void) {
        
        guard let url = self.backgroundImageURL(), let data = try? Data(contentsOf: url) else {
            
            self.makeBackground { (image) in
                completion(image)
            }
            
            return
        }
        
        completion(UIImage(data: data))

    }
    
    private func backgroundImageURL() -> URL? {
        
        let name: String = "mapTeaserBackgroundImage"
        
        return try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(name)
        
    }

    override func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        
        let cell: MapTeaserCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: self.itemCell.reuseIdentifier, for: indexPath) as! MapTeaserCollectionViewCell
        cell.delegate = self
        self.getBackground { (image) in
            cell.imageView.image = image
        }
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            
            cell.configure(stores: self.dataSource)
            
            return cell

        default:
            cell.configureNoPermissions()
        }
        
        return cell
    }
    
}

extension MapTeaserSection: MapTeaserCollectionViewCellDelegate {
    
    func hideMapTapped(cell: MapTeaserCollectionViewCell) {
        
        self.delegate?.hideMap?(requestBy: self)
        
    }
    
}
