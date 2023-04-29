//
//  ImageCropViewController.swift
//  faer
//
//  Created by pluto on 06.06.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import AVFoundation

protocol ImageCropViewControllerDelegate {
    func didCropImage(image: UIImage, controler: ImageCropViewController)
    func didCancelCropping(controler: ImageCropViewController)
}

class ImageCropViewController: UIViewController, UIGestureRecognizerDelegate {
    
    static let nibName = "ImageCropViewController"
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var imageViewWidth: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cropper: CropperView!
    
    @IBOutlet weak var dismissBtn: FaerButton!
    @IBAction func dismissBtnTapped(_ sender: Any) {
        self.delegate?.didCancelCropping(controler: self)
    }
    
    private func resizeFrame(regionOfInterest: CGRect) -> CGRect {
        
        //Convert the image crop frame's size from image space to the screen space
//        CGFloat minimumSize = self.scrollView.minimumZoomScale;
        let mininumSize:CGFloat = 1
        let scaledOffset = CGPoint(x: regionOfInterest.origin.x * mininumSize, y: regionOfInterest.origin.y * mininumSize)
        let scaledCropSize = CGSize(width: regionOfInterest.size.width * mininumSize, height: regionOfInterest.size.height * mininumSize)
        
        // Work out the scale necessary to upscale the crop size to fit the content bounds of the crop bound
        let bounds: CGRect = self.view.bounds
        let scale: CGFloat = min(bounds.size.width / scaledCropSize.width, bounds.size.height / scaledCropSize.height)
        
        // Work out the size and offset of the upscaled crop box
        let frame = CGRect(x: 0, y: 0, width: scaledCropSize.width * scale, height: scaledCropSize.height * scale)
        
        //set the crop box
        var cropBoxFrame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        cropBoxFrame.origin.x = bounds.midX - frame.size.width * 0.5
        cropBoxFrame.origin.x = bounds.midY - frame.size.width * 0.5
        
        
        return cropBoxFrame
    }
    
    // apple method
    private func resizeFrame2(regionOfInterest: CGRect) -> CGRect {
        
        let imageViewScale = max(image.size.width / self.imageView.bounds.width,
                                 image.size.height / self.imageView.bounds.height)
        
        return CGRect(x:regionOfInterest.minX * imageViewScale,
                                       y:regionOfInterest.minY * imageViewScale,
                                       width:regionOfInterest.size.width * imageViewScale,
                                       height:regionOfInterest.size.height * imageViewScale)
        

    }
    
    private func resizeFrame3(image: UIImage, regionOfInterest: CGRect) -> CGRect {
        
        let scaleX: CGFloat = image.size.width / self.view.bounds.width
        let scaleY: CGFloat = image.size.height / self.view.bounds.height
        
        return CGRect(x: regionOfInterest.minX * scaleX,
                      y: regionOfInterest.minY * scaleY,
                      width: regionOfInterest.size.width * scaleX,
                      height: regionOfInterest.size.height * scaleY)
    }

    
    private func visibleImage() -> UIImage {
        // https://stackoverflow.com/questions/43720720/how-to-crop-a-uiimageview-to-a-new-uiimage-in-aspect-fill-mode
        // return the visible part of the UIImageiew
        let imsize = imageView.image!.size
        let ivsize = imageView.bounds.size
        
        var scale : CGFloat = ivsize.width / imsize.width
        
        if imsize.height * scale < ivsize.height {
            scale = ivsize.height / imsize.height
        }
        
        let croppedImsize = CGSize(width:ivsize.width/scale, height:ivsize.height/scale)
        let croppedImrect =
            CGRect(origin: CGPoint(x: (imsize.width-croppedImsize.width)/2.0,
                                   y: (imsize.height-croppedImsize.height)/2.0),
                   size: croppedImsize)
        
        let r = UIGraphicsImageRenderer(size:croppedImsize)
        return r.image { _ in
            imageView.image!.draw(at: CGPoint(x:-croppedImrect.origin.x, y:-croppedImrect.origin.y))
        }
    }
    
    
    func oldTapped() {
        
        //        (56.25, 100.05, 262.5, 466.9) 2268 4032
        
        let portraitImage  : UIImage = image
        let regionOfInterest: CGRect = self.cropper.regionOfInterest
        
        let regionOfInterestViewScale = min((self.view.bounds.width / regionOfInterest.size.width), (self.view.bounds.height /  regionOfInterest.size.height))
        
        // Scale cropRect to handle images larger than shown-on-screen size
        // The croparea is rotate by 90C as .cropping(to:) uses the cgImage which retains the original aspect ration (width > height)
        
        let croparea = resizeFrame3(image: portraitImage, regionOfInterest: regionOfInterest)
          let croppedCGImage = portraitImage.cgImage!.cropping(to: croparea)
          let croppedImage = UIImage(cgImage: croppedCGImage!) //.rotated(by: Measurement(value: 90.0, unit: .degrees))!
         // debug output
 /*       print("regionOfInterest aspect ratio", regionOfInterest.width / regionOfInterest.height, portraitImage.size.width / portraitImage.size.height)
        print("regionOfInterest ", self.cropper.regionOfInterest, "croparea ", croparea, "image.imageOrientation ", image.imageOrientation.rawValue)
        print("image", image.size.width, image.size.height, "image cg", image.cgImage!.width, image.cgImage!.height)
        print("portrait", portraitImage.size.width, portraitImage.size.height)
        print("croppedImage", croppedImage.size.width, croppedImage.size.height, "croppedCGImage", croppedCGImage?.width, croppedCGImage?.height)
        print("imageView", imageView.frame)*/
        
        
        // call delegate
        self.delegate?.didCropImage(image: croppedImage, controler: self)
        
    }
    
