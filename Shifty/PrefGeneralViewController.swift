//
//  GeneralPreferencesViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import MASPreferences
import ServiceManagement
import AXSwift
import Logging


@objcMembers
class PrefGeneralViewController: NSViewController, MASPreferencesViewController {

    override var nibName: NSNib.Name {
        return "PrefGeneralViewController"
    }

    var viewIdentifier: String = "PrefGeneralViewController"

    var toolbarItemImage: NSImage? {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        } else {
            return NSImage(named: NSImage.preferencesGeneralName)
        }
    }

    var toolbarItemLabel: String? {
        _ = view
        return NSLocalizedString("prefs.general", comment: "General")
    }

    var hasResizableWidth = false
    var hasResizableHeight = false

    @IBOutlet weak var autoLaunchButton: NSButton!
    @IBOutlet weak var quickToggleButton: NSButton!
    @IBOutlet weak var iconSwitchingButton: NSButton!
    @IBOutlet weak var websiteShiftingButton: NSButton!
    @IBOutlet weak var trueToneControlButton: NSButton!
    
    @IBOutlet weak var trueToneStackView: NSStackView!
    
    var hideMenuBarIconButton: NSButton!

    var appDelegate: AppDelegate!
    var prefWindow: NSWindow!

    override func viewDidLoad() {
        super.viewDidLoad()

        appDelegate = NSApplication.shared.delegate as? AppDelegate
        prefWindow = appDelegate.preferenceWindowController.window
        
        //Hide True Tone settings on unsupported computers
        if #available(macOS 10.14, *) {
            trueToneStackView.isHidden = CBTrueToneClient.shared.state == .unsupported
        } else {
            trueToneStackView.isHidden = true
        }

        //Fix layer-backing issues in 10.12 that cause window corners to not be rounded.
        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)) {
            view.wantsLayer = false
        }
        
        // Add "Hide menu bar icon" checkbox programmatically
        hideMenuBarIconButton = NSButton(checkboxWithTitle: NSLocalizedString("prefs.hide_menu_bar_icon", comment: "Hide menu bar icon"),
                                         target: self,
                                         action: #selector(hideMenuBarIconClicked(_:)))
        hideMenuBarIconButton.state = UserDefaults.standard.bool(forKey: Keys.isMenuBarIconHidden) ? .on : .off
        hideMenuBarIconButton.translatesAutoresizingMaskIntoConstraints = false
        
        if let mainStackView = trueToneStackView.superview as? NSStackView {
            let trueToneIndex = mainStackView.arrangedSubviews.firstIndex(of: trueToneStackView) ?? mainStackView.arrangedSubviews.count - 1
            mainStackView.insertArrangedSubview(hideMenuBarIconButton, at: trueToneIndex + 1)
            
            // Add Quit button at bottom
            let quitButton = NSButton(title: NSLocalizedString("prefs.quit", comment: "Quit Shifty"), target: self, action: #selector(quitApp))
            quitButton.bezelStyle = .rounded
            quitButton.translatesAutoresizingMaskIntoConstraints = false
            mainStackView.addArrangedSubview(quitButton)
            mainStackView.setCustomSpacing(16, after: hideMenuBarIconButton)
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
    }

    //MARK: IBActions

    @IBAction func setAutoLaunch(_ sender: NSButtonCell) {
        let launcherAppIdentifier = "io.natethompson.ShiftyHelper"
        try? SMAppService.loginItem(identifier: launcherAppIdentifier).register()
        if sender.state != .on {
            try? SMAppService.loginItem(identifier: launcherAppIdentifier).unregister()
        }
        logw("Auto launch on login set to \(sender.state.rawValue)")
    }

    @IBAction func quickToggle(_ sender: NSButtonCell) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.setStatusToggle()
        logw("Quick Toggle set to \(sender.state.rawValue)")
    }

    @IBAction func setIconSwitching(_ sender: NSButtonCell) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.updateMenuBarIcon()
        logw("Icon switching set to \(sender.state.rawValue)")
    }

    @IBAction func setWebsiteControl(_ sender: NSButtonCell) {
        logw("Website control preference clicked")
        if sender.state == .on {
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
    
    @IBAction func setTrueToneControl(_ sender: NSButtonCell) {
        if #available(macOS 10.14, *) {
            if sender.state == .on {
                if NightShiftManager.shared.isDisableRuleActive {
                    CBTrueToneClient.shared.isTrueToneEnabled = false
                }
            } else {
                CBTrueToneClient.shared.isTrueToneEnabled = true
            }
            logw("True Tone control set to \(sender.state.rawValue)")
        }
    }
    
    @objc func hideMenuBarIconClicked(_ sender: NSButton) {
        let shouldHide = sender.state == .on
        
        if shouldHide {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("prefs.hide_icon_alert.title",
                comment: "Alert title when hiding menu bar icon")
            alert.informativeText = NSLocalizedString("prefs.hide_icon_alert.message",
                comment: "Alert message when hiding menu bar icon")
            alert.alertStyle = .informational
            alert.addButton(withTitle: NSLocalizedString("prefs.hide_icon_alert.confirm",
                comment: "Confirm hiding menu bar icon"))
            alert.addButton(withTitle: NSLocalizedString("prefs.hide_icon_alert.cancel",
                comment: "Cancel hiding menu bar icon"))
            
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                sender.state = .off
                return
            }
        }
        
        UserDefaults.standard.set(shouldHide, forKey: Keys.isMenuBarIconHidden)
        NotificationCenter.default.post(name: .menuBarIconVisibilityChanged, object: nil)
    }
    
    @IBAction func openNightShiftSettings(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension")!)
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    override func viewWillDisappear() {
        Event.preferences(autoLaunch: autoLaunchButton.state == .on,
                          quickToggle: quickToggleButton.state == .on,
                          iconSwitching: iconSwitchingButton.state == .on,
                          websiteShifting: websiteShiftingButton.state == .on,
                          trueToneControl: trueToneControlButton.state == .on).record()
    }
}


class PrefWindowController: MASPreferencesWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.styleMask = [.titled, .closable]
        
        if #available(macOS 11.0, *) {
            window?.toolbarStyle = .preference
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 13 && event.modifierFlags.contains(.command) {
            window?.close()
        }
    }
}
