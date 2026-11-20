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
    
    private let highlighter = JSONHighlighter()

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
            self.highlighter.highlight(jsonString) { [weak self] highlightedCode in
                guard let self, let highlightedCode else { return }
                self.rawTextView.textStorage?.setAttributedString(highlightedCode)
                self.progressIndicator.isHidden = true
                self.progressIndicator.stopAnimation(nil)
            }
        }
    }
    
    func refreshHighlightrTheme() {
        self.highlighter.setTheme(NSApp.effectiveAppearance.isDark ? "paraiso-dark" : "github")
    }

    @IBAction func copyButtonAction(_ sender: Any) {
        self.viewModel?.copyToClipboard()
    }
}

/// Runs Highlightr off the main thread.
///
/// Highlightr (JavaScriptCore) is not thread-safe, so every use of it, including
/// theme changes, is serialized on one private queue. That is what makes the
/// `@unchecked Sendable` conformance sound.
private final class JSONHighlighter: @unchecked Sendable {

    private let queue = DispatchQueue(label: "com.yagiz.Bagel.highlightr", qos: .userInitiated)
    private let highlightr = Highlightr()

    func setTheme(_ name: String) {
        queue.async {
            self.highlightr?.setTheme(to: name)
        }
    }

    func highlight(_ json: String, completion: @escaping @MainActor (NSAttributedString?) -> Void) {
        queue.async {
            let result = self.highlightr?.highlight(json, as: "json")
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
