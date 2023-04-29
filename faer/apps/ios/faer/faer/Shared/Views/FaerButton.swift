//
//  FaerButton
//  faer
//
//  Created by pluto on 14.02.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

@IBDesignable
class FaerButton: UIButton {
    
    private var selectedBackgroundColor: UIColor = .clear
    private var defaultBackgroundColor: UIColor!
    
    private var paddedTitleLabel: PaddingLabel!
    
    @IBInspectable public var hasBorder: Bool = false {
        didSet {
            if self.hasBorder {
                self.layer.borderColor = self.titleColor(for: .normal)?.cgColor
                self.layer.borderWidth = 2
            } else {
                self.layer.borderWidth = 0
            }
        }
    }
    
    @IBInspectable public var isOutlined: Bool = false {
        didSet {
            self.updateTitleOutline()
        }
    }    
    
    @IBInspectable var isSelectedBackgroundColor: UIColor = .clear
    
    @IBInspectable var isRound: Bool = false {
        didSet {
            if self.isRound {
                self.layer.cornerRadius = 0.5 * self.bounds.size.width
                self.layer.masksToBounds = true
            } else {
                self.layer.cornerRadius = 0
                self.layer.masksToBounds = false
            }
        }
    }
    
    override public var isSelected: Bool {
        didSet {
            self.backgroundColor = isSelected ? isSelectedBackgroundColor : self.defaultBackgroundColor
            self.updateTitleOutline()
        }
    }
    
    override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        super.setTitleColor(color, for: state)
        self.updateTitleOutline()
    }
    
    private func updateTitleOutline() {
        guard let _ = self.titleLabel, let _ = self.titleLabel!.text else { return }
        
        let currentTitleColor: UIColor
        
        // setting only using currentTitleColor = self.titleColor(for: self.state)! doesn't work
        if self.isSelected {
            currentTitleColor = self.titleColor(for: .selected)!
        } else {
            currentTitleColor = self.titleColor(for: .normal)!
        }
        
        switch self.isOutlined {
        case true:
            // make title outlined

            let strokeTextAttributes:[NSAttributedString.Key : Any] = [
                NSAttributedString.Key.strokeColor: currentTitleColor.inverted,
                NSAttributedString.Key.foregroundColor: currentTitleColor as Any,
                NSAttributedString.Key.strokeWidth : -1,
                NSAttributedString.Key.font : self.titleLabel!.font
            ]

            self.setAttributedTitle(NSMutableAttributedString(string: "\(self.titleLabel!.text!)", attributes: strokeTextAttributes), for: .normal)


        case false:
            // make title not outlined
            let strokeTextAttributes:[NSAttributedString.Key : Any] = [
                NSAttributedString.Key.strokeColor: currentTitleColor.inverted,
                NSAttributedString.Key.foregroundColor: currentTitleColor as Any,
                NSAttributedString.Key.strokeWidth : 0,
                NSAttributedString.Key.font : self.titleLabel!.font
            ]
            self.setAttributedTitle(NSMutableAttributedString(string: self.titleLabel!.text!, attributes: strokeTextAttributes), for: .normal)
        }
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        self.defaultBackgroundColor = self.backgroundColor

    }
    
}

@IBDesignable class PaddingLabel: UILabel {
    
    @IBInspectable var topInset: CGFloat = 5.0
    @IBInspectable var bottomInset: CGFloat = 5.0
    @IBInspectable var leftInset: CGFloat = 7.0
    @IBInspectable var rightInset: CGFloat = 7.0
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }
}

