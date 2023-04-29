//
//  CameraSessionViewController.swift
//  faer
//
//  Created by pluto on 22.03.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import TOCropViewController
import NVActivityIndicatorView
import NotificationBannerSwift

class VisualSearchViewController: SearchInputTypeViewController, UINavigationControllerDelegate {
    
    static let storyboardName: String = "VisualSearch"
    
    static let storyboardID: String = "VisualSearchViewController"

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    
    // MARK: View Controller Life Cycle
    
    @IBOutlet weak var infoView: UIView! // General purpose info view
    @IBOutlet weak var infoTitle: UILabel!
    
    @IBOutlet weak var dismissButton: FaerButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Handle changes in the search input type
        self.addEventListner(for: .keyboard)
        self.addEventListner(for: .microphone)
        self.addEventListner(for: .camera)
        
        // Set up the video preview view.
        previewView.session = session
        
        if !self.hasPermissions {
            sessionQueue.suspend()
            DispatchQueue.main.async {
                self.infoView.isHidden = false
            }
        }
        
        sessionQueue.async {
            self.configureSession()
        }
        
        let pinch: UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        self.previewView.addGestureRecognizer(pinch)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        self.isPresentingDetectedProduct = false
        self.startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
            DispatchQueue.main.async {
                self.activityIndicatorView.isHidden = true
                self.activityIndicatorView.stopAnimating()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }
    
    // MARK: Handle zoom
    
    private let minimumZoom: CGFloat = 1.0
    private let maximumZoom: CGFloat = 3.0
    private var lastZoomFactor: CGFloat = 1.0
    
