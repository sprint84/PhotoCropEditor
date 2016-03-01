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
        
        topLeftCornerView.delegate = self
        addSubview(topLeftCornerView)
        topRightCornerView.delegate = self
        addSubview(topRightCornerView)
        bottomLeftCornerView.delegate = self
        addSubview(bottomLeftCornerView)
        bottomRightCornerView.delegate = self
        addSubview(bottomRightCornerView)
        
        topEdgeView.delegate = self
        addSubview(topEdgeView)
        leftEdgeView.delegate = self
        addSubview(leftEdgeView)
        rightEdgeView.delegate = self
        addSubview(rightEdgeView)
        bottomEdgeView.delegate = self
        addSubview(bottomEdgeView)
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
                          width: CGRectGetWidth(initialRect) + resizeControl.translation.x,
                          height: CGRectGetHeight(initialRect) - resizeControl.translation.y)
            
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
