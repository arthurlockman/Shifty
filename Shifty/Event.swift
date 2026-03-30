//
//  Event.swift
//  Shifty
//
//  Created by Nate Thompson on 7/27/17.
//
//

import Foundation

enum Event {
    case appLaunched(preferredLocalization: String)
    case oldMacOSVersion(version: String)
    case unsupportedHardware

    //StatusMenuController
    case menuOpened
    case toggleNightShift(state: Bool)
    case disableForCurrentApp(state: Bool)
    case disableForHour(state: Bool)
    case disableForCustomTime(state: Bool, timeInterval: Int?)
    case disableForDomain(state: Bool)
    case disableForSubdomain(state: Bool)
    case preferencesWindowOpened
    case quitShifty

    //SliderView
    case enableSlider
    case sliderMoved(value: Float)

    //Preferences
    case preferences(autoLaunch: Bool, quickToggle: Bool, iconSwitching: Bool, websiteShifting: Bool, trueToneControl: Bool, schedule: ScheduleType)
    case shortcuts(toggleNightShift: Bool, increaseColorTemp: Bool, decreaseColorTemp: Bool, disableApp: Bool, disableDomain: Bool, disableSubdomain: Bool, disableHour: Bool, disableCustom: Bool, toggleTrueTone: Bool, toggleDarkMode: Bool)
    case websiteButtonClicked
    case feedbackButtonClicked
    case twitterButtonClicked
    case translateButtonClicked
    case donateButtonClicked
    case checkForUpdatesClicked
    case creditsClicked

    //Errors
    case accessibilityRevokedAlertShown

    func record() {
        // Analytics removed — previously sent to AppCenter
    }
}