    @objc
    func handlePinch(_ pinch: UIPinchGestureRecognizer) {
        guard let device = self.videoDeviceInput?.device else { return }
        
        // Return zoom value between the minimum and maximum zoom values
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, minimumZoom), maximumZoom), device.activeFormat.videoMaxZoomFactor)
        }
        
        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.videoZoomFactor = factor
            } catch {
                print("\(error.localizedDescription)")
            }
        }
        
        let newScaleFactor = minMaxZoom(pinch.scale * lastZoomFactor)
        
        switch pinch.state {
        case .began: fallthrough
        case .changed: update(scale: newScaleFactor)
        case .ended:
            lastZoomFactor = minMaxZoom(newScaleFactor)
            update(scale: lastZoomFactor)
        default: break
        }
    }
    
    
    // MARK: Session Management
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private let session = AVCaptureSession()
    
    private var isSessionRunning = false
    
    private let sessionQueue = DispatchQueue(label: "session queue") // Communicate with the session and other session objects on this queue.
    
    private var setupResult: SessionSetupResult = .success
    
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    @IBOutlet private weak var previewView: PreviewView!
    
    // Call this on the session queue.
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        
        /*
         We do not create an AVCaptureMovieFileOutput when setting up the session because the
         AVCaptureMovieFileOutput does not support movie recording with AVCaptureSession.Preset.Photo.
         */
        session.sessionPreset = .photo
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If the back dual camera is not available, default to the back wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                /*
                 In some cases where users break their phones, the back wide angle camera is not available.
                 In this case, we should default to the front wide angle camera.
                 */
                defaultVideoDevice = frontCameraDevice
            }
            guard let _ = defaultVideoDevice else { // happens on simulator
                throw NSError(domain: "No device found", code: 0, userInfo: nil)
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice!)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    /*
                     Why are we dispatching this to the main queue?
                     Because AVCaptureVideoPreviewLayer is the backing layer for PreviewView and UIView
                     can only be manipulated on the main thread.
                     Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     
                     Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    let statusBarOrientation = UIApplication.shared.statusBarOrientation
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if statusBarOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: statusBarOrientation) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                    
                }
            } else {
                print("Could not add video device input to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Could not create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        self.enableMetadataDetection()
        
        // Add photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        CommonSeguesManager.prepare(for: segue, sender: sender)
    }
    
    private func startSession() {
        
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                DispatchQueue.main.async {
                    self.infoView.isHidden = true
                }
                
            case .notAuthorized:
                return
                
            case .configurationFailed:
                DispatchQueue.main.async {
                    self.infoView.isHidden = false
                    self.infoTitle.text = "Couldn't find a camera"
                    self.cameraButton.isEnabled = false
                    self.flashModeButton.isEnabled = false
                }
            }
        }
    }
    
    @objc private func resumeSession() {
        sessionQueue.async {
            /*
             The session might fail to start running, e.g., if a phone or FaceTime call is still
             using audio or video. A failure to start the session running will be communicated via
             a session runtime error notification. To avoid repeatedly failing to start the session
             running, we only try to restart the session running in the session runtime error handler
             if we aren't trying to resume the session running.
             */
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            if !self.session.isRunning {
                DispatchQueue.main.async {
                    let message = NSLocalizedString("Unable to resume", comment: "Alert message when unable to resume the session running")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: Device Configuration
    
    @IBOutlet private weak var cameraButton: UIButton!
    
    @IBOutlet private weak var cameraUnavailableLabel: UILabel!
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera],
                                                                               mediaType: .video, position: .unspecified)
    
    private var currentFlashMode: AVCaptureDevice.FlashMode = .auto
    
    @IBAction private func changeCamera(_ cameraButton: UIButton) {
        
        guard
            let currentVideoDevice = self.videoDeviceInput?.device
        else { return }
        
        cameraButton.isEnabled = false
        
        sessionQueue.async {
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInWideAngleCamera
            }
            
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            // First, look for a device with both the preferred position and device type. Otherwise, look for a device with only the preferred position.
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice, let _ = self.videoDeviceInput {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    
                    // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
                    self.session.removeInput(self.videoDeviceInput!)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        NotificationCenter.default.removeObserver(self, name: .AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
                        
                        NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
                        
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput!)
                    }
                    
                    self.session.commitConfiguration()
                } catch {
                    print("Error occured while creating video device input: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.cameraButton.isEnabled = true
            }
        }
    }
    
    @IBOutlet weak var flashModeButton: FaerButton!
    
    @IBAction func changeFlashMode(_ sender: Any) {
        if self.currentFlashMode == .auto {
            self.currentFlashMode = .off
            self.flashModeButton.alpha = 0.5
        } else {
            self.currentFlashMode = .auto
            self.flashModeButton.alpha = 1
        }
    }
    
    
    @IBAction private func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let devicePoint = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
        focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        
        guard let device = self.videoDeviceInput?.device else { return }
        
        sessionQueue.async {
            
            do {
                try device.lockForConfiguration()
                
                /*
                 Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                 Call set(Focus/Exposure)Mode() to apply the new point of interest.
                 */
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    // MARK: - Handle meta data detection eg QR codes
    
    private var isPresentingDetectedProduct: Bool = false
    
    private let metadataObjectsQueue = DispatchQueue(label: "metadata objects queue", attributes: [], target: nil)
    
    private func metadataProviderName(url: URL) -> String? {
        let allowedMetadataHosts: [String: [String]] = ["circular.fashion" : ["circular.fashion", "circularfashion.id"]]
        
        guard let _ = url.host else {
            return nil
        }
        
        for (name, hosts) in allowedMetadataHosts {
            for h in hosts {
                if url.host!.caseInsensitiveCompare(h) == .orderedSame {
                    return name
                }
            }
        }
        
        return nil
        
    }
    
    private func enableMetadataDetection() {
        // Add handling of QR, ean codes and similar
        let metadataOutput = AVCaptureMetadataOutput()
        
        guard self.session.canAddOutput(metadataOutput) else { return }
        
        // Add metadata output.
        session.addOutput(metadataOutput)
        
        // Set this view controller as the delegate for metadata objects.
        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataObjectsQueue)
        metadataOutput.metadataObjectTypes = [.qr] // only detect QR codes for now
        
    }
    
    // MARK - Get permission for photo and camera access
    
    private var hasPermissions: Bool {
        get {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                return true
            default:
                return false
            }
        }
    }
    
    private func requestCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return
        case .denied:
            self.openSettings(title: "Look-a-like Search", message: "Tap Settings to let Faer use your camera")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                
                self.sessionQueue.resume()
                
            })
        case .restricted:
            self.openSettings(title: "Look-a-like Search", message: "Tap Settings to let Faer use your camera")
        }
    }
    
    private func requestPhotoLibraryAuthorization(_ completionHandler: @escaping ((_ authorized: Bool) -> Void)) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            // The user has previously granted access to the photo library.
            completionHandler(true)
            
        case .notDetermined:
            // The user has not yet been presented with the option to grant photo library access so request access.
            PHPhotoLibrary.requestAuthorization({ status in
                completionHandler((status == .authorized))
            })
            
        case .denied:
            // The user has previously denied access.
            completionHandler(false)
            
        case .restricted:
            // The user doesn't have the authority to request access e.g. parental restriction.
            completionHandler(false)
        }
    }
    
    // MARK: Capturing Photos
    
    private let photoOutput = AVCapturePhotoOutput()
    
    private var photoSampleBuffer: CMSampleBuffer?
    
    private var photoPreviewSampleBuffer: CMSampleBuffer?
    
    
    private func capturePhoto() {
        guard let device = self.videoDeviceInput?.device else { return }
        
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. We do this to ensure UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        let height = self.view.frame.height
        let width = self.view.frame.width
        sessionQueue.async {
            // Update the photo output's connection to match the video orientation of the video preview layer.
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.isAutoStillImageStabilizationEnabled = true
            photoSettings.isHighResolutionPhotoEnabled = false
            
            let previewPixelType = photoSettings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                                 kCVPixelBufferWidthKey as String: width,
                                 kCVPixelBufferHeightKey as String: height] as [String : Any]
            photoSettings.previewPhotoFormat = previewFormat

            
            if device.isFlashAvailable {
                photoSettings.flashMode = self.currentFlashMode
            }
            
            photoSettings.isHighResolutionPhotoEnabled = true
            if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
            }
            
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
            
        }
    }
    
    private func saveSampleBufferToPhotoLibrary(_ sampleBuffer: CMSampleBuffer,
                                                previewSampleBuffer: CMSampleBuffer?,
                                                completionHandler: ((_ success: Bool, _ error: Error?) -> Void)?) {
        
        guard let jpegData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(
            forJPEGSampleBuffer: sampleBuffer,
            previewPhotoSampleBuffer: previewSampleBuffer)
            else {
                print("Unable to create JPEG data.")
                completionHandler?(false, nil)
                return
        }
        
        if let preview = UIImage(data: jpegData) {
            
            DispatchQueue.main.async {
                self.presentImageCropper(image: preview)
            }
        }
        
        self.requestPhotoLibraryAuthorization({ authorized in
            guard authorized else {
                print("Permission to access photo library denied.")
                completionHandler?(false, nil)
                return
            }
            
            PHPhotoLibrary.shared().performChanges( {
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: PHAssetResourceType.photo, data: jpegData, options: nil)
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    completionHandler?(success, error)
                }
            })
        })
    }
    
    // crops image according to the current preview
    private func cropImage(with image: UIImage) -> UIImage {
        let outputRect = self.previewView.videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: self.previewView.videoPreviewLayer.bounds)
        
        let takenCGImage = image.cgImage!
        let width = CGFloat(takenCGImage.width)
        let height = CGFloat(takenCGImage.height)
        let cropRect = CGRect(x: outputRect.origin.x * width, y: outputRect.origin.y * height, width: outputRect.size.width * width, height: outputRect.size.height * height)
        
        let cropCGImage = takenCGImage.cropping(to: cropRect)
        let cropTakenImage = UIImage(cgImage: cropCGImage!, scale: 1, orientation: image.imageOrientation)
        
        return cropTakenImage
    }
    
    
    override func inputButtonTapped(_ sender: UIButton) {
        super.inputButtonTapped(sender)
        guard sender.tag == SearchInputType.camera.rawValue else {
            return
        }
        
        guard self.hasPermissions else {
            self.requestCameraAuthorization()
            return
        }
        
        self.capturePhoto()
        
    }
    
    // MARK: Use Photo from Library
    
    @IBOutlet weak var photoLibraryPickerButton: FaerButton!
    
    @IBAction func photoLibraryPickerButton(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("can't open photo library")
            return
        }
        
        let imagePicker = UIImagePickerController()
        
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        
        present(imagePicker, animated: true)
        
    }
    
    // MARK: Edit Photo
    
  
     // not in use as custom image cropper has an issue with image orientation. see imageCropper class for details
    
    private func customCropController(image: UIImage) -> TOCropViewController {
        // run cropper
        let cropViewController:TOCropViewController = TOCropViewController(image: image)
        //  let cropViewController:TOCropViewController = TOCropViewController(image: image.kf.resize(to: newSize))
        cropViewController.delegate = self
        // custom done button
        let textAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.font:UIFont(name: StyleGuide.fontSemiBold, size: 21)!,
            NSAttributedString.Key.foregroundColor : UIColor.white
        ]
        
        cropViewController.toolbar.doneTextButton.setAttributedTitle(NSAttributedString(string: "DONE", attributes: textAttributes), for: .normal)
        cropViewController.toolbar.doneTextButton.sizeToFit()
        // custom cancel button
        cropViewController.toolbar.cancelTextButton.setAttributedTitle(NSAttributedString(string: "CANCEL", attributes: textAttributes), for: .normal)
        cropViewController.toolbar.cancelTextButton.sizeToFit()
        
        // setup rest
        cropViewController.toolbar.clampButton.isHidden = true
        cropViewController.toolbar.rotateClockwiseButtonHidden = true
        cropViewController.toolbar.rotateCounterclockwiseButtonHidden = true
        cropViewController.toolbar.resetButtonEnabled = false
        return cropViewController
    }
    
    
    // MARK: KVO and Notifications
    
    private var keyValueObservations = [NSKeyValueObservation]()
    
    private func addObservers() {
        guard let device = self.videoDeviceInput?.device else { return }
        
        let keyValueObservation = session.observe(\.isRunning, options: .new) { _, change in
            guard let isSessionRunning = change.newValue else { return }
            
            DispatchQueue.main.async {
                // Only enable the ability to change camera if the device has more than one camera.
                self.cameraButton.isEnabled = isSessionRunning && self.videoDeviceDiscoverySession.uniqueDevicePositionsCount > 1
            }
        }
        keyValueObservations.append(keyValueObservation)
        
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: device)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: .AVCaptureSessionRuntimeError, object: session)
        
        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: .AVCaptureSessionWasInterrupted, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeSession), name: .AVCaptureSessionInterruptionEnded, object: session)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        
        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }
    
    @objc
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    @objc
    func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        
        print("Capture session runtime error: \(error)")
        
        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                }
            }
        } else {
            self.resumeSession()
        }
    }
    
    @objc
    func sessionWasInterrupted(notification: NSNotification) {
        /*
         In some scenarios we want to enable the user to resume the session running.
         For example, if music playback is initiated via control center while
         using AVCam, then the user can let AVCam resume
         the session running, which will stop music playback. Note that stopping
         music playback in control center will not automatically resume the session
         running. Also note that it is not always possible to resume, see `resumeInterruptedSession(_:)`.
         */
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            
            
            // Simply fade-in a label to inform the user that the camera is unavailable.
            let _ = self.alert(message: "Camera unavailable")
            
        }
    }
    
    // MARK: Transitions
    
    @IBOutlet weak var activityIndicatorView: NVActivityIndicatorView!
    
    override func transitionForSearching(visible: Bool) {
        if visible {
            activityIndicatorView.startAnimating()
            activityIndicatorView.isHidden = false
        } else {
            activityIndicatorView.stopAnimating()
            activityIndicatorView.isHidden = true
        }
    }
    
    
}

