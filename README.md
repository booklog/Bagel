# Bagel
![Bagel](https://github.com/yagiz/Bagel/blob/master/assets/header.png?raw=true)
<p align="center">
    <a href="https://swift.org/package-manager/" alt="Swift Package Manager">
        <img src="https://img.shields.io/badge/SPM-supported-4BC51D.svg?style=flat" /></a>
    <a href="https://github.com/yagiz/Bagel/releases" alt="Version">
        <img src="https://img.shields.io/github/release/yagiz/Bagel.svg" /></a>
</p>

Bagel is a little native iOS network debugger. It's not a proxy debugger so you don't have to mess around with certificates, proxy settings etc. As long as your iOS devices and your Mac are in the same network, you can view the network traffic of your apps seperated by the devices or simulators.

## Preview
![Bagel](https://github.com/yagiz/Bagel/blob/develop/assets/screenshot.png?raw=true)
## Installation
#### Install Mac App
- Clone the repo.
- Open `mac/Bagel.xcodeproj` in Xcode. Dependencies are fetched automatically with Swift Package Manager.
- Build and archive the project. The Mac app requires macOS 14.0 or later.
#### Install iOS Client
Bagel is distributed with Swift Package Manager. In Xcode, choose **File > Add Package Dependencies...** and enter `https://github.com/yagiz/Bagel.git`, or add it to your `Package.swift`:
```swift
.package(url: "https://github.com/yagiz/Bagel.git", .upToNextMajor(from: "1.4.0")),
```
The iOS client requires iOS 17.0 or later. CocoaPods and Carthage are no longer supported.

### Local Network permission
Bagel finds the desktop client with Bonjour, so iOS requires your app to declare it. Add the following to your app's `Info.plist`, otherwise browsing fails and Bagel logs `Bonjour browsing is blocked by iOS Local Network privacy`:
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Bagel uses the local network to send network logs to the Bagel desktop app.</string>
<key>NSBonjourServices</key>
<array>
    <string>_Bagel._tcp</string>
</array>
```
If you change `netserviceType`, list that value in `NSBonjourServices` instead. On first launch iOS asks the user to allow local network access; if it was denied, re-enable it in Settings > Privacy & Security > Local Network.

### Usage
Most basic usage is to start Bagel iOS before any network operation. 
```swift
//import Bagel
Bagel.start()
```
Since Bagel exposes every request info to the public it would be better if you disable it for the store versions. You can use the below snippet to do it:
```swift
//import Bagel
#if DEBUG
Bagel.start()
#endif
```

###  Configuring Bagel
By default, Bagel gets your project name and device information. Desktop client uses these informations to separate projects and devices. You can configure these if you wish:
```swift
let bagelConfig = BagelConfiguration()

bagelConfig.project.projectName = "Custom Project Name"
bagelConfig.device.deviceName = "Custom Device Name"
bagelConfig.device.deviceDescription = "Custom Device Description"

Bagel.start(bagelConfig)
```
Bagel framework communicates with the desktop client by using Bonjour protocol. You can also configure these Netservice parameters. Default values are:

```swift
let bagelConfig = BagelConfiguration()

bagelConfig.netservicePort = 43434
bagelConfig.netserviceDomain = ""
bagelConfig.netserviceType = "_Bagel._tcp"
bagelConfig.netserviceName = ""

Bagel.start(bagelConfig)
```
If you change Netservice parameters in your app, you should also change them on desktop client.

License
----
Apache
