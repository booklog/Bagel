//
//  DataJSONViewController.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 2.10.2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa
import WebKit
import Highlightr

class DataJSONViewController: BaseViewController {
    
    var viewModel: DataJSONViewModel?
    
    let highlightr = Highlightr()

    private var appearanceObservation: NSKeyValueObservation?

    @IBOutlet var rawTextView: NSTextView!
    
    @IBOutlet weak var rawTextScrollView: NSScrollView!
    @IBOutlet weak var copyToClipboardButton: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    override func setup() {
        
        self.copyToClipboardButton.image = ThemeImage.copyToClipboardIcon
        
        // Follow the system light / dark appearance.
        self.appearanceObservation = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.refreshHighlightrTheme()
                self?.refresh()
            }
        }
        
        self.viewModel?.onChange = { [weak self] in
            self?.refresh()
        }
        
        self.refreshHighlightrTheme()
        self.refresh()
    }

    func refresh() {
        self.rawTextView.string = ""
        if let jsonString = self.viewModel?.dataRepresentation?.rawString {
            self.progressIndicator.isHidden = false
            self.progressIndicator.startAnimation(nil)
            DispatchQueue.global(qos: .background).async {
                if let highlightedCode = self.highlightr?.highlight(jsonString, as: "json") {
                    DispatchQueue.main.async {
                        self.rawTextView.textStorage?.setAttributedString(highlightedCode)
                        self.progressIndicator.isHidden = true
                        self.progressIndicator.stopAnimation(nil)
                    }
                }
            }
        }
    }
    
    func refreshHighlightrTheme() {
        if NSApp.effectiveAppearance.isDark {
            self.highlightr?.setTheme(to: "paraiso-dark")
        } else {
            self.highlightr?.setTheme(to: "github")
        }
    }

    @IBAction func copyButtonAction(_ sender: Any) {
        self.viewModel?.copyToClipboard()
    }
}
