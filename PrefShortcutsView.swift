//
//  PrefShortcutsView.swift
//  Shifty
//
//  SwiftUI replacement for PrefShortcutsViewController keyboard grid.
//

import SwiftUI
import KeyboardShortcuts

struct PrefShortcutsView: View {
    private let isTrueToneSupported: Bool

    private let shortcuts: [(label: String, name: KeyboardShortcuts.Name)] = [
        (NSLocalizedString("prefs.shortcuts.toggle_night_shift", comment: ""), .toggleNightShift),
        (NSLocalizedString("prefs.shortcuts.increase_color_temp", comment: ""), .incrementColorTemp),
        (NSLocalizedString("prefs.shortcuts.decrease_color_temp", comment: ""), .decrementColorTemp),
        (NSLocalizedString("prefs.shortcuts.disable_app", comment: ""), .disableApp),
        (NSLocalizedString("prefs.shortcuts.disable_domain", comment: ""), .disableDomain),
        (NSLocalizedString("prefs.shortcuts.disable_subdomain", comment: ""), .disableSubdomain),
        (NSLocalizedString("prefs.shortcuts.disable_hour", comment: ""), .disableHour),
        (NSLocalizedString("prefs.shortcuts.disable_custom", comment: ""), .disableCustom),
        (NSLocalizedString("prefs.shortcuts.toggle_true_tone", comment: ""), .toggleTrueTone),
        (NSLocalizedString("prefs.shortcuts.toggle_dark_mode", comment: ""), .toggleDarkMode),
    ]

    init() {
        if #available(macOS 10.14, *) {
            isTrueToneSupported = CBTrueToneClient.shared.state != .unsupported
        } else {
            isTrueToneSupported = false
        }
    }

    var body: some View {
        Grid(alignment: .trailing, horizontalSpacing: 10, verticalSpacing: 12) {
            ForEach(Array(shortcuts.enumerated()), id: \.offset) { _, pair in
                if pair.name == .toggleTrueTone && !isTrueToneSupported {
                    EmptyView()
                } else {
                    GridRow {
                        Text(pair.label)
                            .gridColumnAlignment(.trailing)
                        KeyboardShortcuts.Recorder(for: pair.name)
                            .gridColumnAlignment(.leading)
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 480)
    }
}

#Preview {
    PrefShortcutsView()
}
