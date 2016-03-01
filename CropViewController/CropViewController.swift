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
    public var image: UIImage?
    public var keepAspectRatio = false
    public var cropAspectRatio: CGFloat = 0.0 {
        didSet {
            cropView.cropAspectRatio = cropAspectRatio
        }
    }
    public var cropRect = CGRectZero
    public var imageCropRect = CGRectZero
    public var toolbarHidden = false
    public var rotationEnabled = false
    public private(set) var rotationTransform = CGAffineTransformIdentity
    public private(set) var zoomedCropRect = CGRectZero

    private var cropView: CropView!
    
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
        contentView.addSubview(cropView)
        
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.translucent = false
        navigationController?.toolbar.translucent = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel:")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "done:")
        
        if self.toolbarItems == nil {
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            let constrainButton = UIBarButtonItem(title: "Constrain", style: .Plain, target: self, action: "contrain:")
            toolbarItems = [flexibleSpace, constrainButton, flexibleSpace]
        }
        
        navigationController?.toolbarHidden = toolbarHidden
        
        cropView.image = image
        cropView.rotationGestureRecognizer.enabled = rotationEnabled
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if cropAspectRatio != 0 {
            cropView.cropAspectRatio = cropAspectRatio
        }
        
    }


    
    

}
