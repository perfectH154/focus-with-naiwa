import Foundation
import Combine

enum FocusPhase {
    case focus
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .focus: "专注时间"
        case .shortBreak: "短暂休息"
        case .longBreak: "长休息"
        }
    }

    var duration: Int {
        switch self {
        case .focus: 25 * 60
        case .shortBreak: 5 * 60
        case .longBreak: 15 * 60
        }
    }
}

enum FocusTimelineKind: String, Codable {
    case focus
    case rest
}

struct FocusTimelineEvent: Identifiable, Codable {
    let id: UUID
    let kind: FocusTimelineKind
    let startDate: Date
    let endDate: Date

    init(id: UUID = UUID(), kind: FocusTimelineKind, startDate: Date, endDate: Date) {
        self.id = id
        self.kind = kind
        self.startDate = startDate
        self.endDate = endDate
    }
}

@MainActor
final class FocusTimer: ObservableObject {
    private static let focusDurationKey = "focusDurationMinutes"
    private static let completedSessionsKey = "completedFocusSessions"
    private static let milkEggCountKey = "milkEggCount"
    private static let timelineEventsKey = "focusTimelineEvents"

    @Published private(set) var phase: FocusPhase = .focus
    @Published private(set) var focusDurationMinutes: Int
    @Published private(set) var secondsRemaining: Int
    @Published private(set) var completedFocusSessions: Int
    @Published private(set) var milkEggCount: Int
    @Published private(set) var timelineEvents: [FocusTimelineEvent]
    @Published private(set) var isRunning = false
    @Published private(set) var showMilkEggReward = false

    private var phaseStartDate: Date?

    init() {
        let defaults = UserDefaults.standard
        let savedDuration = defaults.object(forKey: Self.focusDurationKey) as? Int ?? 25
        let durationMinutes = min(max(savedDuration, 1), 180)
        focusDurationMinutes = durationMinutes
        secondsRemaining = durationMinutes * 60
        completedFocusSessions = defaults.integer(forKey: Self.completedSessionsKey)
        milkEggCount = defaults.integer(forKey: Self.milkEggCountKey)
        if let data = defaults.data(forKey: Self.timelineEventsKey),
           let events = try? JSONDecoder().decode([FocusTimelineEvent].self, from: data) {
            timelineEvents = events
        } else {
            timelineEvents = []
        }
    }

    var formattedTime: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var actionTitle: String {
        if isRunning { return "暂停" }
        let initialDuration = phase == .focus ? focusDurationMinutes * 60 : phase.duration
        if secondsRemaining == initialDuration {
            return phase == .focus ? "开始专注" : "开始休息"
        }
        return "继续"
    }

    func setFocusDuration(minutes: Int) {
        guard !isRunning else { return }
        let duration = min(max(minutes, 1), 180)
        focusDurationMinutes = duration
        UserDefaults.standard.set(duration, forKey: Self.focusDurationKey)

        if phase == .focus {
            secondsRemaining = duration * 60
        }
    }

    func toggleRunning() {
        if isRunning {
            isRunning = false
        } else {
            if phaseStartDate == nil {
                phaseStartDate = Date()
            }
            isRunning = true
        }
    }

    func tick() {
        guard isRunning else { return }

        if secondsRemaining > 1 {
            secondsRemaining -= 1
        } else {
            advancePhase()
        }
    }

    func stopForBackground() {
        isRunning = false
        phase = .focus
        secondsRemaining = focusDurationMinutes * 60
        phaseStartDate = nil
    }

    func stopManually() {
        stopForBackground()
    }

    func dismissMilkEggReward() {
        showMilkEggReward = false
    }

    private func advancePhase() {
        let endDate = Date()
        let completedPhase = phase
        let fallbackDuration = completedPhase == .focus
            ? focusDurationMinutes * 60
            : completedPhase.duration
        let startDate = phaseStartDate ?? endDate.addingTimeInterval(TimeInterval(-fallbackDuration))
        let event = FocusTimelineEvent(
            kind: completedPhase == .focus ? .focus : .rest,
            startDate: startDate,
            endDate: endDate
        )
        timelineEvents.append(event)
        timelineEvents.sort { $0.startDate < $1.startDate }
        if let data = try? JSONEncoder().encode(timelineEvents) {
            UserDefaults.standard.set(data, forKey: Self.timelineEventsKey)
        }

        switch phase {
        case .focus:
            completedFocusSessions += 1
            milkEggCount += 1
            UserDefaults.standard.set(completedFocusSessions, forKey: Self.completedSessionsKey)
            UserDefaults.standard.set(milkEggCount, forKey: Self.milkEggCountKey)
            showMilkEggReward = true
            phase = completedFocusSessions.isMultiple(of: 4) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            phase = .focus
        }

        secondsRemaining = phase == .focus ? focusDurationMinutes * 60 : phase.duration
        phaseStartDate = isRunning ? endDate : nil
    }
}
