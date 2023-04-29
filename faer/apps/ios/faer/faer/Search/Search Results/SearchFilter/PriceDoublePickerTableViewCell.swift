//
//  PricePickerTableViewCell.swift
//  faer
//
//  Created by pluto on 13.07.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

protocol PriceDoublePickerTableViewCellDelegate: class {
    func didPick(_ pickerCell: PriceDoublePickerTableViewCell, lowerBound: Int, componentValue: String)
    func didPick(_ pickerCell: PriceDoublePickerTableViewCell, upperBound: Int, componentValue: String)
}

class PriceDoublePickerTableViewCell: UITableViewCell {
    
    weak var delegate: PriceDoublePickerTableViewCellDelegate?
    
    var priceInfoIdentifier: String? // the price info the picker belongs to
    
    static let cellIdentifier: String = "priceDoublePicker"
    
    var list: ItemList!
        
    
    private var pickerLeft: UIPickerView?
    private var pickerLeftDataSource: PricePickerRange?
    private let pickerLeftTag: Int = 5 //set in IB accordingly
    
    private var pickerRight: UIPickerView?
    private var pickerRightDataSource: PricePickerRange?
    private let pickerRightTag: Int = 6 //set in IB accordingly
    
    private func setupPickers() {
        // lowest
        self.pickerLeft = self.viewWithTag(self.pickerLeftTag) as? UIPickerView
        self.pickerLeft?.dataSource = self
        self.pickerLeft?.delegate = self
        self.pickerLeftDataSource = PricePickerRange()
        self.pickerLeft?.reloadAllComponents()

        // highest
        self.pickerRight = self.viewWithTag(self.pickerRightTag) as? UIPickerView
        self.pickerRight?.dataSource = self
        self.pickerRight?.delegate = self
        self.pickerRightDataSource = PricePickerRange()
        self.pickerRight?.reloadAllComponents()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setupPickers()
    }
    
    func updateRangeIfNeeded(settings: ItemListSettings) {
                
        // left = lowest
        self.pickerLeftDataSource = PriceLowerPicker(endPrice: settings.price.upperBound)
        self.pickerLeft?.reloadAllComponents()
        self.pickerLeft?.selectRow(self.pickerLeftDataSource!.rowFor(settings.price.lowerBound), inComponent: 0, animated: false)

        // right = highes
        self.pickerRightDataSource = PricePickerRange(startPrice: settings.price.lowerBound)
        self.pickerRight?.reloadAllComponents()
        self.pickerRight?.selectRow(self.pickerRightDataSource!.rowFor(settings.price.upperBound), inComponent: 0, animated: false)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.priceInfoIdentifier = nil
        self.pickerRightDataSource = nil
        self.pickerLeftDataSource = nil
    }
    
}

extension PriceDoublePickerTableViewCell: UIPickerViewDelegate {
    
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        if pickerView.tag == self.pickerLeftTag {
            return self.makePickerLabel(reuseView: view, row: row, text: self.pickerLeftDataSource!.labelFor(row: row))
        }
        if pickerView.tag == self.pickerRightTag {
            return self.makePickerLabel(reuseView: view, row: row, text: self.pickerRightDataSource!.labelFor(row: row))
        }
        return UIView()
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        
        if pickerView.tag == self.pickerLeftTag {
            self.delegate?.didPick(self, lowerBound: self.pickerLeftDataSource!.priceFor(row), componentValue: self.pickerLeftDataSource!.labelFor(row: row))
        }
        if pickerView.tag == self.pickerRightTag {
            self.delegate?.didPick(self, upperBound: self.pickerRightDataSource!.priceFor(row), componentValue: self.pickerRightDataSource!.labelFor(row: row))
        }
        
    }
    
}


extension PriceDoublePickerTableViewCell: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == self.pickerLeftTag, let _ = self.pickerLeftDataSource {
            return self.pickerLeftDataSource!.count
        }
        if pickerView.tag == self.pickerRightTag, let _ = self.pickerRightDataSource {
            return self.pickerRightDataSource!.count
        }
        return 0
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
    
}
