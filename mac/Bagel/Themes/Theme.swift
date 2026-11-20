//
//  Theme.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 7.10.2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa

/// App colors that follow the system appearance (light / dark).
///
/// These replace the former macOSThemeKit light and dark themes with the same
/// values, using dynamic `NSColor`s so they update automatically when the
/// system appearance changes.
enum ThemeColor {

    static let labelColor = dynamic(light: .darkGray, dark: .white)
    static let controlBackgroundColor = dynamic(light: .white, dark: NSColor(hexString: "#1D1D1D"))
    static let gridColor = dynamic(light: NSColor(hexString: "#F0F0F0"), dark: NSColor(hexString: "#2A2A2A"))
    static let secondaryLabelColor = dynamic(light: .lightGray, dark: NSColor(hexString: "#9C9C9C"))
    static let textColor = NSColor.textColor

    static let contentBarColor = dynamic(light: NSColor(hexString: "#f4f4f4"), dark: NSColor(hexString: "#3A3A3A"))
    static let rowSelectedColor = dynamic(light: NSColor(hexString: "#F0F0F0"), dark: NSColor(hexString: "#2A2A2A"))

    static let statusGreenColor = NSColor(hexString: "#2ECC71")
    static let statusOrangeColor = NSColor(hexString: "#F1C40F")
    static let statusRedColor = NSColor(hexString: "#E74C3C")

    static let projectListBackgroundColor = NSColor(hexString: "#232323")
    static let projectTextColor = NSColor(hexString: "#ffffff")
    static let deviceListBackgroundColor = dynamic(light: NSColor(hexString: "#F6F6F6"), dark: NSColor(hexString: "#262626"))
    static let deviceRowSelectedColor = dynamic(light: NSColor(hexString: "#ffffff"), dark: NSColor(hexString: "#3A3A3A"))
    static let packetListAndDetailBackgroundColor = dynamic(light: NSColor(hexString: "#F0F0F0"), dark: NSColor(hexString: "#323232"))

    static let httpMethodGetColor = dynamic(light: NSColor(hexString: "#00cec9"), dark: NSColor(hexString: "#00b894"))
    static let httpMethodPostColor = NSColor(hexString: "#fdcb6e")
    static let httpMethodDeleteColor = NSColor(hexString: "#e17055")
    static let httpMethodPutColor = NSColor(hexString: "#0984e3")
    // Neither former theme defined a PATCH color, so macOSThemeKit fell back to
    // black (light) / white (dark). Keep that behavior.
    static let httpMethodPatchColor = dynamic(light: .black, dark: .white)
    static let httpMethodDefaultColor = secondaryLabelColor

    private static func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        return NSColor(name: nil) { appearance in
            appearance.isDark ? dark : light
        }
    }
}

/// App images. Light / dark variants live in the asset catalog as appearance
/// variants, so `NSImage` picks the right one automatically.
enum ThemeImage {

    static var clearIcon: NSImage {
        return NSImage(named: "TrashIcon")!
    }

    static var copyToClipboardIcon: NSImage {
        return NSImage(named: "CopyIcon")!
    }
}

extension NSAppearance {

    var isDark: Bool {
        return bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }
}
