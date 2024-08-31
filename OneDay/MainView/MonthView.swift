import SwiftUI

struct MonthView: View {
    let month: Date
    @Binding var selectedDateString: String
    var onDateSelected: (String) -> Void
    var completedDates: Set<String>
    
    var body: some View {
        VStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(daysOfWeek(), id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(Font.custom("MangoDdobak-R", size: 20, relativeTo: .subheadline))
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                
                ForEach(datesInMonth(month: month), id: \.self) { date in
                    if let date = date {
                        let dateString = formattedDate(date)
                        
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(Font.custom("KNPSKkomi", size: 15, relativeTo: .body))
                            .frame(width: 40, height: 40)
                            .background(
                                Group {
                                    if selectedDateString == dateString {
                                        Color.blue.opacity(0.5)
                                    } else if completedDates.contains(dateString) {
                                        Color.green.opacity(0.3)
                                    } else {
                                        Color.blue.opacity(0.2)
                                    }
                                }
                            )
                            .cornerRadius(8)
                            .foregroundColor(.primary)
                            .shadow(color: selectedDateString == dateString ? .blue : .gray, radius: selectedDateString == dateString ? 4 : 2, x: 0, y: 2)
                            .overlay(
                                completedDates.contains(dateString) ?
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                        .font(.system(size: 12))
                                        .offset(x: 12, y: -12)
                                    : nil
                            )
                            .onTapGesture {
                                onDateSelected(dateString)
                            }
                    } else {
                        Color.clear
                            .frame(width: 40, height: 40)
                    }
                }
            }
        }
        .padding()
    }
    
    func datesInMonth(month: Date) -> [Date?] {
        var dates = [Date?]()
        let range = Calendar.current.range(of: .day, in: .month, for: month)!
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: month))!
        
        let firstWeekday = Calendar.current.component(.weekday, from: startOfMonth)
        for _ in 1..<firstWeekday {
            dates.append(nil)
        }
        
        for day in range {
            let date = Calendar.current.date(byAdding: .day, value: day - 1, to: startOfMonth)!
            dates.append(date)
        }
        
        while dates.count % 7 != 0 {
            dates.append(nil)
        }
        
        return dates
    }
    
    func daysOfWeek() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.veryShortStandaloneWeekdaySymbols
    }
    
    func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
