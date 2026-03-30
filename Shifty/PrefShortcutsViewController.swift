//
//  PrefShortcutsViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import MASPreferences
import KeyboardShortcuts

@objcMembers
class PrefShortcutsViewController: NSViewController, MASPreferencesViewController {

    let statusMenuController = (NSApplication.shared.delegate as? AppDelegate)?.statusMenu.delegate as? StatusMenuController

    override var nibName: NSNib.Name? {
        return nil
    }

    var viewIdentifier: String = "PrefShortcutsViewController"

    var toolbarItemImage: NSImage? {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "command", accessibilityDescription: nil)
        } else {
            return #imageLiteral(resourceName: "shortcutsIcon")
        }
    }

    var toolbarItemLabel: String? {
        _ = view
        return NSLocalizedString("prefs.shortcuts", comment: "Shortcuts")
    }

    var hasResizableWidth = false
    var hasResizableHeight = false

    private var trueToneLabel: NSTextField!
    private var trueToneRecorder: KeyboardShortcuts.RecorderCocoa!

    override func loadView() {
        let container = NSView()

        let pairs: [(String, KeyboardShortcuts.Name)] = [
            (NSLocalizedString("prefs.shortcuts.toggle_night_shift", comment: "Toggle Night Shift:"), .toggleNightShift),
            (NSLocalizedString("prefs.shortcuts.increase_color_temp", comment: "Increase color temp:"), .incrementColorTemp),
            (NSLocalizedString("prefs.shortcuts.decrease_color_temp", comment: "Decrease color temp:"), .decrementColorTemp),
            (NSLocalizedString("prefs.shortcuts.disable_app", comment: "Disable for current app:"), .disableApp),
            (NSLocalizedString("prefs.shortcuts.disable_domain", comment: "Disable for domain:"), .disableDomain),
            (NSLocalizedString("prefs.shortcuts.disable_subdomain", comment: "Disable for subdomain:"), .disableSubdomain),
            (NSLocalizedString("prefs.shortcuts.disable_hour", comment: "Disable for an hour:"), .disableHour),
            (NSLocalizedString("prefs.shortcuts.disable_custom", comment: "Disable for custom time:"), .disableCustom),
            (NSLocalizedString("prefs.shortcuts.toggle_true_tone", comment: "Toggle True Tone:"), .toggleTrueTone),
            (NSLocalizedString("prefs.shortcuts.toggle_dark_mode", comment: "Toggle Dark Mode:"), .toggleDarkMode),
        ]

        let grid = NSGridView(numberOfColumns: 2, rows: 0)
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.rowSpacing = 12
        grid.columnSpacing = 10
        grid.column(at: 0).xPlacement = .trailing

        for (labelText, name) in pairs {
            let label = NSTextField(labelWithString: labelText)
            label.alignment = .right
            label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            let recorder = KeyboardShortcuts.RecorderCocoa(for: name)
            grid.addRow(with: [label, recorder])
            if name == .toggleTrueTone {
                trueToneLabel = label
                trueToneRecorder = recorder
            }
        }

        container.addSubview(grid)

        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            grid.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            grid.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -20),
        ])

        container.setFrameSize(NSSize(width: 480, height: 380))
        self.view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide True Tone settings on unsupported computers
        if #available(macOS 10.14, *) {
            let trueToneUnsupported = CBTrueToneClient.shared.state == .unsupported
            trueToneLabel?.isHidden = trueToneUnsupported
            trueToneRecorder?.isHidden = trueToneUnsupported
        } else {
            trueToneLabel?.isHidden = true
            trueToneRecorder?.isHidden = true
        }
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
