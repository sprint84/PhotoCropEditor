//
//  ViewController.swift
//  Example
//
//  Created by Guilherme Moura on 3/1/16.
//  Copyright © 2016 Reefactor, Inc. All rights reserved.
//

import UIKit
import PhotoCropEditor

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CropViewControllerDelegate {

    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateEditButtonEnabled()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func openEditor(sender: UIBarButtonItem?) {
        guard let image = imageView.image else {
            return
        }
//        let imgView = UIImageView(image: image)
//        imgView.frame = imageView.bounds
//        imgView.clipsToBounds = true
//        imgView.contentMode = .ScaleAspectFit
        
//        let cropView = CropView(frame: imageView.frame)
//        cropView.opaque = false
//        cropView.clipsToBounds = true
//        cropView.backgroundColor = UIColor.clearColor()
//        cropView.imageView = imgView
//        view.insertSubview(cropView, aboveSubview: imageView)
        
        let controller = CropViewController()
        controller.delegate = self
        controller.image = image
        
        let navController = UINavigationController(rootViewController: controller)
        presentViewController(navController, animated: true, completion: nil)
    }

    @IBAction func cameraButtonAction(sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .Default) { action in
            self.showCamera()
        }
        actionSheet.addAction(cameraAction)
        let albumAction = UIAlertAction(title: "Photo Library", style: .Default) { action in
            self.openPhotoAlbum()
        }
        actionSheet.addAction(albumAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { action in
            self.openPhotoAlbum()
        }
        actionSheet.addAction(cancelAction)
        presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func showCamera() {
        let controller = UIImagePickerController()
        controller.delegate = self
        controller.sourceType = .Camera
        presentViewController(controller, animated: true, completion: nil)
    }
    
    func openPhotoAlbum() {
        let controller = UIImagePickerController()
        controller.delegate = self
        controller.sourceType = .PhotoLibrary
        presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: - Private methods
    private func updateEditButtonEnabled() {
        editButton.enabled = self.imageView.image != nil
    }
    
    // MARK: - CropView
    func cropViewController(controller: CropViewController, didFinishCroppingImage image: UIImage) {
//        controller.dismissViewControllerAnimated(true, completion: nil)
//        imageView.image = image
//        updateEditButtonEnabled()
    }
    
    func cropViewController(controller: CropViewController, didFinishCroppingImage image: UIImage, transform: CGAffineTransform, cropRect: CGRect) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        imageView.image = image
        updateEditButtonEnabled()
    }
    
    func cropViewControllerDidCancel(controller: CropViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        updateEditButtonEnabled()
    }
    
    // MARK: - UIImagePickerController delegate methods
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            dismissViewControllerAnimated(true, completion: nil)
            return
        }
        imageView.image = image
        
        dismissViewControllerAnimated(true) { [unowned self] in
            self.openEditor(nil)
        }
    }
}

