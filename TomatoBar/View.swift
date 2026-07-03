import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI
import RevenueCat

extension KeyboardShortcuts.Name {
    static let startStopTimer = Self("startStopTimer")
}

private struct IntervalsView: View {
    @EnvironmentObject var timer: TBTimer

    var body: some View {
        VStack {
            Stepper(value: $timer.workIntervalLength, in: 1 ... 60) {
                Text("Work interval:")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(timer.workIntervalLength) min")
            }
            Stepper(value: $timer.shortRestIntervalLength, in: 1 ... 60) {
                Text("Short rest interval:")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(timer.shortRestIntervalLength) min")
            }
            Stepper(value: $timer.longRestIntervalLength, in: 1 ... 60) {
                Text("Long rest interval:")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(timer.longRestIntervalLength) min")
            }
            .help("Duration of the lengthy break, taken after finishing work interval set")
            Stepper(value: $timer.workIntervalsInSet, in: 1 ... 10) {
                Text("Work intervals in a set:")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(timer.workIntervalsInSet)")
            }
            .help("Number of working intervals in the set, after which a lengthy break taken")
            .disabled(true)
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}

private struct SettingsView: View {
    @EnvironmentObject var timer: TBTimer
    @ObservedObject private var userModel = UserViewModel.shared
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable


    var body: some View {
        VStack {
            KeyboardShortcuts.Recorder(for: .startStopTimer) {
                Text("Shortcut")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Toggle(isOn: $timer.stopAfterBreak) {
                Text("Stop after break")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            Toggle(isOn: $timer.showTimerInMenuBar) {
                Text("Show timer in menu bar")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
                .onChange(of: timer.showTimerInMenuBar) { _ in
                    timer.updateTimeLeft()
                }
            Toggle(isOn: $launchAtLogin.isEnabled) {
                Text("Launch at login")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            Spacer().frame(minHeight: 0)
            if !userModel.hasPremiumAccess {
                Text("Upgrade to unlock")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .italic(true)
                    //.background(Color.gray)
                    .cornerRadius(20)
            }
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
        .disabled(!userModel.hasPremiumAccess)
    }
}

private struct SoundsView: View {
    @EnvironmentObject var timer: TBTimer

    var body: some View {
        VStack {
            Toggle(isOn: $timer.isWindupEnabled) {
                Text("Windup")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)
            Toggle(isOn: $timer.isDingEnabled) {
                Text("Ding")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)
            Toggle(isOn: $timer.isTickingEnabled) {
                Text("Ticking")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)
            .onChange(of: timer.isTickingEnabled) { _ in
                timer.toggleTicking()
            }
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}

private enum ChildView {
    case intervals, settings, sounds
}

private struct UpgradeButton: View {
    var body: some View {
        if #available(macOS 14.0, *) {
            SettingsLink {
                label
            }
            .buttonStyle(.bordered)
            .keyboardShortcut("a")
        } else {
            Button {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                label
            }
            .buttonStyle(.bordered)
            .keyboardShortcut("a")
        }
    }

    private var label: some View {
        HStack {
            Text("Upgrade to PRO")
            Spacer()
            Text("⌘ A").foregroundColor(Color.gray)
        }
    }
}

struct TBPopoverView: View {
    @ObservedObject var timer = TBTimer()
    @ObservedObject private var userModel = UserViewModel.shared
    @State private var buttonHovered = false
    @State private var activeChildView = ChildView.intervals
    @State private var showDetails = false

    private var showAboutButton = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                timer.startStop()
                TBStatusItem.shared.closePopover(nil)
            } label: {
                Text(timer.timer != nil ? (buttonHovered ? "Stop" : timer.timeLeftString) : "Start")
                    /*
                      When appearance is set to "Dark" and accent color is set to "Graphite"
                      "defaultAction" button label's color is set to the same color as the
                      button, making the button look blank. #24
                     */
                    .foregroundColor(Color.white)
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity)
            }
            .onHover { over in
                buttonHovered = over
            }
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .task {
                await userModel.refreshRevenueCatState()
            }

            Picker("", selection: $activeChildView) {
                Text("Intervals").tag(ChildView.intervals)
                Text("Settings").tag(ChildView.settings)
                Text("Sounds").tag(ChildView.sounds)
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .pickerStyle(.segmented)

            GroupBox {
                switch activeChildView {
                case .intervals:
                    IntervalsView().environmentObject(timer)
                case .settings:
                    SettingsView().environmentObject(timer)
                case .sounds:
                    SoundsView().environmentObject(timer)
                }
            }

            Group {
                if (showAboutButton) {
                    Button {
                        NSApp.activate(ignoringOtherApps: true)
                        NSApp.orderFrontStandardAboutPanel()
                    } label: {
                        Text("About")
                        Spacer()
                        Text("⌘ A").foregroundColor(Color.gray)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("a")
                    .hidden()
                }
                
                if !userModel.hasPremiumAccess {
                    UpgradeButton()
                }
                
                Button {
                    NSApplication.shared.terminate(self)
                } label: {
                    Text("Quit")
                    Spacer()
                    Text("⌘ Q").foregroundColor(Color.gray)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("q")
            }
        }
        .frame(width: 300, height: 370)
        .padding(12)
    }
}
