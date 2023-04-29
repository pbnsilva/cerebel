import UIKit

class RichSearchSectionHeaderView: UICollectionReusableView {
    
    static let reuseIdentifier: String = "RichSearchSectionHeaderView"
    
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
        titleView?.translatesAutoresizingMaskIntoConstraints = false
        titleView?.font = UIFont(name: StyleGuide.fontRegular, size: StyleGuide.fontCopySize)
        titleView?.textColor = UIColor.lightGray
        titleView?.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 15).isActive = true
        titleView?.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0).isActive = true
        titleView?.topAnchor.constraint(equalTo: self.topAnchor, constant: 15).isActive = true
        titleView?.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
    }
    
    override func prepareForReuse() {
        self.titleView?.text = nil
    }
}
