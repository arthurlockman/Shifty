//
//  PrefAboutView.swift
//  Shifty
//
//  SwiftUI replacement for PrefAboutViewController.
//

import SwiftUI
import Sparkle

struct PrefAboutView: View {
    private let appName: String
    private let version: String
    private let checkForUpdates: () -> Void
    @AppStorage(Keys.includeBetaUpdates) private var includeBetaUpdates = false

    init() {
        appName = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
            ?? "Shifty"
        version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        checkForUpdates = {
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                appDelegate.updaterController.checkForUpdates(nil)
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // App name and version
            VStack(spacing: 4) {
                Text(appName)
                    .font(.title)
                    .fontWeight(.bold)
                Text(version)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Link rows
            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 10) {
                linkRow(
                    emoji: "🌍",
                    label: String(localized: "about.website"),
                    linkText: "shifty.arosa.dev",
                    url: "https://shifty.arosa.dev"
                )

                linkRow(
                    emoji: "📬",
                    label: String(localized: "about.contact"),
                    linkText: "arthur@rosafamily.net",
                    url: "mailto:arthur@rosafamily.net?subject=Shifty%20Feedback"
                )
            }

            Divider()

            // Buttons
            HStack {
                Button(String(localized: "about.checkForUpdates")) {
                    checkForUpdates()
                    Event.checkForUpdatesClicked.record()
                }

                Button(String(localized: "about.credits")) {
                    if let path = Bundle.main.path(forResource: "credits", ofType: "rtfd") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: path))
                    }
                    Event.creditsClicked.record()
                }
            }

            Toggle(String(localized: "about.includeBetaUpdates"),
                   isOn: $includeBetaUpdates)

            // Copyright
            Text("Original © 2017-2021 Nate Thompson\nRevived in 2026 by Arthur Rosa")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(width: 340)
    }

    @ViewBuilder
    private func linkRow(emoji: String, label: String, linkText: String, url: String) -> some View {
        GridRow {
            Text(emoji)
            Text(label)
                .foregroundStyle(.secondary)
            Link(linkText, destination: URL(string: url)!)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
        }
    }
}

#Preview {
    PrefAboutView()
}
