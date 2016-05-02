
//
//  CropRectView.swift
//  CropViewController
//
//  Created by Guilherme Moura on 2/26/16.
//  Copyright © 2016 Reefactor, Inc. All rights reserved.
//

import UIKit

protocol CropRectViewDelegate: class {
    func cropRectViewDidBeginEditing(view: CropRectView)
    func cropRectViewDidChange(view: CropRectView)
    func cropRectViewDidEndEditing(view: CropRectView)
}

class CropRectView: UIView, ResizeControlDelegate {
    weak var delegate: CropRectViewDelegate?
    var showsGridMajor = true {
        didSet {
            setNeedsDisplay()
        }
    }
    var showsGridMinor = false {
        didSet {
            setNeedsDisplay()
        }
    }
    var keepAspectRatio = false {
        didSet {
            if keepAspectRatio {
                let width = CGRectGetWidth(bounds)
                let height = CGRectGetHeight(bounds)
                fixedAspectRatio = min(width / height, height / width)
            }
        }
    }
    
    private var resizeImageView: UIImageView!
    private let topLeftCornerView = ResizeControl()
    private let topRightCornerView = ResizeControl()
    private let bottomLeftCornerView = ResizeControl()
    private let bottomRightCornerView = ResizeControl()
    private let topEdgeView = ResizeControl()
    private let leftEdgeView = ResizeControl()
    private let rightEdgeView = ResizeControl()
    private let bottomEdgeView = ResizeControl()
    private var initialRect = CGRectZero
    private var fixedAspectRatio: CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        backgroundColor = UIColor.clearColor()
        contentMode = .Redraw
        
        resizeImageView = UIImageView(frame: CGRectInset(bounds, -2.0, -2.0))
        resizeImageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        let bundle = NSBundle(forClass: self.dynamicType)
        let image = UIImage(named: "PhotoCropEditorBorder", inBundle: bundle, compatibleWithTraitCollection: nil)
        resizeImageView.image = image?.resizableImageWithCapInsets(UIEdgeInsets(top: 23.0, left: 23.0, bottom: 23.0, right: 23.0))
        addSubview(resizeImageView)
        
        topEdgeView.delegate = self
        addSubview(topEdgeView)
        leftEdgeView.delegate = self
        addSubview(leftEdgeView)
        rightEdgeView.delegate = self
        addSubview(rightEdgeView)
        bottomEdgeView.delegate = self
        addSubview(bottomEdgeView)
        
