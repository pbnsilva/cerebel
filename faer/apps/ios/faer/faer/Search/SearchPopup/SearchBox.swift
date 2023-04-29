//
//  SearchPopupSectionHeaderView.swift
//  faer
//
//  Created by pluto on 27.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

protocol SearchBoxDelegate :class {
    
    func cancelTapped(view: SearchBox)
    
    func searchFieldShouldClear() -> Bool
    
    func searchBtnTriggered(text: String)
    
    func searchFieldChanged(text: String)
    
}

class SearchBox: UIView {
    
    // this is going to be our container object
    
    weak var delegate: SearchBoxDelegate?
    
    // other usual outlets
    @IBOutlet weak var cancelBtn: UIButton!
    @IBAction func cancelBtnTapped(_ sender: Any) {
        self.delegate?.cancelTapped(view: self)
    }
    
    @IBOutlet weak var searchField: UITextField!
    
    @IBAction func searchFieldPrimaryAction(_ sender: Any) {
        self.delegate?.searchBtnTriggered(text: self.searchField.text ?? "")
    }
    
    @IBAction func searchFieldEditingChanged(_ sender: Any) {
        self.delegate?.searchFieldChanged(text: self.searchField.text ?? "")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.searchField.delegate = self
        
        self.searchField.becomeFirstResponder()
    }
    
}


extension UINib {
    func instantiate() -> Any? {
        return self.instantiate(withOwner: nil, options: nil).first
    }
}

extension UIView {
    
    static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    static func fromXIB(autolayout: Bool = true) -> Self {
        // generic helper function
        func instantiateUsingNib<T: UIView>(autolayout: Bool) -> T {
            let view = self.nib.instantiate() as! T
            view.translatesAutoresizingMaskIntoConstraints = !autolayout
            return view
        }
        return instantiateUsingNib(autolayout: autolayout)
    }
}





extension SearchBox: UITextFieldDelegate {
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return self.delegate?.searchFieldShouldClear() ?? true
    }
    
}
