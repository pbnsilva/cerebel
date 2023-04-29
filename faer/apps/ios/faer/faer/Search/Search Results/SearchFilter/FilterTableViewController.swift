//
//  FilterTableViewController
//  Faer
//
//  Created by pluto on 20.07.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

protocol FilterTableViewControllerDelegate :class {
    func didUpdate(settings: ItemListSettings)
    func asksForDismiss()
}

class FilterTableViewController: UITableViewController {
    
    static let storyboardName: String = "FilterTableViewStoryboard"
    
    private let contentSizeKeyPath: String = "contentSize"
    
    private let preferredSectionHeaderHeight: CGFloat = 50
    
    private var presentedSection: Int = 2 // Default open Sort by 
    
    private let noSelection: Int = -1
    
    var settings: ItemListSettings! // source for current settings
    
    weak var delegate: FilterTableViewControllerDelegate?
    
    private var panStartLocation: CGFloat?
    
    private var dataSource: [Int: [String]] = [
        0: [LocationTableViewCell.reuseIdentifier],
        1: [PriceDoublePickerTableViewCell.cellIdentifier],
        2: [ItemListSettings.sortingType.relevance.rawValue, ItemListSettings.sortingType.priceHighToLow.rawValue, ItemListSettings.sortingType.priceLowToHigh.rawValue]
    ]
    
    private let sectionTitles: [Int : String] = [
        0: "Location",
        1: "Price",
        2: "Sort by"
    ]
    
    private var sectionHeader: UITableViewHeaderFooterView = UITableViewHeaderFooterView(reuseIdentifier: "sectionHeaderIdentifier")
    private var sectionHeaderIdentifier: String = "sectionHeaderIdentifier"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 50
        
        tableView.estimatedSectionFooterHeight = self.preferredSectionHeaderHeight // setting UITableViewAutomaticDimension fails in 10.x
        
        self.configureDismissal()
        
        self.tableView.addObserver(self, forKeyPath: self.contentSizeKeyPath, options: .new, context: nil)
                
