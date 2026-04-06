//
//  PrefAppsView.swift
//  Shifty
//
//  SwiftUI replacement for PrefAppsViewController.
//

import SwiftUI
import UniformTypeIdentifiers

struct PrefAppsView: View {
    enum Tab: Int, CaseIterable {
        case appRules = 0
        case browserRules = 1

        var label: String {
            switch self {
            case .appRules: NSLocalizedString("prefs.apps.segment.app_rules", comment: "")
            case .browserRules: NSLocalizedString("prefs.apps.segment.browser_rules", comment: "")
            }
        }
    }

    struct AppRuleItem: Identifiable, Hashable {
        let bundleID: String
        let ruleType: String
        var id: String { bundleID }
    }

    struct BrowserRuleItem: Identifiable, Hashable {
        let host: String
        let type: RuleType
        var id: String { host }
    }

    @SwiftUI.State private var selectedTab: Tab = .appRules
    @SwiftUI.State private var appRules: [AppRuleItem] = []
    @SwiftUI.State private var browserRules: [BrowserRuleItem] = []
    @SwiftUI.State private var appSelection: String?
    @SwiftUI.State private var browserSelection: String?
    @SwiftUI.State private var showDomainSheet = false
    @SwiftUI.State private var newDomain = ""

    private var selection: String? {
        selectedTab == .appRules ? appSelection : browserSelection
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.label).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            Group {
                if selectedTab == .appRules {
                    appRulesList
                } else {
                    browserRulesList
                }
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 4) {
                Button(action: addClicked) {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 24)
                }
                Button(action: removeClicked) {
                    Image(systemName: "minus")
                        .frame(width: 24, height: 24)
                }
                .disabled(selection == nil)
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .frame(width: 500, height: 350)
        .onAppear { reloadData() }
        .onChange(of: selectedTab) {
            appSelection = nil
            browserSelection = nil
            reloadData()
        }
        .sheet(isPresented: $showDomainSheet) {
            domainSheet
        }
    }

    // MARK: - App Rules List

    private var appRulesList: some View {
        List(selection: $appSelection) {
            ForEach(appRules) { rule in
                HStack {
                    Image(nsImage: appIcon(forBundleID: rule.bundleID))
                        .resizable()
                        .frame(width: 18, height: 18)
                    Text(appName(forBundleID: rule.bundleID))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("", selection: ruleTypeBinding(forBundleID: rule.bundleID)) {
                        Text(NSLocalizedString("prefs.apps.rule.focused", comment: "")).tag("focused")
                        Text(NSLocalizedString("prefs.apps.rule.running", comment: "")).tag("running")
                    }
                    .labelsHidden()
                    .fixedSize()
                }
                .tag(rule.bundleID)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Browser Rules List

    private var browserRulesList: some View {
        List(selection: $browserSelection) {
            ForEach(browserRules) { rule in
                HStack {
                    Text(rule.host)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(localizedBrowserRuleType(rule.type))
                        .foregroundStyle(.secondary)
                        .frame(width: 150, alignment: .trailing)
                }
                .tag(rule.host)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Domain Sheet

    private var domainSheet: some View {
        VStack(spacing: 16) {
            Text(NSLocalizedString("prefs.apps.add_domain_title", comment: ""))
                .font(.headline)
            Text(NSLocalizedString("prefs.apps.add_domain_info", comment: ""))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("example.com", text: $newDomain)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)
            HStack {
                Button(NSLocalizedString("prefs.apps.cancel", comment: "")) {
                    newDomain = ""
                    showDomainSheet = false
                }
                .keyboardShortcut(.cancelAction)
                Button(NSLocalizedString("prefs.apps.add", comment: "")) {
                    let domain = newDomain.trimmingCharacters(in: .whitespaces)
                    if !domain.isEmpty {
                        RuleManager.shared.addDomainDisableRule(forDomain: domain)
                        reloadData()
                    }
                    newDomain = ""
                    showDomainSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newDomain.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
    }

    // MARK: - Actions

    private func addClicked() {
        if selectedTab == .appRules {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.application]
            panel.directoryURL = URL(fileURLWithPath: "/Applications")
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowsMultipleSelection = false
            panel.message = NSLocalizedString("prefs.apps.add_app_message", comment: "")

            if panel.runModal() == .OK, let url = panel.url,
               let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier {
                promptRuleType(forBundleID: bundleID)
            }
        } else {
            newDomain = ""
            showDomainSheet = true
        }
    }

    private func removeClicked() {
        if selectedTab == .appRules {
            guard let sel = appSelection else { return }
            if let rule = appRules.first(where: { $0.bundleID == sel }) {
                if rule.ruleType == "focused" {
                    RuleManager.shared.removeCurrentAppDisableRule(forBundleID: rule.bundleID)
                } else {
                    RuleManager.shared.removeRunningAppDisableRule(forBundleID: rule.bundleID)
                }
            }
            appSelection = nil
        } else {
            guard let sel = browserSelection else { return }
            if let rule = RuleManager.shared.browserRules.first(where: { $0.host == sel }) {
                RuleManager.shared.removeBrowserRule(rule)
            }
            browserSelection = nil
        }
        reloadData()
    }

    private func promptRuleType(forBundleID bundleID: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("prefs.apps.rule_type_title", comment: "")
        alert.informativeText = NSLocalizedString("prefs.apps.rule_type_info", comment: "")

        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 200, height: 24), pullsDown: false)
        popup.addItem(withTitle: NSLocalizedString("prefs.apps.rule.focused", comment: ""))
        popup.addItem(withTitle: NSLocalizedString("prefs.apps.rule.running", comment: ""))
        alert.accessoryView = popup

        alert.addButton(withTitle: NSLocalizedString("prefs.apps.add", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("prefs.apps.cancel", comment: ""))

        if alert.runModal() == .alertFirstButtonReturn {
            if popup.indexOfSelectedItem == 0 {
                RuleManager.shared.addCurrentAppDisableRule(forBundleID: bundleID)
            } else {
                RuleManager.shared.addRunningAppDisableRule(forBundleID: bundleID)
            }
            reloadData()
        }
    }

    // MARK: - Data

    private func reloadData() {
        let currentRules = RuleManager.shared.allCurrentAppDisableRules.map {
            AppRuleItem(bundleID: $0.bundleIdentifier, ruleType: "focused")
        }
        let runningRules = RuleManager.shared.allRunningAppDisableRules.map {
            AppRuleItem(bundleID: $0.bundleIdentifier, ruleType: "running")
        }
        appRules = (currentRules + runningRules).sorted {
            appName(forBundleID: $0.bundleID) < appName(forBundleID: $1.bundleID)
        }
        browserRules = RuleManager.shared.browserRules.sorted { $0.host < $1.host }.map {
            BrowserRuleItem(host: $0.host, type: $0.type)
        }
    }

    private func ruleTypeBinding(forBundleID bundleID: String) -> Binding<String> {
        Binding(
            get: { appRules.first(where: { $0.bundleID == bundleID })?.ruleType ?? "focused" },
            set: { newType in
                guard let rule = appRules.first(where: { $0.bundleID == bundleID }),
                      newType != rule.ruleType else { return }
                if rule.ruleType == "focused" {
                    RuleManager.shared.removeCurrentAppDisableRule(forBundleID: bundleID)
                } else {
                    RuleManager.shared.removeRunningAppDisableRule(forBundleID: bundleID)
                }
                if newType == "focused" {
                    RuleManager.shared.addCurrentAppDisableRule(forBundleID: bundleID)
                } else {
                    RuleManager.shared.addRunningAppDisableRule(forBundleID: bundleID)
                }
                reloadData()
            }
        )
    }

    // MARK: - Helpers

    private func appName(forBundleID bundleID: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
           let bundle = Bundle(url: url),
           let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return name
        }
        return bundleID
    }

    private func appIcon(forBundleID bundleID: String) -> NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(for: UTType.application)
    }

    private func localizedBrowserRuleType(_ type: RuleType) -> String {
        switch type {
        case .domain:
            NSLocalizedString("prefs.apps.rule.domain", comment: "")
        case .subdomainDisabled:
            NSLocalizedString("prefs.apps.rule.subdomain_disabled", comment: "")
        case .subdomainEnabled:
            NSLocalizedString("prefs.apps.rule.subdomain_enabled", comment: "")
        }
    }
}

#Preview {
    PrefAppsView()
}
