//
//  PrefShortcutsViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import Settings
import SwiftUI
import KeyboardShortcuts

@objcMembers
class PrefShortcutsViewController: NSViewController, SettingsPane {

    var statusMenuController: StatusMenuController? {
        (NSApplication.shared.delegate as? AppDelegate)?.statusMenu.delegate as? StatusMenuController
    }

    let paneIdentifier = Settings.PaneIdentifier("shortcuts")
    let paneTitle = NSLocalizedString("prefs.shortcuts", comment: "Shortcuts")

    var toolbarItemIcon: NSImage {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "command", accessibilityDescription: nil)!
        } else {
            return #imageLiteral(resourceName: "shortcutsIcon")
        }
    }

    override func loadView() {
        let hostingView = NSHostingView(rootView: PrefShortcutsView())
        let size = hostingView.fittingSize
        hostingView.frame = NSRect(origin: .zero, size: size)
        self.preferredContentSize = size
        self.view = hostingView
    }

    func bindShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .toggleNightShift) { [weak self] in
            guard let menu = self?.statusMenuController else { return }
            if !menu.powerMenuItem.isHidden && menu.powerMenuItem.isEnabled {
                self?.statusMenuController?.power(self as Any)
            } else {
                NSSound.beep()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .incrementColorTemp) {
            if NightShiftManager.shared.isNightShiftEnabled {
                if NightShiftManager.shared.colorTemperature == 1.0 {
                    NSSound.beep()
                }
                NightShiftManager.shared.colorTemperature += 0.1
            } else {
                NightShiftManager.shared.respond(to: .userEnabledNightShift)
                NightShiftManager.shared.colorTemperature = 0.1
            }
        }

        KeyboardShortcuts.onKeyUp(for: .decrementColorTemp) {
            if NightShiftManager.shared.isNightShiftEnabled {
                NightShiftManager.shared.colorTemperature -= 0.1
                if NightShiftManager.shared.colorTemperature == 0.0 {
                    NSSound.beep()
                }
            } else {
                NSSound.beep()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .disableApp) { [weak self] in
            guard let menu = self?.statusMenuController else { return }
            if !menu.disableCurrentAppMenuItem.isHidden && menu.disableCurrentAppMenuItem.isEnabled {
                self?.statusMenuController?.disableForCurrentApp(self as Any)
            } else {
                NSSound.beep()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .disableDomain) { [weak self] in
            guard let menu = self?.statusMenuController else { return }
            if !menu.disableDomainMenuItem.isHidden && menu.disableDomainMenuItem.isEnabled {
                self?.statusMenuController?.disableForDomain(self as Any)
            } else {
                NSSound.beep()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .disableSubdomain) { [weak self] in
            guard let menu = self?.statusMenuController else { return }
            if !menu.disableSubdomainMenuItem.isHidden && menu.disableSubdomainMenuItem.isEnabled {
                self?.statusMenuController?.disableForSubdomain(self as Any)
            } else {
                NSSound.beep()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .disableHour) { [weak self] in
            guard let menu = self?.statusMenuController else { return }
            if !menu.disableHourMenuItem.isHidden && menu.disableHourMenuItem.isEnabled {
                self?.statusMenuController?.disableHour(self as Any)
            } else {
                NSSound.beep()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .disableCustom) { [weak self] in
            guard let menu = self?.statusMenuController else { return }
            if !menu.disableCustomMenuItem.isHidden && menu.disableCustomMenuItem.isEnabled {
                self?.statusMenuController?.disableCustomTime(self as Any)
            } else {
                NSSound.beep()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .toggleTrueTone) { [weak self] in
            guard let menu = self?.statusMenuController else { return }
            if !menu.trueToneMenuItem.isHidden && menu.trueToneMenuItem.isEnabled {
                self?.statusMenuController?.toggleTrueTone(self as Any)
            } else {
                NSSound.beep()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .toggleDarkMode) {
            SLSSetAppearanceThemeLegacy(!SLSGetAppearanceThemeLegacy())
        }
    }
}