    @IBAction func searchBtnTapped(_ sender: Any) {
        
        let scale:CGFloat = 1/scrollView.zoomScale
        
        let x:CGFloat = scrollView.contentOffset.x * scale
        let y:CGFloat  = scrollView.contentOffset.y * scale

        let width:CGFloat = scrollView.frame.size.width * scale
        let height:CGFloat = scrollView.frame.size.height * scale
        let croppedCGImage: CGImage = (imageView.image?.cgImage?.cropping(to: CGRect(x: x, y: y, width: width, height: height)))!
        let croppedImage: UIImage = UIImage(cgImage: croppedCGImage)
        // debugoutout
//        print("croppedImage", croppedImage.size)
  //      print("image", image.size)
        // call delegate
        self.delegate?.didCropImage(image: croppedImage, controler: self)
    }
    
    var image: UIImage!
    
    var delegate: ImageCropViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.    
        //self.imageView.image = self.image
        scrollView.delegate = self
        self.setImageToCrop(image: image)
        
        //TODO: Draw grid

    }
    
    private func setImageToCrop(image:UIImage){

        // this is a fix for a iOS bug; sometimes the orientation of a UIImage's cgimage is different from its image.orientation
        if CGFloat(image.cgImage!.height) != image.size.height {
            imageView.image = image.fixedOrientation()
        } else {
            imageView.image = image
        }
        print("image", image.cgImage!.height, image.size.height, imageView.image!.cgImage!.height, imageView.image!.size.height, image.imageOrientation)
        
        imageViewWidth.constant = image.size.width
        imageViewHeight.constant = image.size.height
        let scaleHeight = scrollView.frame.size.width/image.size.width
        let scaleWidth = scrollView.frame.size.height/image.size.height
        scrollView.minimumZoomScale = max(scaleWidth, scaleHeight)
        scrollView.zoomScale = max(scaleWidth, scaleHeight)
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /*
         Set an inital rect of interest that is 80% of the view's shortest side
         and 25% of the longest side. This means that the region of interest will
         appear in the same spot regardless of whether the app starts in portrait
         or landscape.
         */
        let width = self.view.frame.width * 0.7
        let height = self.view.frame.height * 0.7
        let x = (self.view.frame.width - width) / 2.0
        let y = (self.view.frame.height - height) / 2.0
        
        DispatchQueue.main.async {
            let initialRegionOfInterest = CGRect(x: x, y: y, width: width, height: height)
            print(initialRegionOfInterest)
            self.cropper.setRegionOfInterestWithProposedRegionOfInterest(initialRegionOfInterest)
        }
        
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    private func cropImage(_ inputImage: UIImage, toRect cropRect: CGRect, viewWidth: CGFloat, viewHeight: CGFloat) -> UIImage?
    {
        let imageViewScale = max(inputImage.size.width / viewWidth,
                                 inputImage.size.height / viewHeight)
        
        // Scale cropRect to handle images larger than shown-on-screen size
        let cropZone = CGRect(x:cropRect.origin.x * imageViewScale,
                              y:cropRect.origin.y * imageViewScale,
                              width:cropRect.size.width * imageViewScale,
                              height:cropRect.size.height * imageViewScale)
        
        // Perform cropping in Core Graphics
        guard let cutImageRef: CGImage = inputImage.cgImage?.cropping(to:cropZone)
            else {
                return nil
        }
        
        // Return image to UIImage
        let croppedImage: UIImage = UIImage(cgImage: cutImageRef)
        return croppedImage
    }
    
}