// MARK: - TOCropViewDelegate
extension VisualSearchViewController: TOCropViewControllerDelegate {
    
    func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        // 'image' is the newly cropped version of the original image
        DispatchQueue.main.async {
            cropViewController.dismiss(animated: false, completion: {
                self.performSegue(withIdentifier: CommonSegues.searchResult.rawValue, sender: image)
            })
        }
    }
    
    func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        cropViewController.dismiss(animated: false, completion: nil)
    }
}

// MARK: ImagePicker, UIImagePickerControllerDelegate

extension VisualSearchViewController: UIImagePickerControllerDelegate {
    
    private func presentImageCropper(image: UIImage) {
        // resize image
        let newSize: CGSize
        let maxLength: CGFloat = 600
        let ratio: CGFloat = image.size.width / image.size.height
        switch true {
        case ratio > 1:
            newSize = CGSize(width: maxLength, height: maxLength / ratio)
        case ratio < 1:
            newSize = CGSize(width: maxLength * ratio, height: maxLength)
        default: // ratio == 1
            newSize = CGSize(width: maxLength, height: maxLength)
        }
        
        self.present(self.customCropController(image: image.resizeImage(newSize.width, opaque: false)), animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        picker.dismiss(animated: true, completion: nil)
        guard let pickedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
            return
        }
        self.presentImageCropper(image: pickedImage)
        
    }
    
}

