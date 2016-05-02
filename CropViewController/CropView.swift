//
//  CropView.swift
//  CropViewController
//
//  Created by Guilherme Moura on 2/25/16.
//  Copyright © 2016 Reefactor, Inc. All rights reserved.
//

import UIKit
import AVFoundation

public class CropView: UIView, UIScrollViewDelegate, UIGestureRecognizerDelegate, CropRectViewDelegate {
    public var image: UIImage? {
        didSet {
            if image != nil {
                imageSize = image!.size
            }
            imageView?.removeFromSuperview()
            imageView = nil
            zoomingView?.removeFromSuperview()
            zoomingView = nil
            setNeedsLayout()
        }
    }
    public var imageView: UIView? {
        didSet {
            if let view = imageView where image == nil {
                imageSize = view.frame.size
            }
            usingCustomImageView = true
            setNeedsLayout()
        }
    }
    public var croppedImage: UIImage? {
        return image?.rotatedImageWithTransform(rotation, croppedToRect: zoomedCropRect())
    }
    public var keepAspectRatio = false {
        didSet {
            cropRectView.keepAspectRatio = keepAspectRatio
        }
    }
    public var cropAspectRatio: CGFloat {
        set {
            layoutIfNeeded()
            setCropAspectRatio(newValue, shouldCenter: true)
        }
        get {
            let rect = scrollView.frame
            let width = CGRectGetWidth(rect)
            let height = CGRectGetHeight(rect)
            return width / height
        }
    }
    public var rotation: CGAffineTransform {
        guard let imgView = imageView else {
            return CGAffineTransformIdentity
        }
        return imgView.transform
    }
    public var rotationAngle: CGFloat {
        set {
            imageView?.transform = CGAffineTransformMakeRotation(newValue)
        }
        get {
            return atan2(rotation.b, rotation.a)
        }
    }
    public var cropRect: CGRect {
        set {
            zoomToCropRect(newValue)
        }
        get {
            return scrollView.frame
        }
    }
    public var imageCropRect = CGRectZero {
        didSet {
            resetCropRect()
            
            let scale = min(CGRectGetWidth(scrollView.frame) / imageSize.width, CGRectGetHeight(scrollView.frame) / imageSize.height)
            let x = CGRectGetMinX(imageCropRect) * scale + CGRectGetMinX(scrollView.frame)
            let y = CGRectGetMinY(imageCropRect) * scale + CGRectGetMinY(scrollView.frame)
            let width = CGRectGetWidth(imageCropRect) * scale
            let height = CGRectGetHeight(imageCropRect) * scale
            
            let rect = CGRect(x: x, y: y, width: width, height: height)
            let intersection = CGRectIntersection(rect, scrollView.frame)
            
            if !CGRectIsNull(intersection) {
                cropRect = intersection
            }
        }
    }
    public var resizeEnabled = true {
        didSet {
            cropRectView.enableResizing(resizeEnabled)
        }
    }
    public var showCroppedArea = true {
        didSet {
            layoutIfNeeded()
            scrollView.clipsToBounds = !showCroppedArea
            showOverlayView(showCroppedArea)
        }
    }
    public var rotationGestureRecognizer: UIRotationGestureRecognizer!
    private var imageSize = CGSize(width: 1.0, height: 1.0)
    private var scrollView: UIScrollView!
    private var zoomingView: UIView?
    private let cropRectView = CropRectView()
    private let topOverlayView = UIView()
    private let leftOverlayView = UIView()
    private let rightOverlayView = UIView()
    private let bottomOverlayView = UIView()
    private var insetRect = CGRectZero
    private var editingRect = CGRectZero
    private var interfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
    private var resizing = false
    private var usingCustomImageView = false
    private let MarginTop: CGFloat = 37.0
    private let MarginLeft: CGFloat = 20.0

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {
        autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        backgroundColor = UIColor.clearColor()
        
        scrollView = UIScrollView(frame: bounds)
        scrollView.delegate = self
        scrollView.autoresizingMask = [.FlexibleTopMargin, .FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleRightMargin]
        scrollView.backgroundColor = UIColor.clearColor()
        scrollView.maximumZoomScale = 20.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        scrollView.bouncesZoom = false
        scrollView.clipsToBounds =  false
        addSubview(scrollView)
        
        rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(CropView.handleRotation(_:)))
        rotationGestureRecognizer?.delegate = self
        scrollView.addGestureRecognizer(rotationGestureRecognizer)
        
        cropRectView.delegate = self
        addSubview(cropRectView)
        
