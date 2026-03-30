//
//  PrefAppsViewController.swift
//  Shifty
//
//  Created via Copilot CLI.
//

import Cocoa
import MASPreferences_Shifty
import UniformTypeIdentifiers


@objcMembers
class PrefAppsViewController: NSViewController, MASPreferencesViewController {

    // MARK: - MASPreferencesViewController

    var viewIdentifier: String = "PrefAppsViewController"

    var toolbarItemImage: NSImage? {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "app.badge.checkmark", accessibilityDescription: nil)
        } else {
            return NSImage(named: NSImage.applicationIconName)
        }
    }

    var toolbarItemLabel: String? {
        return NSLocalizedString("prefs.apps", comment: "Apps")
    }

    var hasResizableWidth = false
    var hasResizableHeight = false

    // MARK: - UI Elements

    private var segmentedControl: NSSegmentedControl!
    private var scrollView: NSScrollView!
    private var tableView: NSTableView!
    private var addButton: NSButton!
    private var removeButton: NSButton!

    private enum Tab: Int {
        case appRules = 0
        case browserRules = 1
    }

    private var currentTab: Tab = .appRules

    // MARK: - Data

    private var appRules: [(bundleID: String, ruleType: String)] = []
    private var browserRulesList: [BrowserRule] = []

    // MARK: - Lifecycle

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 350))
        container.translatesAutoresizingMaskIntoConstraints = false
        self.view = container

        setupSegmentedControl()
        setupTableView()
        setupButtons()
        setupConstraints()
        reloadData()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        reloadData()
    }

    // MARK: - Setup

    private func setupSegmentedControl() {
        segmentedControl = NSSegmentedControl(
            labels: [
                NSLocalizedString("prefs.apps.segment.app_rules", comment: "App Rules"),
                NSLocalizedString("prefs.apps.segment.browser_rules", comment: "Browser Rules")
            ],
            trackingMode: .selectOne,
            target: self,
            action: #selector(segmentChanged(_:))
        )
        segmentedControl.selectedSegment = 0
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)
    }

    private func setupTableView() {
        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = false
        tableView.rowHeight = 26
        tableView.headerView = NSTableHeaderView()

        scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        setupAppRulesColumns()
    }

    private func setupButtons() {
        addButton = NSButton(image: NSImage(named: NSImage.addTemplateName)!,
                             target: self, action: #selector(addClicked(_:)))
        addButton.bezelStyle = .smallSquare
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)

        removeButton = NSButton(image: NSImage(named: NSImage.removeTemplateName)!,
                                target: self, action: #selector(removeClicked(_:)))
        removeButton.bezelStyle = .smallSquare
        removeButton.isEnabled = false
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(removeButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Segmented control at top, centered
            segmentedControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Scroll view below segmented control
            scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -8),

            // Add/Remove buttons at bottom left
            addButton.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            addButton.widthAnchor.constraint(equalToConstant: 24),
            addButton.heightAnchor.constraint(equalToConstant: 24),

            removeButton.leadingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: 0),
            removeButton.bottomAnchor.constraint(equalTo: addButton.bottomAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: 24),
            removeButton.heightAnchor.constraint(equalToConstant: 24),

            // Fixed view size
            view.widthAnchor.constraint(equalToConstant: 500),
            view.heightAnchor.constraint(equalToConstant: 350),
        ])
    }

    // MARK: - Column Setup

    private func setupAppRulesColumns() {
        tableView.tableColumns.forEach { tableView.removeTableColumn($0) }

        let iconCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("icon"))
        iconCol.title = ""
        iconCol.width = 24
        iconCol.minWidth = 24
        iconCol.maxWidth = 24
        tableView.addTableColumn(iconCol)

        let nameCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameCol.title = NSLocalizedString("prefs.apps.column.name", comment: "App Name")
        nameCol.minWidth = 150
        tableView.addTableColumn(nameCol)

        let typeCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("type"))
        typeCol.title = NSLocalizedString("prefs.apps.column.type", comment: "Rule Type")
        typeCol.width = 120
        tableView.addTableColumn(typeCol)
    }

    private func setupBrowserRulesColumns() {
        tableView.tableColumns.forEach { tableView.removeTableColumn($0) }

        let domainCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("domain"))
        domainCol.title = NSLocalizedString("prefs.apps.column.domain", comment: "Domain")
        domainCol.minWidth = 200
        tableView.addTableColumn(domainCol)

        let typeCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("type"))
        typeCol.title = NSLocalizedString("prefs.apps.column.type", comment: "Rule Type")
        typeCol.width = 150
        tableView.addTableColumn(typeCol)
    }

    // MARK: - Actions

    @objc private func segmentChanged(_ sender: NSSegmentedControl) {
        currentTab = Tab(rawValue: sender.selectedSegment) ?? .appRules
        refreshDataArrays()
        if currentTab == .appRules {
            setupAppRulesColumns()
        } else {
            setupBrowserRulesColumns()
        }
        tableView.reloadData()
        removeButton?.isEnabled = false
    }

    @objc private func addClicked(_ sender: Any) {
        if currentTab == .appRules {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.application]
            panel.directoryURL = URL(fileURLWithPath: "/Applications")
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowsMultipleSelection = false
            panel.message = NSLocalizedString("prefs.apps.add_app_message",
                                              comment: "Select an application to add a rule for")

            panel.beginSheetModal(for: self.view.window!) { [weak self] response in
                guard response == .OK, let url = panel.url else { return }
                if let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier {
                    self?.promptRuleType(forBundleID: bundleID)
                }
            }
        } else {
            promptAddDomain()
        }
    }

    @objc private func removeClicked(_ sender: Any) {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 else { return }

        if currentTab == .appRules {
            let rule = appRules[selectedRow]
            if rule.ruleType == "focused" {
                RuleManager.shared.removeCurrentAppDisableRule(forBundleID: rule.bundleID)
            } else {
                RuleManager.shared.removeRunningAppDisableRule(forBundleID: rule.bundleID)
            }
        } else {
            let rule = browserRulesList[selectedRow]
            RuleManager.shared.removeBrowserRule(rule)
        }
        reloadData()
    }

    // MARK: - Prompts

    @objc private func ruleTypeChanged(_ sender: NSPopUpButton) {
        let row = sender.tag
        guard row < appRules.count else { return }
        let rule = appRules[row]
        let newType = sender.indexOfSelectedItem == 0 ? "focused" : "running"
        guard newType != rule.ruleType else { return }

        // Remove old rule, add new one
        if rule.ruleType == "focused" {
            RuleManager.shared.removeCurrentAppDisableRule(forBundleID: rule.bundleID)
        } else {
            RuleManager.shared.removeRunningAppDisableRule(forBundleID: rule.bundleID)
        }
        if newType == "focused" {
            RuleManager.shared.addCurrentAppDisableRule(forBundleID: rule.bundleID)
        } else {
            RuleManager.shared.addRunningAppDisableRule(forBundleID: rule.bundleID)
        }
        refreshDataArrays()
    }

    private func promptRuleType(forBundleID bundleID: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("prefs.apps.rule_type_title",
                                              comment: "Choose Rule Type")
        alert.informativeText = NSLocalizedString("prefs.apps.rule_type_info",
                                                  comment: "Select when Night Shift should be disabled for this app.")

        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 200, height: 24), pullsDown: false)
        popup.addItem(withTitle: NSLocalizedString("prefs.apps.rule.focused",
                                                   comment: "When focused"))
        popup.addItem(withTitle: NSLocalizedString("prefs.apps.rule.running",
                                                   comment: "When running"))
        alert.accessoryView = popup

        alert.addButton(withTitle: NSLocalizedString("prefs.apps.add", comment: "Add"))
        alert.addButton(withTitle: NSLocalizedString("prefs.apps.cancel", comment: "Cancel"))

        alert.beginSheetModal(for: self.view.window!) { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            if popup.indexOfSelectedItem == 0 {
                RuleManager.shared.addCurrentAppDisableRule(forBundleID: bundleID)
            } else {
                RuleManager.shared.addRunningAppDisableRule(forBundleID: bundleID)
            }
            self?.reloadData()
        }
    }

    private func promptAddDomain() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("prefs.apps.add_domain_title",
                                              comment: "Add Domain Rule")
        alert.informativeText = NSLocalizedString("prefs.apps.add_domain_info",
                                                  comment: "Enter a domain to disable Night Shift for.")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 250, height: 24))
        textField.placeholderString = "example.com"
        alert.accessoryView = textField

        alert.addButton(withTitle: NSLocalizedString("prefs.apps.add", comment: "Add"))
        alert.addButton(withTitle: NSLocalizedString("prefs.apps.cancel", comment: "Cancel"))

        alert.beginSheetModal(for: self.view.window!) { response in
            guard response == .alertFirstButtonReturn else { return }
            let domain = textField.stringValue.trimmingCharacters(in: .whitespaces)
            guard !domain.isEmpty else { return }
            RuleManager.shared.addDomainDisableRule(forDomain: domain)
            self.reloadData()
        }
    }

    // MARK: - Data

    private func refreshDataArrays() {
        let currentAppRules = RuleManager.shared.allCurrentAppDisableRules.map {
            (bundleID: $0.bundleIdentifier, ruleType: "focused")
        }
        let runningAppRules = RuleManager.shared.allRunningAppDisableRules.map {
            (bundleID: $0.bundleIdentifier, ruleType: "running")
        }
        appRules = (currentAppRules + runningAppRules).sorted {
            appName(forBundleID: $0.bundleID) < appName(forBundleID: $1.bundleID)
        }
        browserRulesList = RuleManager.shared.browserRules.sorted { $0.host < $1.host }
    }

    private func reloadData() {
        refreshDataArrays()
        tableView?.reloadData()
        removeButton?.isEnabled = false
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

    private func localizedRuleType(_ ruleType: String) -> String {
        switch ruleType {
        case "focused":
            return NSLocalizedString("prefs.apps.rule.focused", comment: "When focused")
        case "running":
            return NSLocalizedString("prefs.apps.rule.running", comment: "When running")
        default:
            return ruleType
        }
    }

    private func localizedBrowserRuleType(_ type: RuleType) -> String {
        switch type {
        case .domain:
            return NSLocalizedString("prefs.apps.rule.domain", comment: "Domain")
        case .subdomainDisabled:
            return NSLocalizedString("prefs.apps.rule.subdomain_disabled", comment: "Subdomain disabled")
        case .subdomainEnabled:
            return NSLocalizedString("prefs.apps.rule.subdomain_enabled", comment: "Subdomain enabled")
        }
    }
}


