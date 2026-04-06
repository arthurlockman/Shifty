//
//  PrefGeneralView.swift
//  Shifty
//
//  SwiftUI replacement for PrefGeneralViewController.
//

import SwiftUI

struct PrefGeneralView: View {
    @AppStorage(Keys.isAutoLaunchEnabled) private var autoLaunch = false
    @AppStorage(Keys.isStatusToggleEnabled) private var quickToggle = false
    @AppStorage(Keys.isIconSwitchingEnabled) private var iconSwitching = false
    @AppStorage(Keys.trueToneControl) private var trueToneControl = false

    // Gated toggles use local state; the controller commits on success.
    @SwiftUI.State private var websiteShifting: Bool
    @SwiftUI.State private var hideMenuBarIcon: Bool
    @SwiftUI.State private var showHideIconAlert = false

    let isTrueToneSupported: Bool
    let onAutoLaunchChanged: (Bool) -> Void
    let onQuickToggleChanged: (Bool) -> Void
    let onIconSwitchingChanged: (Bool) -> Void
    let onWebsiteShiftingChanged: (Bool) -> Void
    let onTrueToneControlChanged: (Bool) -> Void
    let onHideMenuBarIconConfirmed: (Bool) -> Void
    let onOpenNightShiftSettings: () -> Void
    let onQuit: () -> Void

    init(
        isTrueToneSupported: Bool,
        onAutoLaunchChanged: @escaping (Bool) -> Void,
        onQuickToggleChanged: @escaping (Bool) -> Void,
        onIconSwitchingChanged: @escaping (Bool) -> Void,
        onWebsiteShiftingChanged: @escaping (Bool) -> Void,
        onTrueToneControlChanged: @escaping (Bool) -> Void,
        onHideMenuBarIconConfirmed: @escaping (Bool) -> Void,
        onOpenNightShiftSettings: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.isTrueToneSupported = isTrueToneSupported
        self.onAutoLaunchChanged = onAutoLaunchChanged
        self.onQuickToggleChanged = onQuickToggleChanged
        self.onIconSwitchingChanged = onIconSwitchingChanged
        self.onWebsiteShiftingChanged = onWebsiteShiftingChanged
        self.onTrueToneControlChanged = onTrueToneControlChanged
        self.onHideMenuBarIconConfirmed = onHideMenuBarIconConfirmed
        self.onOpenNightShiftSettings = onOpenNightShiftSettings
        self.onQuit = onQuit

        _websiteShifting = SwiftUI.State(initialValue: UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled))
        _hideMenuBarIcon = SwiftUI.State(initialValue: UserDefaults.standard.bool(forKey: Keys.isMenuBarIconHidden))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(String(localized: "general.autoLaunch"), isOn: $autoLaunch)
                .onChange(of: autoLaunch) { onAutoLaunchChanged($1) }

            settingRow(
                toggle: $quickToggle,
                label: String(localized: "general.quickToggle"),
                description: String(localized: "general.quickToggle.description")
            )
            .onChange(of: quickToggle) { onQuickToggleChanged($1) }

            Toggle(String(localized: "general.iconSwitching"), isOn: $iconSwitching)
                .onChange(of: iconSwitching) { onIconSwitchingChanged($1) }

            settingRow(
                toggle: $websiteShifting,
                label: String(localized: "general.websiteShifting"),
                description: String(localized: "general.websiteShifting.description")
            )
            .onChange(of: websiteShifting) { onWebsiteShiftingChanged($1) }

            if isTrueToneSupported {
                settingRow(
                    toggle: $trueToneControl,
                    label: String(localized: "general.trueToneControl"),
                    description: String(localized: "general.trueToneControl.description")
                )
                .onChange(of: trueToneControl) { onTrueToneControlChanged($1) }
            }

            Toggle(String(localized: "general.hideMenuBarIcon"), isOn: Binding(
                get: { hideMenuBarIcon },
                set: { newValue in
                    if newValue {
                        showHideIconAlert = true
                    } else {
                        hideMenuBarIcon = false
                        onHideMenuBarIconConfirmed(false)
                    }
                }
            ))

            Spacer().frame(height: 4)

            HStack {
                Spacer()
                Button(String(localized: "general.openNightShiftSettings")) {
                    onOpenNightShiftSettings()
                }
                Spacer()
            }

            HStack {
                Spacer()
                Button(String(localized: "general.quit")) {
                    onQuit()
                }
                Spacer()
            }
        }
        .padding(20)
        .frame(width: 370)
        .alert(
            String(localized: "general.hideIconAlert.title"),
            isPresented: $showHideIconAlert
        ) {
            Button(String(localized: "general.hideIconAlert.confirm")) {
                hideMenuBarIcon = true
                onHideMenuBarIconConfirmed(true)
            }
            Button(String(localized: "general.hideIconAlert.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "general.hideIconAlert.message"))
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            let current = UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled)
            if current != websiteShifting {
                websiteShifting = current
            }
        }
    }

    @ViewBuilder
    private func settingRow(toggle: Binding<Bool>, label: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Toggle(label, isOn: toggle)
            Text(description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.leading, 20)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrefGeneralView(
        isTrueToneSupported: true,
        onAutoLaunchChanged: { _ in },
        onQuickToggleChanged: { _ in },
        onIconSwitchingChanged: { _ in },
        onWebsiteShiftingChanged: { _ in },
        onTrueToneControlChanged: { _ in },
        onHideMenuBarIconConfirmed: { _ in },
        onOpenNightShiftSettings: {},
        onQuit: {}
    )
}
