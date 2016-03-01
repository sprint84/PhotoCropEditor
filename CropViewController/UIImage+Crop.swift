//
//  UIImage+Crop.swift
//  CropViewController
//
//  Created by Guilherme Moura on 2/26/16.
//  Copyright © 2016 Reefactor, Inc. All rights reserved.
//

import UIKit

extension UIImage {
    func rotatedImageWithTransform(rotation: CGAffineTransform, croppedToRect rect: CGRect) -> UIImage {
        let rotatedImage = rotatedImageWithTransform(rotation)
        
        let scale = rotatedImage.scale
        let cropRect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(scale, scale))
        
        let croppedImage = CGImageCreateWithImageInRect(rotatedImage.CGImage, cropRect)
        let image = UIImage(CGImage: croppedImage!, scale: self.scale, orientation: rotatedImage.imageOrientation)
        return image
    }
    
    private func rotatedImageWithTransform(transform: CGAffineTransform) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        let context = UIGraphicsGetCurrentContext()
        CGContextTranslateCTM(context, size.width / 2.0, size.height / 2.0)
        CGContextConcatCTM(context, transform)
        CGContextTranslateCTM(context, size.width / -2.0, size.height / -2.0)
        drawInRect(CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotatedImage
    }
}