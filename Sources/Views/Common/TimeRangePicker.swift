import SwiftUI

struct TimeRangePicker: View {
    @Binding var selectedRange: ChartViewModel.TimeRange

    var body: some View {
        Picker("Time Range", selection: $selectedRange) {
            ForEach(ChartViewModel.TimeRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }
}
