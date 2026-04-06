//
//  AccessibilityPromptView.swift
//  Shifty
//
//  Prompts the user to grant Accessibility permissions.
//

import SwiftUI
import AXSwift

struct AccessibilityPromptView: View {

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text(NSLocalizedString("accessibility.title", comment: ""))
                .font(.headline)

            Text(NSLocalizedString("accessibility.message", comment: ""))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    instructionRow(number: "1", text: NSLocalizedString("accessibility.step1", comment: ""))
                    instructionRow(number: "2", text: NSLocalizedString("accessibility.step2", comment: ""))
                    instructionRow(number: "3", text: NSLocalizedString("accessibility.step3", comment: ""))
                }
                .padding(4)
            }
            .frame(maxWidth: 340)

            HStack(spacing: 12) {
                Button(NSLocalizedString("alert.not_now", comment: "")) {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.cancelAction)

                Button(NSLocalizedString("alert.open_preferences", comment: "")) {
                    NSWorkspace.shared.open(
                        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    )
                }
                .keyboardShortcut(.defaultAction)
            }

            Button(NSLocalizedString("accessibility.help", comment: "")) {
                NSWorkspace.shared.open(
                    URL(string: "https://support.apple.com/guide/mac-help/allow-accessibility-apps-to-access-your-mac-mh43185")!
                )
            }
            .buttonStyle(.link)
            .font(.caption)
        }
        .padding(24)
        .frame(width: 400)
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(.blue))
            Text(text)
                .font(.callout)
        }
    }
}

// MARK: - Modal Window Presentation

private class ModalWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApp.stopModal()
    }
}

enum AccessibilityPrompt {
    private static var windowDelegate: ModalWindowDelegate?

    static func showModal() {
        let view = AccessibilityPromptView()
        let hostingView = NSHostingView(rootView: view)
        let size = hostingView.fittingSize

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.center()
        window.title = NSLocalizedString("accessibility.title", comment: "")
        window.isReleasedWhenClosed = false

        let delegate = ModalWindowDelegate()
        window.delegate = delegate
        windowDelegate = delegate

        DispatchQueue.main.async {
            NSApp.runModal(for: window)
            windowDelegate = nil
        }
    }
}

#Preview {
    AccessibilityPromptView()
}
