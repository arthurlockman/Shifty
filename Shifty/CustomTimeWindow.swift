//
//  CustomTimeWindow.swift
//  Shifty
//
//  Created by Nate Thompson on 7/21/17.
//
//

import Cocoa
import SwiftUI

class CustomTimeWindow: NSWindowController {

    var disableCustomTime: ((Int) -> Void)?

    convenience init() {
        self.init(window: nil)
    }

    override func showWindow(_ sender: Any?) {
        if window == nil {
            createWindow()
        }
        super.showWindow(sender)
    }

    private func createWindow() {
        let view = CustomTimeView(
            onConfirm: { [weak self] seconds in
                self?.disableCustomTime?(seconds)
                self?.window?.close()
            },
            onCancel: { [weak self] in
                self?.window?.close()
            }
        )

        let hostingView = NSHostingView(rootView: view)
        let size = hostingView.fittingSize

        let win = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.contentView = hostingView
        win.titleVisibility = .hidden
        win.level = .floating
        win.isReleasedWhenClosed = false

        let saveName = "customTimeWindowFrame"
        if UserDefaults.standard.value(forKey: saveName) == nil {
            win.center()
        }
        win.setFrameUsingName(saveName)

        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: win, queue: nil) { _ in
            win.saveFrame(usingName: saveName)
        }

        self.window = win
    }
}
