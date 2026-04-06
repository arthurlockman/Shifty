//
//  CustomTimeView.swift
//  Shifty
//
//  SwiftUI replacement for CustomTimeWindow XIB.
//

import SwiftUI

struct CustomTimeView: View {
    @SwiftUI.State private var hours = ""
    @SwiftUI.State private var minutes = ""

    var onConfirm: (Int) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(NSLocalizedString("customtime.title", comment: ""))
                .font(.headline)

            HStack(spacing: 8) {
                TextField("0", text: $hours)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                    .onChange(of: hours) { filterDigits(&hours, maxLength: 3) }
                Text(NSLocalizedString("customtime.hours", comment: ""))

                TextField("0", text: $minutes)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                    .onChange(of: minutes) { filterDigits(&minutes, maxLength: 3) }
                Text(NSLocalizedString("customtime.minutes", comment: ""))
            }

            HStack(spacing: 12) {
                Button(NSLocalizedString("general.cancel", comment: "")) {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button(NSLocalizedString("general.ok", comment: "")) {
                    let h = Int(hours) ?? 0
                    let m = Int(minutes) ?? 0
                    let totalSeconds = h * 3600 + m * 60
                    if totalSeconds > 0 {
                        onConfirm(totalSeconds)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(totalSeconds == 0)
            }
        }
        .padding(20)
        .frame(width: 300)
    }

    private var totalSeconds: Int {
        (Int(hours) ?? 0) * 3600 + (Int(minutes) ?? 0) * 60
    }

    private func filterDigits(_ value: inout String, maxLength: Int) {
        let filtered = value.filter { $0.isNumber }
        if filtered.count > maxLength {
            value = String(filtered.prefix(maxLength))
        } else if filtered != value {
            value = filtered
        }
    }
}
