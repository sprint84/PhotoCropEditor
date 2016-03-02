
# CropViewController [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![GitHub release](https://img.shields.io/badge/Release-v1.0-brightgreen.svg)]()

This project is a Swift translation of the [PEPhotoCropEditor](https://github.com/kishikawakatsumi/PEPhotoCropEditor). Version 1.0 doesn't add anything new, or fixes existing bugs. I want to slowly iterate on that, and if you want to contribute, let me know.

## Check it out

To run the example project, clone the repo, and open the 'Example/Example.xcodeproj' file.

## Requirements

This component is written using Swift and Dynamic Frameworks, so iOS 8.x is required. However you may want to manually import the source files into your project, if you need to support 7.x.

## Installation

ProgressButton is available through [Carthage](https://github.com/Carthage/Carthage). To install
it, simply add the following line to your Cartfile:

```ruby
github "sprint84/CropViewController" ~> 1.0
```

### Installing Carthage

To install the `carthage` tool on your system, please download and run the `Carthage.pkg` file for the latest release, then follow the on-screen instructions.

Alternately, you can use Homebrew and install the `carthage` tool on your system simply by running brew update and `brew install carthage`.

For further details, please visit the [Carthage Github page](https://github.com/Carthage/Carthage)

## Usage

First import the module into your project.

```swift
import CropViewController
```

You may use the view controller component, with the default buttons and appearance. We will add customization properties in the future.

```swift
let controller = CropViewController()
controller.delegate = self
controller.image = image

let navController = UINavigationController(rootViewController: controller)
presentViewController(navController, animated: true, completion: nil)
```

Alternatively, you can use the crop view directly, and incorporate it in your existing UI.

```swift
let cropView = CropView(frame: bounds)
view.addSubview(cropView)
```

### Reading the cropped image

Using the delegate method on the View Controller:

```swift
func cropViewController(controller: CropViewController, didFinishCroppingImage image: UIImage) {
    controller.dismissViewControllerAnimated(true, completion: nil)
    imageView.image = image
}
```

Retrieving directly from the crop view
```swift
let croppedImage = cropView.croppedImage
```

### Customization
Coming in the near future...

## Author

Reefactor, Inc., reefactor@gmail.com

## License

ProgressButton is available under the MIT license. See the LICENSE file for more info.