        showOverlayView(showCroppedArea)
        addSubview(topOverlayView)
        addSubview(leftOverlayView)
        addSubview(rightOverlayView)
        addSubview(bottomOverlayView)
    }
    
    public override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        if !userInteractionEnabled {
            return nil
        }
        
        if let hitView = cropRectView.hitTest(convertPoint(point, toView: cropRectView), withEvent: event) {
            return hitView
        }
        let locationInImageView = convertPoint(point, toView: zoomingView)
        let zoomedPoint = CGPoint(x: locationInImageView.x * scrollView.zoomScale, y: locationInImageView.y * scrollView.zoomScale)
        if CGRectContainsPoint(zoomingView!.frame, zoomedPoint) {
            return scrollView
        }
        return super.hitTest(point, withEvent: event)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let interfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
        
        if image == nil && imageView == nil {
            return
        }
        
        setupEditingRect()

        if imageView == nil {
            if UIInterfaceOrientationIsPortrait(interfaceOrientation) {
                insetRect = CGRectInset(bounds, MarginLeft, MarginTop)
            } else {
                insetRect = CGRectInset(bounds, MarginLeft, MarginLeft)
            }
            if !showCroppedArea {
                insetRect = editingRect
            }
            setupZoomingView()
            setupImageView()
        } else if usingCustomImageView {
            if UIInterfaceOrientationIsPortrait(interfaceOrientation) {
                insetRect = CGRectInset(bounds, MarginLeft, MarginTop)
            } else {
                insetRect = CGRectInset(bounds, MarginLeft, MarginLeft)
            }
            if !showCroppedArea {
                insetRect = editingRect
            }
            setupZoomingView()
            imageView?.frame = zoomingView!.bounds
            zoomingView?.addSubview(imageView!)
            usingCustomImageView = false
        }
        
        if !resizing {
            layoutCropRectViewWithCropRect(scrollView.frame)
            if self.interfaceOrientation != interfaceOrientation {
                zoomToCropRect(scrollView.frame)
            }
        }
        
        
        self.interfaceOrientation = interfaceOrientation
    }
    
    public func setRotationAngle(rotationAngle: CGFloat, snap: Bool) {
        var rotation = rotationAngle
        if snap {
            rotation = nearbyint(rotationAngle / CGFloat(M_PI_2)) * CGFloat(M_PI_2)
        }
        self.rotationAngle = rotation
    }
    
    public func resetCropRect() {
        resetCropRectAnimated(false)
    }
    
    public func resetCropRectAnimated(animated: Bool) {
        if animated {
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(0.25)
            UIView.setAnimationBeginsFromCurrentState(true)
        }
        imageView?.transform = CGAffineTransformIdentity
        let contentSize = scrollView.contentSize
        let initialRect = CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height)
        scrollView.zoomToRect(initialRect, animated: false)
        
        layoutCropRectViewWithCropRect(scrollView.bounds)
        
        if animated {
            UIView.commitAnimations()
        }
    }
    
    public func zoomedCropRect() -> CGRect {
        let cropRect = convertRect(scrollView.frame, toView: zoomingView)
        var ratio: CGFloat = 1.0
        let orientation = UIApplication.sharedApplication().statusBarOrientation
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad || UIInterfaceOrientationIsPortrait(orientation)) {
            ratio = CGRectGetWidth(AVMakeRectWithAspectRatioInsideRect(imageSize, insetRect)) / imageSize.width
        } else {
            ratio = CGRectGetHeight(AVMakeRectWithAspectRatioInsideRect(imageSize, insetRect)) / imageSize.height
        }
        
        let zoomedCropRect = CGRect(x: cropRect.origin.x / ratio,
            y: cropRect.origin.y / ratio,
            width: cropRect.size.width / ratio,
            height: cropRect.size.height / ratio)
        
        return zoomedCropRect
    }
    
    public func croppedImage(image: UIImage) -> UIImage {
        imageSize = image.size
        return image.rotatedImageWithTransform(rotation, croppedToRect: zoomedCropRect())
    }
    
    func handleRotation(gestureRecognizer: UIRotationGestureRecognizer) {
        if let imageView = imageView {
            let rotation = gestureRecognizer.rotation
            let transform = CGAffineTransformRotate(imageView.transform, rotation)
            imageView.transform = transform
            gestureRecognizer.rotation = 0.0
        }
        
        switch gestureRecognizer.state {
        case .Began, .Changed:
            cropRectView.showsGridMinor = true
        default:
            cropRectView.showsGridMinor = false
        }
    }
    
    // MARK: - Private methods
    private func showOverlayView(show: Bool) {
        let color = show ? UIColor(white: 0.0, alpha: 0.4) : UIColor.clearColor()
        
        topOverlayView.backgroundColor = color
        leftOverlayView.backgroundColor = color
        rightOverlayView.backgroundColor = color
        bottomOverlayView.backgroundColor = color
    }
    
    private func setupEditingRect() {
        let interfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
        if UIInterfaceOrientationIsPortrait(interfaceOrientation) {
            editingRect = CGRectInset(bounds, MarginLeft, MarginTop)
        } else {
            editingRect = CGRectInset(bounds, MarginLeft, MarginLeft)
        }
        if !showCroppedArea {
            editingRect = bounds
        }
    }
    
    private func setupZoomingView() {
        var cropRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        cropRect = AVMakeRectWithAspectRatioInsideRect(imageSize, insetRect)
        
        scrollView.frame = cropRect
        scrollView.contentSize = cropRect.size
        
        zoomingView = UIView(frame: scrollView.bounds)
        zoomingView?.backgroundColor = UIColor.clearColor()
        scrollView.addSubview(zoomingView!)
    }

    private func setupImageView() {
        let imageView = UIImageView(frame: zoomingView!.bounds)
        imageView.backgroundColor = UIColor.clearColor()
        imageView.contentMode = .ScaleAspectFit
        imageView.image = image
        zoomingView?.addSubview(imageView)
        self.imageView = imageView
        usingCustomImageView = false
    }
    
    private func layoutCropRectViewWithCropRect(cropRect: CGRect) {
        cropRectView.frame = cropRect
        layoutOverlayViewsWithCropRect(cropRect)
    }
    
    private func layoutOverlayViewsWithCropRect(cropRect: CGRect) {
        topOverlayView.frame = CGRect(x: 0, y: 0, width: CGRectGetWidth(bounds), height: CGRectGetMinY(cropRect))
        leftOverlayView.frame = CGRect(x: 0, y: CGRectGetMinY(cropRect), width: CGRectGetMinX(cropRect), height: CGRectGetHeight(cropRect))
        rightOverlayView.frame = CGRect(x: CGRectGetMaxX(cropRect), y: CGRectGetMinY(cropRect), width: CGRectGetWidth(bounds) - CGRectGetMaxX(cropRect), height: CGRectGetHeight(cropRect))
        bottomOverlayView.frame = CGRect(x: 0, y: CGRectGetMaxY(cropRect), width: CGRectGetWidth(bounds), height: CGRectGetHeight(bounds) - CGRectGetMaxY(cropRect))
    }
    
    private func zoomToCropRect(toRect: CGRect) {
        zoomToCropRect(toRect, shouldCenter: false)
    }
    
    private func zoomToCropRect(toRect: CGRect, shouldCenter: Bool) {
        if CGRectEqualToRect(scrollView.frame, toRect) {
            return
        }
        
        let width = CGRectGetWidth(toRect)
        let height = CGRectGetHeight(toRect)
        let scale = min(CGRectGetWidth(editingRect) / width, CGRectGetHeight(editingRect) / height)
        
        let scaledWidth = width * scale
        let scaledHeight = height * scale
        let cropRect = CGRect(x: (CGRectGetWidth(bounds) - scaledWidth) / 2.0, y: (CGRectGetHeight(bounds) - scaledHeight) / 2.0, width: scaledWidth, height: scaledHeight)
        
        var zoomRect = convertRect(toRect, toView: zoomingView)
        zoomRect.size.width = CGRectGetWidth(cropRect) / (scrollView.zoomScale * scale)
        zoomRect.size.height = CGRectGetHeight(cropRect) / (scrollView.zoomScale * scale)
        
        if let imgView = imageView where shouldCenter {
            let imageViewBounds = imgView.bounds
            zoomRect.origin.x = (CGRectGetWidth(imageViewBounds) / 2.0) - (CGRectGetWidth(zoomRect) / 2.0)
            zoomRect.origin.y = (CGRectGetHeight(imageViewBounds) / 2.0) - (CGRectGetHeight(zoomRect) / 2.0)
        }
        
        UIView.animateWithDuration(0.25, delay: 0.0, options: .BeginFromCurrentState, animations: { [unowned self] in
            self.scrollView.bounds = cropRect
            self.scrollView.zoomToRect(zoomRect, animated: false)
            self.layoutCropRectViewWithCropRect(cropRect)
            }, completion: nil)
    }
    
    private func cappedCropRectInImageRectWithCropRectView(cropRectView: CropRectView) -> CGRect {
        var cropRect = cropRectView.frame
        
        let rect = convertRect(cropRect, toView: scrollView)
        if CGRectGetMinX(rect) < CGRectGetMinX(zoomingView!.frame) {
            cropRect.origin.x = CGRectGetMinX(scrollView.convertRect(zoomingView!.frame, toView: self))
            let cappedWidth = CGRectGetMaxX(rect)
            let height = !keepAspectRatio ? cropRect.size.height : cropRect.size.height * (cappedWidth / cropRect.size.width)
            cropRect.size = CGSize(width: cappedWidth, height: height)
        }
        
        if CGRectGetMinY(rect) < CGRectGetMinY(zoomingView!.frame) {
            cropRect.origin.y = CGRectGetMinY(scrollView.convertRect(zoomingView!.frame, toView: self))
            let cappedHeight = CGRectGetMaxY(rect)
            let width = !keepAspectRatio ? cropRect.size.width : cropRect.size.width * (cappedHeight / cropRect.size.height)
            cropRect.size = CGSize(width: width, height: cappedHeight)
        }
        
        if CGRectGetMaxX(rect) > CGRectGetMaxX(zoomingView!.frame) {
            let cappedWidth = CGRectGetMaxX(scrollView.convertRect(zoomingView!.frame, toView: self)) - CGRectGetMinX(cropRect)
            let height = !keepAspectRatio ? cropRect.size.height : cropRect.size.height * (cappedWidth / cropRect.size.width)
            cropRect.size = CGSize(width: cappedWidth, height: height)
        }
        
        if CGRectGetMaxY(rect) > CGRectGetMaxY(zoomingView!.frame) {
            let cappedHeight = CGRectGetMaxY(scrollView.convertRect(zoomingView!.frame, toView: self)) - CGRectGetMinY(cropRect)
            let width = !keepAspectRatio ? cropRect.size.width : cropRect.size.width * (cappedHeight / cropRect.size.height)
            cropRect.size = CGSize(width: width, height: cappedHeight)
        }
        
        return cropRect
    }
    
    private func automaticZoomIfEdgeTouched(cropRect: CGRect) {
        if CGRectGetMinX(cropRect) < CGRectGetMinX(editingRect) - 5.0 ||
            CGRectGetMaxX(cropRect) > CGRectGetMaxX(editingRect) + 5.0 ||
            CGRectGetMinY(cropRect) < CGRectGetMinY(editingRect) - 5.0 ||
            CGRectGetMaxY(cropRect) > CGRectGetMaxY(editingRect) + 5.0 {
                UIView.animateWithDuration(1.0, delay: 0.0, options: .BeginFromCurrentState, animations: { [unowned self] in
                    self.zoomToCropRect(self.cropRectView.frame)
                    }, completion: nil)
        }
    }
    
    private func setCropAspectRatio(ratio: CGFloat, shouldCenter: Bool) {
        var cropRect = scrollView.frame
        var width = CGRectGetWidth(cropRect)
        var height = CGRectGetHeight(cropRect)
        if ratio <= 1.0 {
            width = height * ratio
            if width > CGRectGetWidth(imageView!.bounds) {
                width = CGRectGetWidth(cropRect)
                height = width / ratio
            }
        } else {
            height = width / ratio
            if height > CGRectGetHeight(imageView!.bounds) {
                height = CGRectGetHeight(cropRect)
                width = height * ratio
            }
        }
        cropRect.size = CGSize(width: width, height: height)
        zoomToCropRect(cropRect, shouldCenter: shouldCenter)
    }
    
    // MARK: - CropView delegate methods
    func cropRectViewDidBeginEditing(view: CropRectView) {
        resizing = true
    }
    
    func cropRectViewDidChange(view: CropRectView) {
        let cropRect = cappedCropRectInImageRectWithCropRectView(view)
        layoutCropRectViewWithCropRect(cropRect)
        automaticZoomIfEdgeTouched(cropRect)
    }
    
    func cropRectViewDidEndEditing(view: CropRectView) {
        resizing = false
        zoomToCropRect(cropRectView.frame)
    }
    
    // MARK: - ScrollView delegate methods
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return zoomingView
    }
    
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let contentOffset = scrollView.contentOffset
        targetContentOffset.memory = contentOffset
    }
    
    // MARK: - Gesture Recognizer delegate methods
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