// MARK: - NSTableViewDataSource

extension PrefAppsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return currentTab == .appRules ? appRules.count : browserRulesList.count
    }
}


// MARK: - NSTableViewDelegate

extension PrefAppsViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else { return nil }

        if currentTab == .appRules {
            guard row < appRules.count else { return nil }
            let rule = appRules[row]

            switch identifier.rawValue {
            case "icon":
                let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = appIcon(forBundleID: rule.bundleID)
                imageView.imageScaling = .scaleProportionallyDown
                return imageView

            case "name":
                let cellID = NSUserInterfaceItemIdentifier("AppNameCell")
                let cell = tableView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView
                    ?? makeLabelCell(identifier: cellID)
                cell.textField?.stringValue = appName(forBundleID: rule.bundleID)
                return cell

            case "type":
                let popup = NSPopUpButton(frame: .zero, pullsDown: false)
                popup.addItem(withTitle: localizedRuleType("focused"))
                popup.addItem(withTitle: localizedRuleType("running"))
                popup.selectItem(at: rule.ruleType == "focused" ? 0 : 1)
                popup.tag = row
                popup.target = self
                popup.action = #selector(ruleTypeChanged(_:))
                popup.translatesAutoresizingMaskIntoConstraints = false
                popup.controlSize = .small
                popup.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
                return popup

            default:
                return nil
            }
        } else {
            guard row < browserRulesList.count else { return nil }
            let rule = browserRulesList[row]

            switch identifier.rawValue {
            case "domain":
                let cellID = NSUserInterfaceItemIdentifier("DomainCell")
                let cell = tableView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView
                    ?? makeLabelCell(identifier: cellID)
                cell.textField?.stringValue = rule.host
                return cell

            case "type":
                let cellID = NSUserInterfaceItemIdentifier("BrowserRuleTypeCell")
                let cell = tableView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView
                    ?? makeLabelCell(identifier: cellID)
                cell.textField?.stringValue = localizedBrowserRuleType(rule.type)
                return cell

            default:
                return nil
            }
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        removeButton?.isEnabled = tableView.selectedRow >= 0
    }

    private func makeLabelCell(identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = identifier
        let textField = NSTextField(labelWithString: "")
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byTruncatingTail
        cell.addSubview(textField)
        cell.textField = textField
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
            textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
            textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }
}
