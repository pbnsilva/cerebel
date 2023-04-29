//
//  SettingsTableViewController.swift
//  faer
//
//  Created by pluto on 15.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    private struct Sections { // must match the order of the static content in IB
        static let gender: Int = 1
        static let preferredLocale: Int = 2
        static let notifications: Int = 3
        static let about: Int = 0
    }
    @IBOutlet weak var wishlistProductOnSaleSwitch: UISwitch!
    
    @IBAction func wishlistItemOnSaleSwitched(_ sender: Any) {

        guard let notificationSwitch = sender as? UISwitch else { return }
        
        AppNotifications.shared.authorizationStatus { (status) in
            DispatchQueue.main.async {
                switch status {
                case .denied:
                    if notificationSwitch.isOn {
                        let refreshAlert = UIAlertController(title: "Sale notifications", message: "Enable notifications for Faer in your settings to get sale alerts.", preferredStyle: UIAlertController.Style.alert)
                        
                        refreshAlert.addAction(UIAlertAction(title: "Open settings", style: .default, handler: { (action: UIAlertAction!) in
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }))
                        
                        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                        }))
                        
                        self.present(refreshAlert, animated: true, completion: nil)
                    }
                case .notDetermined:
                    AppNotifications.shared.askForPermission()
                default:
                    break;
                }
            }
        }

        User.shared.notificationPermissions?.wishlistProductOnSale = notificationSwitch.isOn
    }
    
    private lazy var selectedRows: [Int: Int] = [:] // section : row
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureSelectedRows()
        
        // configure notification permissions
        
        self.wishlistProductOnSaleSwitch?.setOn((User.shared.notificationPermissions?.wishlistProductOnSale ?? false), animated: false)
        
        self.setNeedsStatusBarAppearanceUpdate()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    private func configureSelectedRows() {
        self.selectedRows.removeAll()
        // gender
        switch User.shared.gender {
        case .female:
            self.selectedRows[Sections.gender] = 0
        case .male:
            self.selectedRows[Sections.gender] = 1
        case .all:
            self.selectedRows[Sections.gender] = 2
        default:
            self.selectedRows[Sections.gender] = 0
        }
        // locale
        switch User.shared.preferredLocale.identifier {
        case "de_DE":
            self.selectedRows[Sections.preferredLocale] = 1
        case "en_US":
            self.selectedRows[Sections.preferredLocale] = 2
        case "en_GB":
            self.selectedRows[Sections.preferredLocale] = 3
        case "da_DK":
            self.selectedRows[Sections.preferredLocale] = 4
        default:
            self.selectedRows[Sections.preferredLocale] = 1
        }
    }
    
    func hasCheckmark(_ indexPath: IndexPath) -> Bool {
        
        if indexPath.section == Sections.about {
            return false
        }
        
        if indexPath.section == Sections.notifications {
            return false
        }
        
        if indexPath.section == Sections.preferredLocale && indexPath.row == 0 {
            return false
        }
        
        return true
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let _ = self.selectedRows[indexPath.section], indexPath.row == self.selectedRows[indexPath.section] {
            cell.accessoryType = .checkmark
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        guard self.hasCheckmark(indexPath) else { return indexPath }
        
        let section = indexPath.section
        let numberOfRows = tableView.numberOfRows(inSection: section)
        for row in 0..<numberOfRows {
            if let cell = tableView.cellForRow(at: IndexPath(row: row, section: section)) {
                cell.accessoryType = row == indexPath.row ? .checkmark : .none
                cell.textLabel?.backgroundColor = UIColor.clear
            }
        }
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.hasCheckmark(indexPath) {
            self.configureSelectedRows()
        }
        
        switch indexPath.section {
        case Sections.gender:
            switch indexPath.row {
            case 0:
                User.shared.gender = .female
            case 1:
                User.shared.gender = .male
            case 2:
                User.shared.gender = .all
            default:
                break;
            }
        case Sections.preferredLocale:
            switch indexPath.row {
            case 0:
                // info only
                break;
            case 1:
                User.shared.preferredLocale = Locale(identifier: "de_DE") // using Germany as proxy for EUR
            case 2:
                User.shared.preferredLocale = Locale(identifier: "en_US")
            case 3:
                User.shared.preferredLocale = Locale(identifier: "en_GB")
            case 4:
                User.shared.preferredLocale = Locale(identifier: "da_DK")
            default:
                User.shared.preferredLocale = Locale(identifier: "de_DE") // using Germany as proxy for EUR
            }
        case Sections.notifications:
            break;
        case Sections.about:
            switch indexPath.row {
            case 0:
                UIApplication.shared.open(URL(string: "http://www.wearefaer.com")!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            default:
                break;
            }
        default:
            break;
        }
        User.shared.save()
        self.tableView?.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.destination is SurveyViewController {
            (segue.destination as! SurveyViewController).presentingFromSettings = true
        }
    }
 
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
