//
//  ViewController.swift
//  test
//
//  Created by pluto on 12.09.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController, UIScrollViewDelegate {
    
    let vcCount:CGFloat = 3 // number of horizontal view controllers
    
    var scrollView: UIScrollView!
    var discoverVc: UIViewController!
    var cameraVc: UIViewController!
    var likesVc: UIViewController!
    
    var initialContentOffset = CGPoint() // scrollView initial offset

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        discoverVc = storyboard.instantiateViewController(withIdentifier: "discoverSB")
        cameraVc = storyboard.instantiateViewController(withIdentifier: "cameraSB")
        likesVc = storyboard.instantiateViewController(withIdentifier: "likesSB")
        
        setupHorizontalScrollView()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupHorizontalScrollView() {
        scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        
        let view = (
            x: self.view.bounds.origin.x,
            y: self.view.bounds.origin.y,
            width: self.view.bounds.width,
            height: self.view.bounds.height
        )
        
        scrollView.frame = CGRect(x: view.x,
                                  y: view.y,
                                  width: view.width,
                                  height: view.height
        )
        
        self.view.addSubview(scrollView)
        
        let scrollWidth  = vcCount * view.width
        let scrollHeight  = view.height
        scrollView.contentSize = CGSize(width: scrollWidth, height: scrollHeight)
        
        discoverVc.view.frame = CGRect(x: 0,
                                   y: 0,
                                   width: view.width,
                                   height: view.height
        )
        
        cameraVc.view.frame = CGRect(x: view.width,
                                    y: 0,
                                    width: view.width,
                                    height: view.height
        )
        
        likesVc.view.frame = CGRect(x: view.width * 2,
                                    y: 0,
                                    width: view.width,
                                    height: view.height
        )
        
        addChildViewController(discoverVc)
        addChildViewController(likesVc)
        addChildViewController(cameraVc)
        
        scrollView.addSubview(discoverVc.view)
        scrollView.addSubview(likesVc.view)
        scrollView.addSubview(cameraVc.view)
        
        discoverVc.didMove(toParentViewController: self)
        likesVc.didMove(toParentViewController: self)
        cameraVc.didMove(toParentViewController: self)
        
        scrollView.contentOffset.x = 0 // start at first viewcontroller
        scrollView.delegate = self
    }
    
 /*   func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.initialContentOffset = scrollView.contentOffset
    }*/
    
 /*   func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if delegate != nil && !delegate!.outerScrollViewShouldScroll() && !directionLockDisabled {
            let newOffset = CGPoint(x: self.initialContentOffset.x, y: self.initialContentOffset.y)
            
            // Setting the new offset to the scrollView makes it behave like a proper
            // directional lock, that allows you to scroll in only one direction at any given time
            self.scrollView!.setContentOffset(newOffset, animated:  false)
        }
    }*/



}