extension ImageCropViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

}

extension UIImage {
    
    func fixedOrientation() -> UIImage? {
        
        guard imageOrientation != UIImage.Orientation.up else {
            //This is default orientation, don't need to do anything
            return self.copy() as? UIImage
        }
        
        guard let cgImage = self.cgImage else {
            //CGImage is not available
            return nil
        }
        
        guard let colorSpace = cgImage.colorSpace, let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil //Not able to create CGContext
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
            break
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
            break
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
            break
        case .up, .upMirrored:
            break
        }
        
        //Flip image one more time if needed to, this is to prevent flipped image
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case .leftMirrored, .rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        }
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        guard let newCGImage = ctx.makeImage() else { return nil }
        return UIImage.init(cgImage: newCGImage, scale: 1, orientation: .up)
    }
}

extension UIImage {
    struct RotationOptions: OptionSet {
        let rawValue: Int
        
        static let flipOnVerticalAxis = RotationOptions(rawValue: 1)
        static let flipOnHorizontalAxis = RotationOptions(rawValue: 2)
    }
    
    func rotated(by rotationAngle: Measurement<UnitAngle>, options: RotationOptions = []) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        let rotationInRadians = CGFloat(rotationAngle.converted(to: .radians).value)
        let transform = CGAffineTransform(rotationAngle: rotationInRadians)
        var rect = CGRect(origin: .zero, size: self.size).applying(transform)
        rect.origin = .zero
        
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        return renderer.image { renderContext in
            renderContext.cgContext.translateBy(x: rect.midX, y: rect.midY)
            renderContext.cgContext.rotate(by: rotationInRadians)
            
            let x = options.contains(.flipOnVerticalAxis) ? -1.0 : 1.0
            let y = options.contains(.flipOnHorizontalAxis) ? 1.0 : -1.0
            renderContext.cgContext.scaleBy(x: CGFloat(x), y: CGFloat(y))
            
            let drawRect = CGRect(origin: CGPoint(x: -self.size.width/2, y: -self.size.height/2), size: self.size)
            renderContext.cgContext.draw(cgImage, in: drawRect)
        }
    }
}

extension UIImageView {
    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }
        
        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }
        
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0
        
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}

extension UIImageView
{
    func imageFrame()->CGRect
    {
        let imageViewSize = self.frame.size
        guard let imageSize = self.image?.size else
        {
            return CGRect.zero
        }
        let imageRatio = imageSize.width / imageSize.height
        let imageViewRatio = imageViewSize.width / imageViewSize.height
        if imageRatio < imageViewRatio
        {
            let scaleFactor = imageViewSize.height / imageSize.height
            let width = imageSize.width * scaleFactor
            let topLeftX = (imageViewSize.width - width) * 0.5
            return CGRect(x: topLeftX, y: 0, width: width, height: imageViewSize.height)
        }
        else
        {
            let scalFactor = imageViewSize.width / imageSize.width
            let height = imageSize.height * scalFactor
            let topLeftY = (imageViewSize.height - height) * 0.5
            return CGRect(x: 0, y: topLeftY, width: imageViewSize.width, height: height)
        }
    }
}
