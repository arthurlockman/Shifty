//
//  GeneralPreferencesViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import Settings
import ServiceManagement
import SwiftUI
import AXSwift
import Logging


@objcMembers
class PrefGeneralViewController: NSViewController, SettingsPane {

    let paneIdentifier = Settings.PaneIdentifier("general")
    let paneTitle = NSLocalizedString("prefs.general", comment: "General")

    var toolbarItemIcon: NSImage {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)!
        } else {
            return NSImage(named: NSImage.preferencesGeneralName)!
        }
    }

    var appDelegate: AppDelegate!

    override func loadView() {
        appDelegate = NSApplication.shared.delegate as? AppDelegate

        let trueToneSupported: Bool
        if #available(macOS 10.14, *) {
            trueToneSupported = CBTrueToneClient.shared.state != .unsupported
        } else {
            trueToneSupported = false
        }

        let generalView = PrefGeneralView(
            isTrueToneSupported: trueToneSupported,
            onAutoLaunchChanged: { [weak self] enabled in
                self?.setAutoLaunch(enabled)
            },
            onQuickToggleChanged: { [weak self] _ in
                self?.appDelegate.setStatusToggle()
                logw("Quick Toggle changed")
            },
            onIconSwitchingChanged: { [weak self] _ in
                self?.appDelegate.updateMenuBarIcon()
                logw("Icon switching changed")
            },
            onWebsiteShiftingChanged: { [weak self] enabled in
                self?.setWebsiteControl(enabled)
            },
            onTrueToneControlChanged: { enabled in
                if #available(macOS 10.14, *) {
                    if enabled {
                        if NightShiftManager.shared.isDisableRuleActive {
                            CBTrueToneClient.shared.isTrueToneEnabled = false
                        }
                    } else {
                        CBTrueToneClient.shared.isTrueToneEnabled = true
                    }
                    logw("True Tone control set to \(enabled)")
                }
            },
            onHideMenuBarIconConfirmed: { shouldHide in
                UserDefaults.standard.set(shouldHide, forKey: Keys.isMenuBarIconHidden)
                NotificationCenter.default.post(name: .menuBarIconVisibilityChanged, object: nil)
                logw("Menu bar icon hidden: \(shouldHide)")
            },
            onOpenNightShiftSettings: {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension")!)
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )

        let hostingView = NSHostingView(rootView: generalView)
        hostingView.frame = NSRect(origin: .zero, size: hostingView.fittingSize)
        self.view = hostingView
    }

    private func setAutoLaunch(_ enabled: Bool) {
        let launcherAppIdentifier = "io.natethompson.ShiftyHelper"
        if enabled {
            try? SMAppService.loginItem(identifier: launcherAppIdentifier).register()
        } else {
            try? SMAppService.loginItem(identifier: launcherAppIdentifier).unregister()
        }
        logw("Auto launch on login set to \(enabled)")
    }

    private func setWebsiteControl(_ enabled: Bool) {
        logw("Website control preference clicked")
        if enabled {
            if !UIElement.isProcessTrusted() {
                logw("Accessibility permissions alert shown")
                UserDefaults.standard.set(false, forKey: Keys.isWebsiteControlEnabled)
                NSApp.runModal(for: AccessibilityWindow().window!)
            }
        } else {
            BrowserManager.shared.stopBrowserWatcher()
            logw("Website control disabled")
        }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        Event.preferences(
            autoLaunch: UserDefaults.standard.bool(forKey: Keys.isAutoLaunchEnabled),
            quickToggle: UserDefaults.standard.bool(forKey: Keys.isStatusToggleEnabled),
            iconSwitching: UserDefaults.standard.bool(forKey: Keys.isIconSwitchingEnabled),
            websiteShifting: UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled),
            trueToneControl: UserDefaults.standard.bool(forKey: Keys.trueToneControl)
        ).record()
    }
}
