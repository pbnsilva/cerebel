//
//  SearchPopupSectionHeaderView.swift
//  faer
//
//  Created by pluto on 27.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class SearchPopupSectionHeaderView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    var title: String? {
        didSet {
            self.titleView?.text = title
        }
    }
    
    private var titleView: UILabel?
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        titleView = UILabel()
        self.addSubview(titleView!)
        titleView?.font = UIFont(name: StyleGuide.fontRegular, size: StyleGuide.fontCopySize)
        titleView?.textColor = UIColor.lightGray
        titleView?.translatesAutoresizingMaskIntoConstraints = false
        titleView?.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 15).isActive = true
        titleView?.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0).isActive = true
        titleView?.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        titleView?.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
    }

}
