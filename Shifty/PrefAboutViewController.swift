//
//  PrefAboutViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import SwiftUI
import MASPreferences

@objcMembers
class PrefAboutViewController: NSViewController, MASPreferencesViewController {

    var viewIdentifier: String = "PrefAboutViewController"

    var toolbarItemImage: NSImage? {
        return NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
    }

    var toolbarItemLabel: String? {
        return NSLocalizedString("prefs.about", comment: "About")
    }

    var hasResizableWidth = false
    var hasResizableHeight = false

    override func loadView() {
        let hostingView = NSHostingView(rootView: PrefAboutView())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        self.view = hostingView
    }
}
