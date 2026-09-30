import Combine
import SwiftUI
import UIKit

enum MilkEggArtwork {
    static let icon = load("MilkEggIcon")
    static let reward = load("MilkEggReward")
    static let reading = load("MilkEggReading")
    static let sleeping = load("MilkEggSleeping")

    private static func load(_ name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var timer = FocusTimer()
    @State private var isShowingDurationPicker = false
    @State private var isShowingTimeline = false
    @State private var durationDraft = 25

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var companionVideoURL: URL? {
        let extensions = ["mov", "mp4"]
        let videoNames = colorScheme == .dark
            ? ["FocusCompanionDark", "FocusCompanion"]
            : ["FocusCompanionLight", "FocusCompanion"]

        for videoName in videoNames {
            for fileExtension in extensions {
                if let url = Bundle.main.url(
                    forResource: videoName,
                    withExtension: fileExtension
                ) ?? Bundle.main.url(
                    forResource: videoName,
                    withExtension: fileExtension,
                    subdirectory: "Resources"
                ) {
                    return url
                }
            }
        }
        return nil
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header
                    .padding(.top, 10)

                Spacer(minLength: 8)
                    .frame(maxHeight: 48)

                timerDisplay

                Spacer(minLength: 20)

                companionVideo
                    .frame(height: min(geometry.size.width - 48, geometry.size.height * 0.48))
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 7) {
                Text("离开应用时，本轮专注会自动结束")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)

                controls
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 7)
            .background(Color(uiColor: .systemBackground))
        }
        .onReceive(ticker) { _ in
            timer.tick()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                timer.stopForBackground()
            }
        }
        .sheet(isPresented: $isShowingDurationPicker) {
            durationPicker
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingTimeline) {
            FocusTimelineView(events: timer.timelineEvents)
        }
        .overlay {
            if timer.showMilkEggReward {
                milkEggRewardCard
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: timer.showMilkEggReward)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("奶蛙专注")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("focus with naiwa")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 9) {
                Button {
                    isShowingTimeline = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 40, height: 40)
                        .background(Color.primary.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("查看专注时间轴")

                HStack(spacing: 6) {
                    Group {
                        if let icon = MilkEggArtwork.icon {
                            Image(uiImage: icon)
                                .resizable()
                                .scaledToFit()
                        } else {
                            Text("🥚")
                        }
                    }
                    .frame(width: 25, height: 25)
                    Text("\(timer.milkEggCount)")
                        .foregroundStyle(.primary)
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.06), in: Capsule())
                .accessibilityLabel("累计获得 \(timer.milkEggCount) 颗奶蛋")
            }
        }
    }

    private var milkEggRewardCard: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Group {
                    if let reward = MilkEggArtwork.reward {
                        Image(uiImage: reward)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("🥚")
                            .font(.system(size: 96))
                    }
                }
                    .frame(width: 150, height: 150)
                    .accessibilityHidden(true)

                Text("专注完成，奶蛋 +1")
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("你获得了一颗奶蛋，累计 \(timer.milkEggCount) 颗。")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    timer.dismissMilkEggReward()
                } label: {
                    Text("收下奶蛋")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .background(Color.primary, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(26)
            .frame(maxWidth: 330)
            .background(
                Color(uiColor: .systemBackground),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            }
            .padding(.horizontal, 28)
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: 10) {
            Text(timer.phase.title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Text(timer.formattedTime)
                .font(.system(size: 92, weight: .light, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .accessibilityLabel("剩余时间 \(timer.formattedTime)")

            Button {
                durationDraft = timer.focusDurationMinutes
                isShowingDurationPicker = true
            } label: {
                Label("专注时长 · \(timer.focusDurationMinutes) 分钟", systemImage: "clock")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.primary.opacity(0.06), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(timer.isRunning)
            .opacity(timer.isRunning ? 0.55 : 1)
        }
        .frame(maxWidth: .infinity)
    }

    private var durationPicker: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("选择每轮专注时长")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Picker("专注时长", selection: $durationDraft) {
                    ForEach(1...180, id: \.self) { minutes in
                        Text("\(minutes) 分钟")
                            .tag(minutes)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
            }
            .padding(.horizontal, 24)
            .navigationTitle("专注时长")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingDurationPicker = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        timer.setFocusDuration(minutes: durationDraft)
                        isShowingDurationPicker = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var controls: some View {
        HStack(alignment: .center) {
            Button {
                timer.toggleRunning()
            } label: {
                Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 54, height: 54)
                    .foregroundStyle(.primary)
                    .background(Color.primary.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(timer.isRunning ? "暂停" : timer.actionTitle)

            Spacer(minLength: 16)

            Button {
                timer.stopManually()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 54, height: 54)
                    .foregroundStyle(.primary)
                    .background(Color.primary.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("重置专注计时")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var companionVideo: some View {
        Group {
            if let companionVideoURL {
                LoopingVideoView(
                    url: companionVideoURL,
                    isPlaying: timer.isRunning && timer.phase == .focus
                )
                    .id(companionVideoURL)
            } else {
                videoPlaceholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var videoPlaceholder: some View {
        VStack(spacing: 13) {
            Image(systemName: "play.rectangle")
                .font(.system(size: 34, weight: .ultraLight))

            Text("安静地陪你专注")
                .font(.system(size: 16, weight: .medium, design: .rounded))

            Text("添加 FocusCompanionLight.mov 和 FocusCompanionDark.mov 后，会随外观自动切换")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary.opacity(0.75))
        .padding(24)
    }
}

#Preview {
    ContentView()
}
