//
//  PrefAppsViewController.swift
//  Shifty
//
//  Created via Copilot CLI.
//

import Cocoa
import Settings
import SwiftUI


@objcMembers
class PrefAppsViewController: NSViewController, SettingsPane {

    let paneIdentifier = Settings.PaneIdentifier("apps")
    let paneTitle = NSLocalizedString("prefs.apps", comment: "Apps")

    var toolbarItemIcon: NSImage {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "app.badge.checkmark", accessibilityDescription: nil)!
        } else {
            return NSImage(named: NSImage.applicationIconName)!
        }
    }

    override func loadView() {
        let hostingView = NSHostingView(rootView: PrefAppsView())
        let size = hostingView.fittingSize
        hostingView.frame = NSRect(origin: .zero, size: size)
        self.preferredContentSize = size
        self.view = hostingView
    }
}
