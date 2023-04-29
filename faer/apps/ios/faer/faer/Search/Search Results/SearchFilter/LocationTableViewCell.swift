//
//  LocationTableViewCell.swift
//  faer
//
//  Created by venus on 19.07.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import CoreLocation


protocol LocationTableViewCellDelegate :class {
    func locationSwitchTapped(isEnabled: Bool)
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if parentResponder is UIViewController {
                return (parentResponder as! UIViewController)
            }
        }
        return nil
    }
}

class LocationTableViewCell: UITableViewCell {
    
    static let reuseIdentifier: String = "LocationTableViewCellIdentifier"

    private let locationManager = CLLocationManager()
    
    private let switchTag: Int = 5

    var locationSwitch: UISwitch!

    weak var delegate: LocationTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.locationSwitch = self.viewWithTag(switchTag) as? UISwitch
        
        self.locationSwitch.addTarget(self, action: #selector(locationSwitchTapped(_:)), for: .allEvents)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc
    func locationSwitchTapped(_ sender: UISwitch) {
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            self.locationManager.requestWhenInUseAuthorization()
            self.locationSwitch.isOn = false
            break
            
        case .restricted, .denied:
            
            let refreshAlert = UIAlertController(title: "Open settings", message: "Enable location for Faer in your settings.", preferredStyle: UIAlertController.Style.alert)
            
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            
            self.parentViewController?.present(refreshAlert, animated: true, completion: {
                self.locationSwitch.isOn = false
            })
            
            break
            
        case .authorizedWhenInUse, .authorizedAlways:
            self.delegate?.locationSwitchTapped(isEnabled: self.locationSwitch.isOn)
            break
        }
    }

}