        topLeftCornerView.delegate = self
        addSubview(topLeftCornerView)
        topRightCornerView.delegate = self
        addSubview(topRightCornerView)
        bottomLeftCornerView.delegate = self
        addSubview(bottomLeftCornerView)
        bottomRightCornerView.delegate = self
        addSubview(bottomRightCornerView)
    }
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        for subview in subviews where subview is ResizeControl {
            if CGRectContainsPoint(subview.frame, point) {
                return subview
            }
        }
        return nil
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        let width = CGRectGetWidth(bounds)
        let height = CGRectGetHeight(bounds)
        
        for i in 0 ..< 3 {
            let borderPadding: CGFloat = 2.0
            
            if showsGridMinor {
                for j in 1 ..< 3 {
                    UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.3).set()
                    UIRectFill(CGRect(x: round((width / 9.0) * CGFloat(j) + (width / 3.0) * CGFloat(i)), y: borderPadding, width: 1.0, height: round(height) - borderPadding * 2.0))
                    UIRectFill(CGRect(x: borderPadding, y: round((height / 9.0) * CGFloat(j) + (height / 3.0) * CGFloat(i)), width: round(width) - borderPadding * 2.0, height: 1.0))
                }
            }
            
            if showsGridMajor {
                if i > 0 {
                    UIColor.whiteColor().set()
                    UIRectFill(CGRect(x: round(CGFloat(i) * width / 3.0), y: borderPadding, width: 1.0, height: round(height) - borderPadding * 2.0))
                    UIRectFill(CGRect(x: borderPadding, y: round(CGFloat(i) * height / 3.0), width: round(width) - borderPadding * 2.0, height: 1.0))
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        topLeftCornerView.frame.origin = CGPoint(x: CGRectGetWidth(topLeftCornerView.bounds) / -2.0, y: CGRectGetHeight(topLeftCornerView.bounds) / -2.0)
        topRightCornerView.frame.origin = CGPoint(x: CGRectGetWidth(bounds) - CGRectGetWidth(topRightCornerView.bounds) - 2.0, y: CGRectGetHeight(topRightCornerView.bounds) / -2.0)
        bottomLeftCornerView.frame.origin = CGPoint(x: CGRectGetWidth(bottomLeftCornerView.bounds) / -2.0, y: CGRectGetHeight(bounds) - CGRectGetHeight(bottomLeftCornerView.bounds) / 2.0)
        bottomRightCornerView.frame.origin = CGPoint(x: CGRectGetWidth(bounds) - CGRectGetWidth(bottomRightCornerView.bounds) / 2.0, y: CGRectGetHeight(bounds) - CGRectGetHeight(bottomRightCornerView.bounds) / 2.0)
        
        topEdgeView.frame = CGRect(x: CGRectGetMaxX(topLeftCornerView.frame), y: CGRectGetHeight(topEdgeView.frame) / -2.0, width: CGRectGetMinX(topRightCornerView.frame) - CGRectGetMaxX(topLeftCornerView.frame), height: CGRectGetHeight(topEdgeView.bounds))
        leftEdgeView.frame = CGRect(x: CGRectGetWidth(leftEdgeView.frame) / -2.0, y: CGRectGetMaxY(topLeftCornerView.frame), width: CGRectGetWidth(leftEdgeView.frame), height: CGRectGetMinY(bottomLeftCornerView.frame) - CGRectGetMaxY(topLeftCornerView.frame))
        bottomEdgeView.frame = CGRect(x: CGRectGetMaxX(bottomLeftCornerView.frame), y: CGRectGetMinY(bottomLeftCornerView.frame), width: CGRectGetMinX(bottomRightCornerView.frame) - CGRectGetMaxX(bottomLeftCornerView.frame), height: CGRectGetHeight(bottomEdgeView.frame))
        rightEdgeView.frame = CGRect(x: CGRectGetWidth(bounds) - CGRectGetWidth(rightEdgeView.frame) / 2.0, y: CGRectGetMaxY(topRightCornerView.frame), width: CGRectGetWidth(rightEdgeView.frame), height: CGRectGetMinY(bottomRightCornerView.frame) - CGRectGetMaxY(topRightCornerView.frame))
    }
    
    func enableResizing(enabled: Bool) {
        resizeImageView.hidden = !enabled
        
        topLeftCornerView.enabled = enabled
        topRightCornerView.enabled = enabled
        bottomLeftCornerView.enabled = enabled
        bottomRightCornerView.enabled = enabled
        
        topEdgeView.enabled = enabled
        leftEdgeView.enabled = enabled
        bottomEdgeView.enabled = enabled
        rightEdgeView.enabled = enabled
    }

    // MARK: - ResizeControl delegate methods
    func resizeControlDidBeginResizing(control: ResizeControl) {
        initialRect = frame
        delegate?.cropRectViewDidBeginEditing(self)
    }
    
    func resizeControlDidResize(control: ResizeControl) {
        frame = cropRectWithResizeControlView(control)
        delegate?.cropRectViewDidChange(self)
    }
    
    func resizeControlDidEndResizing(control: ResizeControl) {
        delegate?.cropRectViewDidEndEditing(self)
    }
    
    private func cropRectWithResizeControlView(resizeControl: ResizeControl) -> CGRect {
        var rect = frame
        
        if resizeControl == topEdgeView {
            rect = CGRect(x: CGRectGetMinX(initialRect),
                          y: CGRectGetMinY(initialRect) + resizeControl.translation.y,
                          width: CGRectGetWidth(initialRect),
                          height: CGRectGetHeight(initialRect) - resizeControl.translation.y)
            
            if keepAspectRatio {
                rect = constrainedRectWithRectBasisOfHeight(rect)
            }
        } else if resizeControl == leftEdgeView {
            rect = CGRect(x: CGRectGetMinX(initialRect) + resizeControl.translation.x,
                          y: CGRectGetMinY(initialRect),
                          width: CGRectGetWidth(initialRect) - resizeControl.translation.x,
                          height: CGRectGetHeight(initialRect))
            
            if keepAspectRatio {
                rect = constrainedRectWithRectBasisOfWidth(rect)
            }
        } else if resizeControl == bottomEdgeView {
            rect = CGRect(x: CGRectGetMinX(initialRect),
                          y: CGRectGetMinY(initialRect),
                          width: CGRectGetWidth(initialRect),
                          height: CGRectGetHeight(initialRect) + resizeControl.translation.y)
            
            if keepAspectRatio {
                rect = constrainedRectWithRectBasisOfHeight(rect)
            }
        } else if resizeControl == rightEdgeView {
            rect = CGRect(x: CGRectGetMinX(initialRect),
                          y: CGRectGetMinY(initialRect),
                          width: CGRectGetWidth(initialRect) + resizeControl.translation.x,
                          height: CGRectGetHeight(initialRect))
            
            if keepAspectRatio {
                rect = constrainedRectWithRectBasisOfWidth(rect)
            }
        } else if resizeControl == topLeftCornerView {
            rect = CGRect(x: CGRectGetMinX(initialRect) + resizeControl.translation.x,
                          y: CGRectGetMinY(initialRect) + resizeControl.translation.y,
                          width: CGRectGetWidth(initialRect) - resizeControl.translation.x,
                          height: CGRectGetHeight(initialRect) - resizeControl.translation.y)
            
            if keepAspectRatio {
                var constrainedFrame: CGRect
                if abs(resizeControl.translation.x) < abs(resizeControl.translation.y) {
                    constrainedFrame = constrainedRectWithRectBasisOfHeight(rect)
                } else {
                    constrainedFrame = constrainedRectWithRectBasisOfWidth(rect)
                }
                constrainedFrame.origin.x -= CGRectGetWidth(constrainedFrame) - CGRectGetWidth(rect)
                constrainedFrame.origin.y -= CGRectGetHeight(constrainedFrame) - CGRectGetHeight(rect)
                rect = constrainedFrame
            }
        } else if resizeControl == topRightCornerView {
            rect = CGRect(x: CGRectGetMinX(initialRect),
                          y: CGRectGetMinY(initialRect) + resizeControl.translation.y,
                          width: CGRectGetWidth(initialRect) + resizeControl.translation.x,
                          height: CGRectGetHeight(initialRect) - resizeControl.translation.y)
            
            if keepAspectRatio {
                if abs(resizeControl.translation.x) < abs(resizeControl.translation.y) {
                    rect = constrainedRectWithRectBasisOfHeight(rect)
                } else {
                    rect = constrainedRectWithRectBasisOfWidth(rect)
                }
            }
        } else if resizeControl == bottomLeftCornerView {
            rect = CGRect(x: CGRectGetMinX(initialRect) + resizeControl.translation.x,
                          y: CGRectGetMinY(initialRect),
                          width: CGRectGetWidth(initialRect) - resizeControl.translation.x,
                          height: CGRectGetHeight(initialRect) + resizeControl.translation.y)
            
            if keepAspectRatio {
                var constrainedFrame: CGRect
                if abs(resizeControl.translation.x) < abs(resizeControl.translation.y) {
                    constrainedFrame = constrainedRectWithRectBasisOfHeight(rect)
                } else {
                    constrainedFrame = constrainedRectWithRectBasisOfWidth(rect)
                }
                constrainedFrame.origin.x -= CGRectGetWidth(constrainedFrame) - CGRectGetWidth(rect)
                rect = constrainedFrame
            }
        } else if resizeControl == bottomRightCornerView {
            rect = CGRect(x: CGRectGetMinX(initialRect),
                          y: CGRectGetMinY(initialRect),
                          width: CGRectGetWidth(initialRect) + resizeControl.translation.x,
                          height: CGRectGetHeight(initialRect) + resizeControl.translation.y)
            
            if keepAspectRatio {
                if abs(resizeControl.translation.x) < abs(resizeControl.translation.y) {
                    rect = constrainedRectWithRectBasisOfHeight(rect)
                } else {
                    rect = constrainedRectWithRectBasisOfWidth(rect)
                }
            }
        }
        
        let minWidth = CGRectGetWidth(leftEdgeView.bounds) + CGRectGetWidth(rightEdgeView.bounds)
        if CGRectGetWidth(rect) < minWidth {
            rect.origin.x = CGRectGetMaxX(frame) - minWidth
            rect.size.width = minWidth
        }
        
        let minHeight = CGRectGetHeight(topEdgeView.bounds) + CGRectGetHeight(bottomEdgeView.bounds)
        if CGRectGetHeight(rect) < minHeight {
            rect.origin.y = CGRectGetMaxY(frame) - minHeight
            rect.size.height = minHeight
        }
        
        if fixedAspectRatio > 0 {
            var constraintedFrame = rect
            if CGRectGetWidth(rect) < minWidth {
                constraintedFrame.size.width = rect.size.height * (minWidth / rect.size.width)
            }
            if CGRectGetHeight(rect) < minHeight {
                constraintedFrame.size.height = rect.size.width * (minHeight / rect.size.height)
            }
            rect = constraintedFrame
        }
        
        return rect
    }
    
    private func constrainedRectWithRectBasisOfWidth(frame: CGRect) -> CGRect {
        var result = frame
        let width = CGRectGetWidth(frame)
        var height = CGRectGetHeight(frame)
        
        if width < height {
           height = width / fixedAspectRatio
        } else {
            height = width * fixedAspectRatio
        }
        result.size = CGSize(width: width, height: height)
        return result
    }
    
    private func constrainedRectWithRectBasisOfHeight(rect: CGRect) -> CGRect {
        var result = frame
        var width = CGRectGetWidth(frame)
        let height = CGRectGetHeight(frame)
        
        if width < height {
            width = height * fixedAspectRatio
        } else {
            width = height / fixedAspectRatio
        }
        result.size = CGSize(width: width, height: height)
        return result
    }
}
