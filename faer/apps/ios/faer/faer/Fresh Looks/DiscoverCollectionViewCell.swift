import UIKit
import Hero

class DiscoverCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "discoverCellReuseId"

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var promotion: UILabel!
    
    @IBOutlet weak var promotionContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.promotionContainer?.isHidden = true
        self.promotion?.text = ""
    }
    
    func setPromotion(text: String) {
        self.promotionContainer?.isHidden = false
        self.promotion?.text = text
    }

}
