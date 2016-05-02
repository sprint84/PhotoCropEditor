//
//  ResizeControl.swift
//  CropViewController
//
//  Created by Guilherme Moura on 2/26/16.
//  Copyright © 2016 Reefactor, Inc. All rights reserved.
//

import UIKit

protocol ResizeControlDelegate: class {
    func resizeControlDidBeginResizing(control: ResizeControl)
    func resizeControlDidResize(control: ResizeControl)
    func resizeControlDidEndResizing(control: ResizeControl)
}

class ResizeControl: UIView {
    weak var delegate: ResizeControlDelegate?
    var translation = CGPointZero
    var enabled = true
    private var startPoint = CGPointZero

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: frame.origin.x, y: frame.origin.y, width: 44.0, height: 44.0))
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(frame: CGRect(x: 0, y: 0, width: 44.0, height: 44.0))
        initialize()
    }
    
    private func initialize() {
        backgroundColor = UIColor.clearColor()
        exclusiveTouch = true
        
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ResizeControl.handlePan(_:)))
        addGestureRecognizer(gestureRecognizer)
    }
    
    func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        if !enabled {
            return
        }
        
        switch gestureRecognizer.state {
        case .Began:
            let translation = gestureRecognizer.translationInView(superview)
            startPoint = CGPoint(x: round(translation.x), y: round(translation.y))
            delegate?.resizeControlDidBeginResizing(self)
        case .Changed:
            let translation = gestureRecognizer.translationInView(superview)
            self.translation = CGPoint(x: round(startPoint.x + translation.x), y: round(startPoint.y + translation.y))
            delegate?.resizeControlDidResize(self)
        case .Ended, .Cancelled:
            delegate?.resizeControlDidEndResizing(self)
        default: ()
        }
        
    }
}
