//
//  PricePickerTableViewCell.swift
//  faer
//
//  Created by pluto on 13.07.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

protocol PricePickerTableViewCellDelegate: class {
    func didPick(_ pickerCell: PricePickerTableViewCell, componentValue: String, priceValue: Double)
}

class PricePickerTableViewCell: UITableViewCell {
    
    weak var delegate: PricePickerTableViewCellDelegate?
    
    var priceInfoIdentifier: String? // the price info the picker belongs to
    
    
    static let cellIdentifier: String = "pricePicker"
    
    var list: ItemList!
        
    private var pickerDataSource: PricePickerRange?
    
    private var picker: UIPickerView?
    
    private let pickerTag: Int = 5 //set in IB accordingly
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.picker = self.viewWithTag(self.pickerTag) as? UIPickerView
        self.picker?.dataSource = self
        self.picker?.delegate = self

    }
    
    func updateRangeIfNeeded(settings: ItemListSettings) {
        self.pickerDataSource = PricePickerRange()
        self.picker?.reloadAllComponents()

        if self.priceInfoIdentifier == PriceInfoTableViewCell.lowestPriceReuseIdentifier {
            self.pickerDataSource = PricePickerRange(endPrice: settings.price.upperBound)
            self.picker?.reloadAllComponents()
            self.pick(settings.price.lowerBound)
        }
        
        if self.priceInfoIdentifier == PriceInfoTableViewCell.highestPriceReuseIdentifier {
            self.pickerDataSource = PricePickerRange(startPrice: settings.price.lowerBound)
            self.picker?.reloadAllComponents()
           self.pick(settings.price.upperBound)
        }
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func pick(_ price: Int) {

        self.picker?.selectRow(self.pickerDataSource!.rowFor(price), inComponent: 0, animated: false)
        self.picker?.reloadAllComponents()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.priceInfoIdentifier = nil
        self.pickerDataSource = nil
    }
    
}

extension PricePickerTableViewCell: UIPickerViewDelegate {
    
    
}

extension PricePickerTableViewCell: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerDataSource?.count ?? 0
    }
    
    private func makePickerLabel(reuseView: UIView?, row: Int, text: String) -> UIView {
        
        let pickerLabel: UILabel = reuseView == nil ? UILabel() : (reuseView as! UILabel) // reuse label
        let myAttributes:[NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.darkText,
            NSAttributedString.Key.font : UIFont(name: StyleGuide.fontSemiBold, size: StyleGuide.fontHeadlineSize)!
        ]
        
        pickerLabel.textAlignment = .center
        pickerLabel.attributedText = NSAttributedString(string: text, attributes: myAttributes)
        return pickerLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        return self.makePickerLabel(reuseView: view, row: row, text: self.pickerDataSource!.labelFor(row: row))
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        self.delegate?.didPick(self, componentValue: self.pickerDataSource!.labelFor(row: row), priceValue: Double(self.pickerDataSource!.priceFor(row)))
    }
    
}