// MARK: AVCapturePhotoCaptureDelegate

extension VisualSearchViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                     previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                     resolvedSettings: AVCaptureResolvedPhotoSettings,
                     bracketSettings: AVCaptureBracketedStillImageSettings?,
                     error: Error?) {
        guard error == nil, let photoSampleBuffer = photoSampleBuffer else {
            print("Error capturing photo: \(String(describing: error))")
            return
        }
        
        self.photoSampleBuffer = photoSampleBuffer
        self.photoPreviewSampleBuffer = previewPhotoSampleBuffer
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                     didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
                     error: Error?) {
        guard error == nil else {
            print("Error in capture process: \(String(describing: error))")
            return
        }
        
        if let photoSampleBuffer = self.photoSampleBuffer {
            
            // process and save photo
            self.saveSampleBufferToPhotoLibrary(photoSampleBuffer,
                                                previewSampleBuffer: self.photoPreviewSampleBuffer,
                                                completionHandler: { success, error in
                                                    if !success {
                                                        print("Error adding JPEG photo to library: \(String(describing: error))")
                                                    }
            })
        }
    }
}

// MARK: - ImageCropViewControllerDelegate
// custom image cropper has an issue with image orientation. see imageCropper class for details
extension VisualSearchViewController: ImageCropViewControllerDelegate {
    
