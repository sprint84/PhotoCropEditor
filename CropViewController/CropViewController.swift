//
//  CropViewController.swift
//  CropViewController
//
//  Created by Guilherme Moura on 2/25/16.
//  Copyright © 2016 Reefactor, Inc. All rights reserved.
//

import UIKit

@objc public protocol CropViewControllerDelegate: class {
    optional func cropViewController(controller: CropViewController, didFinishCroppingImage image: UIImage)
    optional func cropViewController(controller: CropViewController, didFinishCroppingImage image: UIImage, transform: CGAffineTransform, cropRect: CGRect)
    optional func cropViewControllerDidCancel(controller: CropViewController)
}

public class CropViewController: UIViewController {
    public weak var delegate: CropViewControllerDelegate?
    public var image: UIImage? {
        didSet {
            cropView?.image = image
        }
    }
    public var keepAspectRatio = false {
        didSet {
            cropView?.keepAspectRatio = keepAspectRatio
        }
    }
    public var cropAspectRatio: CGFloat = 0.0 {
        didSet {
            cropView?.cropAspectRatio = cropAspectRatio
        }
    }
    public var cropRect = CGRectZero {
        didSet {
            adjustCropRect()
        }
    }
    public var imageCropRect = CGRectZero {
        didSet {
            cropView?.imageCropRect = imageCropRect
        }
    }
    public var toolbarHidden = false
    public var rotationEnabled = false {
        didSet {
            cropView?.rotationGestureRecognizer.enabled = rotationEnabled
        }
    }
    public var rotationTransform: CGAffineTransform {
        return cropView!.rotation
    }
    public var zoomedCropRect: CGRect {
        return cropView!.zoomedCropRect()
    }

    private var cropView: CropView?
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        initialize()
    }
    
    private func initialize() {
        rotationEnabled = true
    }
    
    public override func loadView() {
        let contentView = UIView()
        contentView.autoresizingMask = .FlexibleWidth
        contentView.backgroundColor = UIColor.blackColor()
        view = contentView
        
        // Add CropView
        cropView = CropView(frame: contentView.bounds)
        contentView.addSubview(cropView!)
        
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.translucent = false
        navigationController?.toolbar.translucent = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel:")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "finish:")
        
        if self.toolbarItems == nil {
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            let constrainButton = UIBarButtonItem(title: "Constrain", style: .Plain, target: self, action: "constrain:")
            toolbarItems = [flexibleSpace, constrainButton, flexibleSpace]
        }
        
        navigationController?.toolbarHidden = toolbarHidden
        
        cropView?.image = image
        cropView?.rotationGestureRecognizer.enabled = rotationEnabled
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if cropAspectRatio != 0 {
            cropView?.cropAspectRatio = cropAspectRatio
        }
        
        if !CGRectEqualToRect(cropRect, CGRectZero) {
            adjustCropRect()
        }
        
        if !CGRectEqualToRect(imageCropRect, CGRectZero) {
            cropView?.imageCropRect = imageCropRect
        }
        
        cropView?.keepAspectRatio = keepAspectRatio
    }
    
    public func resetCropRect() {
        cropView?.resetCropRect()
    }
    
    public func resetCropRectAnimated(animated: Bool) {
        cropView?.resetCropRectAnimated(animated)
    }
    
    func cancel(sender: UIBarButtonItem) {
        delegate?.cropViewControllerDidCancel?(self)
    }
    
//    func finish(sender: UIBarButtonItem) {
//        if let image = cropView?.croppedImage {
//            delegate?.cropViewController?(self, didFinishCroppingImage: image)
//            delegate?.cropViewController?(self, didFinishCroppingImage: image, transform: cropView!.rotation, cropRect: cropView!.zoomedCropRect())
//        }
//    }
    
    func constrain(sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let original = UIAlertAction(title: "Original", style: .Default) { [unowned self] action in
            guard let image = self.cropView?.image else {
                return
            }
            guard var cropRect = self.cropView?.cropRect else {
                return
            }
            let width = image.size.width
            let height = image.size.height
            let ratio: CGFloat
            if width < height {
                ratio = width / height
                cropRect.size = CGSize(width: CGRectGetHeight(cropRect) * ratio, height: CGRectGetHeight(cropRect))
            } else {
                ratio = height / width
                cropRect.size = CGSize(width: CGRectGetWidth(cropRect), height: CGRectGetWidth(cropRect) * ratio)
            }
            self.cropView?.cropRect = cropRect
        }
        actionSheet.addAction(original)
        let square = UIAlertAction(title: "Square", style: .Default) { [unowned self] action in
            self.cropView?.cropAspectRatio = 1.0
        }
        actionSheet.addAction(square)
        let threeByTwo = UIAlertAction(title: "3 x 2", style: .Default) { [unowned self] action in
            self.cropView?.cropAspectRatio = 2.0 / 3.0
        }
        actionSheet.addAction(threeByTwo)
        let threeByFive = UIAlertAction(title: "3 x 5", style: .Default) { [unowned self] action in
            self.cropView?.cropAspectRatio = 3.0 / 5.0
        }
        actionSheet.addAction(threeByFive)
        let fourByThree = UIAlertAction(title: "4 x 3", style: .Default) { [unowned self] action in
            self.cropView?.cropAspectRatio = 3.0 / 4.0
        }
        actionSheet.addAction(fourByThree)
        let fourBySix = UIAlertAction(title: "4 x 6", style: .Default) { [unowned self] action in
            self.cropView?.cropAspectRatio = 4.0 / 6.0
        }
        actionSheet.addAction(fourBySix)
        let fiveBySeven = UIAlertAction(title: "5 x 7", style: .Default) { [unowned self] action in
            self.cropView?.cropAspectRatio = 5.0 / 7.0
        }
        actionSheet.addAction(fiveBySeven)
        let eightByTen = UIAlertAction(title: "8 x 10", style: .Default) { [unowned self] action in
            self.cropView?.cropAspectRatio = 8.0 / 10.0
        }
        actionSheet.addAction(eightByTen)
        let widescreen = UIAlertAction(title: "16 x 9", style: .Default) { [unowned self] action in
            self.cropView?.cropAspectRatio = 9.0 / 16.0
        }
        actionSheet.addAction(widescreen)
        let cancel = UIAlertAction(title: "Cancel", style: .Default) { [unowned self] action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        actionSheet.addAction(cancel)
        
        presentViewController(actionSheet, animated: true, completion: nil)
    }

    // MARK: - Private methods
    private func adjustCropRect() {
        imageCropRect = CGRectZero
        
        guard var cropViewCropRect = cropView?.cropRect else {
            return
        }
        cropViewCropRect.origin.x += cropRect.origin.x
        cropViewCropRect.origin.y += cropRect.origin.y
        
        let minWidth = min(CGRectGetMaxX(cropViewCropRect) - CGRectGetMinX(cropViewCropRect), CGRectGetWidth(cropRect))
        let minHeight = min(CGRectGetMaxY(cropViewCropRect) - CGRectGetMinY(cropViewCropRect), CGRectGetHeight(cropRect))
        let size = CGSize(width: minWidth, height: minHeight)
        cropViewCropRect.size = size
        cropView?.cropRect = cropViewCropRect
    }
    
    

}
