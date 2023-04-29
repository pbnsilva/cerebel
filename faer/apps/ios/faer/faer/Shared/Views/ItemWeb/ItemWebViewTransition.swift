import UIKit

class ItemWebViewTransition: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate  {
    
    private var presenting = false
    
    // MARK: UIViewControllerAnimatedTransitioning protocol methods
    
    // animate a change from one viewcontroller to another
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        // get reference to our fromView, toView and the container view that we should perform the transition in
        let container = transitionContext.containerView
        
        // create a tuple of our screens
        let screens : (from:UIViewController, to:UIViewController) = (transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!, transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!)
        
        // assign references to our menu view controller and the 'bottom' view controller from the tuple
        // remember that our menuViewController will alternate between the from and to view controller depending if we're presenting or dismissing
        let itemWebViewController = !self.presenting ? screens.from as! ItemWebViewController : screens.to as! ItemWebViewController
        let bottomViewController = !self.presenting ? screens.to as UIViewController : screens.from as UIViewController
        
        let itemWebView = itemWebViewController.view
        let bottomView = bottomViewController.view
        
        // prepare menu items to slide in
        if (self.presenting){
            self.offStageMenuController(vc: itemWebViewController)
        }
        
        // add the both views to our view controller
        container.addSubview(bottomView!)
        container.addSubview(itemWebView!)
        
        let duration = self.transitionDuration(using: transitionContext)
        
        // perform the animation!
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseIn, animations: {
            
            if (self.presenting){
                self.onStageMenuController(vc: itemWebViewController) // onstage items: slide in
            }
            else {
                self.offStageMenuController(vc: itemWebViewController) // offstage items: slide out
            }

        }) { (finished) in
            // tell our transitionContext object that we've finished animating
            transitionContext.completeTransition(true)
            
            // bug: we have to manually add our 'to view' back http://openradar.appspot.com/radar?id=5320103646199808
            UIApplication.shared.keyWindow?.addSubview(screens.to.view)

        }
        
    }
    
    func offStage(amount: CGFloat) -> CGAffineTransform {
        return CGAffineTransform(translationX: amount, y: 0)
    }
    
    func offStageMenuController(vc: ItemWebViewController){
        
        vc.view.alpha = 0
        
        // setup paramaters for 2D transitions for animations

    /*
        vc.textPostIcon.transform = self.offStage(-topRowOffset)
        vc.textPostLabel.transform = self.offStage(-topRowOffset)
        
        vc.quotePostIcon.transform = self.offStage(-middleRowOffset)
        vc.quotePostLabel.transform = self.offStage(-middleRowOffset)
        
        vc.chatPostIcon.transform = self.offStage(-bottomRowOffset)
        vc.chatPostLabel.transform = self.offStage(-bottomRowOffset)
        
        vc.photoPostIcon.transform = self.offStage(topRowOffset)
        vc.photoPostLabel.transform = self.offStage(topRowOffset)
        
        vc.linkPostIcon.transform = self.offStage(middleRowOffset)
        itemWebViewController.linkPostLabel.transform = self.offStage(middleRowOffset)
        
        vc.audioPostIcon.transform = self.offStage(bottomRowOffset)
        vc.audioPostLabel.transform = self.offStage(bottomRowOffset) */
        
        
        
    }
    
    func onStageMenuController(vc: ItemWebViewController){
        
        // prepare menu to fade in
        vc.view.alpha = 1
      /*
        itemWebViewController.textPostIcon.transform = CGAffineTransformIdentity
        itemWebViewController.textPostLabel.transform = CGAffineTransformIdentity
        
        itemWebViewController.quotePostIcon.transform = CGAffineTransformIdentity
        itemWebViewController.quotePostLabel.transform = CGAffineTransformIdentity
        
        itemWebViewController.chatPostIcon.transform = CGAffineTransformIdentity
        itemWebViewController.chatPostLabel.transform = CGAffineTransformIdentity
        
        itemWebViewController.photoPostIcon.transform = CGAffineTransformIdentity
        itemWebViewController.photoPostLabel.transform = CGAffineTransformIdentity
        
        itemWebViewController.linkPostIcon.transform = CGAffineTransformIdentity
        itemWebViewController.linkPostLabel.transform = CGAffineTransformIdentity
        
        itemWebViewController.audioPostIcon.transform = CGAffineTransformIdentity
        itemWebViewController.audioPostLabel.transform = CGAffineTransformIdentity*/
        
    }
    
    // return how many seconds the transiton animation will take
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    // MARK: UIViewControllerTransitioningDelegate protocol methods
    
    // return the animataor when presenting a viewcontroller
    // rememeber that an animator (or animation controller) is any object that aheres to the UIViewControllerAnimatedTransitioning protocol
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        return self
    }
    
    // return the animator used when dismissing from a viewcontroller
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        return self
    }
    
}

