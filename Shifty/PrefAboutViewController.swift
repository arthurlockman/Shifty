//
//  PrefAboutViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import SwiftUI
import Settings

@objcMembers
class PrefAboutViewController: NSViewController, SettingsPane {

    let paneIdentifier = Settings.PaneIdentifier("about")
    let paneTitle = NSLocalizedString("prefs.about", comment: "About")

    var toolbarItemIcon: NSImage {
        return NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)!
    }

    override func loadView() {
        let hostingView = NSHostingView(rootView: PrefAboutView())
        let size = hostingView.fittingSize
        hostingView.frame = NSRect(origin: .zero, size: size)
        self.preferredContentSize = size
        self.view = hostingView
    }
}
