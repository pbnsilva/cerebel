//
//  SearchFilterSectionHeader.swift
//  faer
//
//  Created by pluto on 04.07.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

protocol FilterSectionHeaderDelegate :class {
    func didTap(header: FilterSectionHeader)
}

class FilterSectionHeader: UITableViewHeaderFooterView {
    
    static let reuseIdentifier: String = "FilterSectionHeaderIdentifier"
    
    weak var delegate: FilterSectionHeaderDelegate?
    
    private var state: UILabel?
    
    private var title: UILabel?
    
    private let openState: String = "" // angle up
    private let closedState: String = "" // angle down
    
    var isSelected: Bool = false {
        didSet {
            if isSelected {
                self.state?.text = self.openState
            } else {
                self.state?.text = self.closedState
            }
        }
    }
        
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        
        self.contentView.backgroundColor = .white
        
        //add title
        self.title = UILabel()
        title!.font = UIFont(name: StyleGuide.fontBold, size: StyleGuide.fontMediumSize)
        self.addSubview(title!)

        title!.translatesAutoresizingMaskIntoConstraints = false
        title!.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        title!.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true

        // add state
        self.state = UILabel()
        state!.text = self.closedState
        state!.font = UIFont(name: StyleGuide.fontIcon, size: StyleGuide.fontMediumSize)
        state!.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(state!)
        state!.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        state!.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true
        
        // recognize taps
        let tap = UITapGestureRecognizer(target: self, action: #selector(FilterSectionHeader.didTap))
        self.addGestureRecognizer(tap)

    }
    
    func setTitle(text: String, preferredHeight: CGFloat) {
    
        title?.heightAnchor.constraint(equalToConstant: preferredHeight).isActive = true
        
        self.title?.text = text
        
    }
    
    @objc
    private func didTap(sender: UITapGestureRecognizer) {
        self.delegate?.didTap(header: self)
    }
    
    override func prepareForReuse() {
        self.title = nil
        self.state = nil
    }
    
}