    // debugbing function to display cropped image taken by camera before sending it the API
    private func debugOutput(image: UIImage) {
        let t = UIImageView(frame: self.view.frame)
        t.contentMode = .scaleAspectFit
        t.image = image
        print("image", image.size, t.frame)
        self.view.addSubview(t)
    }
    
    func didCropImage(image: UIImage, controler: ImageCropViewController) {
        DispatchQueue.main.async {
            //self.debugOutput(image: image)
            controler.dismiss(animated: false, completion: {
                DispatchQueue.main.async {
                    self.delegate?.requestSearch(sender: self, query: image)
                }
            })
        }
    }
    
    func didCancelCropping(controler: ImageCropViewController) {
        DispatchQueue.main.async {
            controler.dismiss(animated: false, completion: nil)
        }
    }
}


//MARK: - AVCaptureMetadataOutputObjectsDelegate
extension VisualSearchViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        guard
            !isPresentingDetectedProduct,
            let metadataObject = metadataObjects.first,
            let _ = metadataObject as? AVMetadataMachineReadableCodeObject,
            let _ = (metadataObject as! AVMetadataMachineReadableCodeObject).stringValue,
            let url = URL(string: (metadataObject as! AVMetadataMachineReadableCodeObject).stringValue!),
            let name = self.metadataProviderName(url: url)
            else { return }
        
        // show notification
        DispatchQueue.main.async {
            let item: Item = Item(
                brandId: "",
                brand: name,
                name: "",
                url: url,
                id: "random",
                prices: [Price(value: 0,
                localeIdentifier: User.shared.preferredLocale.identifier)],
                state: .active,
                shareUrl: url
            ) // dummy item
            
            self.isPresentingDetectedProduct = true
            let banner: NotificationBanner = NotificationBanner(title: "Tap to see more information", subtitle: "Product identified", url: url)
            banner.autoDismiss = false
            banner.onTap = {
                DispatchQueue.main.async {
                    banner.dismiss()
                    self.delegate?.requestItemWeb(item: item)
                }
            }
            banner.onSwipeUp = {
                DispatchQueue.main.async {
                    banner.dismiss()
                }
                self.isPresentingDetectedProduct = false
            }
            
            banner.show()
        }
        
    }
}

//MARK: - SearchResultDelegate

extension VisualSearchViewController: SearchResultDelegate {
    func dismiss(sender: SearchResultViewController) {
        sender.dismiss(animated: false, completion: nil)
    }
    func updatedSettings(value: ItemListSettings) {
        
    }
}

//MARK : VideoOrientation Helper
extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
    
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}

extension AVCaptureDevice.DiscoverySession {
    var uniqueDevicePositionsCount: Int {
        var uniqueDevicePositions: [AVCaptureDevice.Position] = []
        
        for device in devices {
            if !uniqueDevicePositions.contains(device.position) {
                uniqueDevicePositions.append(device.position)
            }
        }
        
        return uniqueDevicePositions.count
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