        tableView.transform = CGAffineTransform(rotationAngle: (-.pi)) // flip tableView to start animations from bottom, reverse data source!
        
    }
    
    private func configureDismissal() {
        let footerView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 14))
        footerView.backgroundColor = .white

        let blackLatch: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 4))
        blackLatch.backgroundColor = .black
        blackLatch.layer.cornerRadius = 2
        blackLatch.layer.masksToBounds = true
        blackLatch.center = footerView.convert(footerView.center, from: footerView.superview)

        footerView.addSubview(blackLatch)

        
        let tap = UITapGestureRecognizer(target: self, action: #selector(FilterTableViewController.tapHandler))
        footerView.addGestureRecognizer(tap)
        blackLatch.addGestureRecognizer(tap)
        
        tableView.tableFooterView = footerView

        // handle swip down dismiss
        let pan = UIPanGestureRecognizer(target: self, action: #selector(FilterTableViewController.panHandler))
        self.view.addGestureRecognizer(pan)
    }
    
    @objc
    private func tapHandler(recognizer: UIPanGestureRecognizer) {
        self.delegate?.asksForDismiss()
    }
    
    @objc
    private func panHandler(recognizer: UIPanGestureRecognizer) {
        
        switch recognizer.state {
        case .began:
            self.panStartLocation = recognizer.location(in: self.view).y
        case .ended:
            guard
                let startLocation = self.panStartLocation
            else {
                break
            }
            
            let distancePanned: CGFloat = recognizer.location(in: self.view).y - startLocation
            if distancePanned < -100 {
                self.delegate?.asksForDismiss()
            }
            
        default:
            break;
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let view = object as? UITableView, view == self.tableView, keyPath == self.contentSizeKeyPath , let _ = change?[NSKeyValueChangeKey.newKey] as? CGSize else {
            return
        }
        self.preferredContentSize = self.tableView.contentSize
    }
    
    deinit {
        self.tableView.removeObserver(self, forKeyPath: self.contentSizeKeyPath)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: FilterSectionHeader.reuseIdentifier) as? FilterSectionHeader ?? FilterSectionHeader(reuseIdentifier: FilterSectionHeader.reuseIdentifier)
        
        header.setTitle(text: self.sectionTitles[section]!, preferredHeight: self.preferredSectionHeaderHeight)
        
        header.delegate = self
        
        header.tag = section
        
        if section == self.presentedSection {
            header.isSelected = true
        } else {
            header.isSelected = false
        }
        
        header.transform = CGAffineTransform(rotationAngle: (-.pi))
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return self.preferredSectionHeaderHeight
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == self.presentedSection ? self.dataSource[section]!.count : 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifierFor(indexPath), for: indexPath)
        
        // update price info if needed
        if let _ = cell as? PriceInfoTableViewCell {
            if self.cellIdentifierFor(indexPath) == PriceInfoTableViewCell.lowestPriceReuseIdentifier {
                (cell as! PriceInfoTableViewCell).priceInfo?.text = PricePickerRange().labelFor(price: self.settings.price.lowerBound)
            }
            if self.cellIdentifierFor(indexPath) == PriceInfoTableViewCell.highestPriceReuseIdentifier {
                (cell as! PriceInfoTableViewCell).priceInfo?.text = PricePickerRange().labelFor(price: self.settings.price.upperBound)
            }
        }
        
        // update price picker range
        if let _ = cell as? PriceDoublePickerTableViewCell {
            (cell as! PriceDoublePickerTableViewCell).priceInfoIdentifier = self.cellIdentifierFor(section: indexPath.section, row: indexPath.row) // or -1 for transformed table
            (cell as! PriceDoublePickerTableViewCell).delegate = self
            (cell as! PriceDoublePickerTableViewCell).updateRangeIfNeeded(settings: self.settings)
        }

        // update location
        if let _ = cell as? LocationTableViewCell {
            (cell as! LocationTableViewCell).locationSwitch.isOn = self.settings.locationEnabled
            (cell as! LocationTableViewCell).delegate = self
        }
        
        // done
        cell.transform = CGAffineTransform(rotationAngle: (-.pi))

        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // set cell checkmark if needed for sorting sections
       if self.cellIdentifierFor(indexPath) == self.settings.sorting.rawValue {
            self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }

    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let cell = self.tableView.cellForRow(at: indexPath) else {
            return indexPath
        }
        
        switch cell {
        case is SortOptionsTableViewCell:
            guard !cell.isSelected else { break }
            self.settings.sorting = ItemListSettings.sortingType(rawValue: cell.reuseIdentifier!)!
            self.delegate?.didUpdate(settings: self.settings)
            break
        default:
            break
        }
        
        return indexPath
    }

    // MARK: - Table view delegate
        
    // Helper
    
    private func cellIdentifierFor(section: Int, row: Int) -> String {
        return dataSource[section]![row]
    }
    
    private func cellIdentifierFor(_ path: IndexPath) -> String {
        return self.cellIdentifierFor(section: path.section, row: path.row)
    }
}

extension FilterTableViewController: FilterSectionHeaderDelegate {
    
    func didSwipe(header: FilterSectionHeader) {
        print("did swipe")
    }
    
    func didTap(header: FilterSectionHeader) {
        
        if header.tag == self.presentedSection {
            // one section open, close it
            self.presentedSection = self.noSelection
        } else {
            self.presentedSection = header.tag
        }
        self.tableView.reloadSections(IndexSet(Array(self.dataSource.keys)), with: .automatic)
        
    }
}

extension FilterTableViewController: PriceDoublePickerTableViewCellDelegate {
    
    func didPick(_ pickerCell: PriceDoublePickerTableViewCell, lowerBound: Int, componentValue: String) {
        self.settings.price = lowerBound..<self.settings.price.upperBound
        pickerCell.updateRangeIfNeeded(settings: self.settings)
        self.delegate?.didUpdate(settings: self.settings)
    }
    
    func didPick(_ pickerCell: PriceDoublePickerTableViewCell, upperBound: Int, componentValue: String) {
        self.settings.price = self.settings.price.lowerBound..<upperBound
        pickerCell.updateRangeIfNeeded(settings: self.settings)
        self.delegate?.didUpdate(settings: self.settings)
    }

    
}

extension FilterTableViewController: LocationTableViewCellDelegate {
    
    func locationSwitchTapped(isEnabled: Bool) {
        self.settings.locationEnabled = isEnabled
        self.delegate?.didUpdate(settings: self.settings)
    }
}

extension FilterTableViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
}

