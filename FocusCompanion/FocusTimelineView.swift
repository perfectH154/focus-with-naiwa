import SwiftUI
import UIKit

struct FocusTimelineView: View {
    let events: [FocusTimelineEvent]

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var displayedMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()

    private var dayEvents: [FocusTimelineEvent] {
        events
            .filter { Calendar.current.isDate($0.startDate, inSameDayAs: selectedDate) }
            .sorted { $0.startDate < $1.startDate }
    }

    private var monthDates: [Date] {
        let calendar = Calendar.current
        let firstDay = calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
        let leadingDays = calendar.component(.weekday, from: firstDay) - 1
        return (0..<42).compactMap { index in
            calendar.date(byAdding: .day, value: index - leadingDays, to: firstDay)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthNavigation

                weekdayHeader
                monthGrid

                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)

                selectedDayHeading

                if dayEvents.isEmpty {
                    emptyState
                } else {
                    eventList
                }
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("专注时间轴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var monthNavigation: some View {
        HStack(spacing: 14) {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(Color.primary.opacity(0.07), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("上个月")

            Text(monthTitle)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(Color.primary.opacity(0.07), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("下个月")

            Button("今天") {
                let today = Calendar.current.startOfDay(for: Date())
                selectedDate = today
                displayedMonth = Calendar.current.dateInterval(of: .month, for: today)?.start ?? today
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { weekday in
                Text(weekday)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 2)
    }

    private var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 1) {
            ForEach(monthDates, id: \.self) { date in
                let calendar = Calendar.current
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let belongsToMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)

                Button {
                    selectedDate = calendar.startOfDay(for: date)
                    if !belongsToMonth {
                        displayedMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
                    }
                } label: {
                    VStack(spacing: 2) {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(
                                isSelected
                                    ? Color(uiColor: .systemBackground)
                                    : (belongsToMonth ? Color.primary : Color.secondary)
                            )
                            .frame(width: 32, height: 32)
                            .background {
                                if isSelected {
                                    Circle().fill(Color.primary)
                                }
                            }

                        Circle()
                            .fill(hasEvents(on: date) ? Color.blue : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 39)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(date.formatted(date: .long, time: .omitted))
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 9)
    }

    private var selectedDayHeading: some View {
        HStack {
            Text(dateTitle)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            Text("\(dayEvents.count) 个时段")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: displayedMonth)
    }

    private var eventList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(dayEvents) { event in
                    eventRow(event)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }

    private func eventRow(_ event: FocusTimelineEvent) -> some View {
        let accent = event.kind == .focus ? Color.blue : Color.cyan

        return HStack(alignment: .top, spacing: 9) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeText(event.startDate))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()

                Text(timeText(event.endDate))
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .frame(width: 48, alignment: .trailing)
            .padding(.top, 13)

            VStack(spacing: 0) {
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
                    .padding(.top, 14)

                Rectangle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: 1, height: 64)
            }
            .frame(width: 8, height: 86)

            eventBar(event, accent: accent)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 7)
    }

    private func eventBar(_ event: FocusTimelineEvent, accent: Color) -> some View {
        HStack(spacing: 10) {
            Group {
                if let artwork = event.kind == .focus ? MilkEggArtwork.reading : MilkEggArtwork.sleeping {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFit()
                } else {
                    Text(event.kind == .focus ? "📖" : "💤")
                        .font(.system(size: 28))
                }
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.kind == .focus ? "奶蛙专注" : "奶蛙休息")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("\(timeText(event.startDate))～\(timeText(event.endDate)) · \(durationText(for: event))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background(
            accent.opacity(0.12),
            in: RoundedRectangle(cornerRadius: 17, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(accent.opacity(0.2), lineWidth: 1)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "还没有时间记录",
            systemImage: "calendar",
            description: Text("完成一轮专注或休息后，奶蛋会把这段时段记在这里。")
        )
    }

    private var dateTitle: String {
        selectedDate.formatted(
            .dateTime.month(.abbreviated).day().weekday(.wide)
                .locale(Locale(identifier: "zh_CN"))
        )
    }

    private func moveMonth(by offset: Int) {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: offset, to: displayedMonth) else {
            return
        }
        displayedMonth = Calendar.current.dateInterval(of: .month, for: nextMonth)?.start ?? nextMonth
        if !Calendar.current.isDate(selectedDate, equalTo: displayedMonth, toGranularity: .month) {
            selectedDate = displayedMonth
        }
    }

    private func hasEvents(on date: Date) -> Bool {
        events.contains { Calendar.current.isDate($0.startDate, inSameDayAs: date) }
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func durationText(for event: FocusTimelineEvent) -> String {
        let minutes = max(1, Int((event.endDate.timeIntervalSince(event.startDate) / 60).rounded()))
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours == 0 {
            return "\(minutes)分钟"
        }
        if remainingMinutes == 0 {
            return "\(hours)小时"
        }
        return "\(hours)小时\(remainingMinutes)分钟"
    }
}
