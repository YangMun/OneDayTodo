import SwiftUI
import CoreData
import UserNotifications

struct ClockTimeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Time.entity(),
        sortDescriptors: []
    ) private var savedTimes: FetchedResults<Time>
    
    @Environment(\.presentationMode) var presentationMode
    @State private var isPresentingTimePicker = false
    @State private var timeToEdit: Time? = nil
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    goBack()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
                Spacer()
                Text("시간 알림")
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                Button(action: {
                    timeToEdit = nil
                    isPresentingTimePicker.toggle()
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.black)
                }
            }
            .padding()
            
            if savedTimes.isEmpty {
                Text("알림을 설정하면 오늘의 할 일에 대한 알림을 받아보실 수 있습니다.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ForEach(savedTimes) { time in
                    HStack {
                        Text("\(time.ampm ?? "") \(time.hour):\(String(format: "%02d", time.minute))")
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                        
                        Spacer()
                        
                        Button(action: {
                            timeToEdit = time
                            isPresentingTimePicker.toggle()
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: {
                            deleteTime(time)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingTimePicker) {
            TimePickerView(timeToEdit: $timeToEdit)
                .environment(\.managedObjectContext, viewContext) // viewContext 전달
                .presentationDetents([.fraction(0.7)])
        }
        .onAppear {
            requestNotificationPermission()
        }
    }
    
    private func goBack() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func deleteTime(_ time: Time) {
        withAnimation {
            print("삭제하려는 시간: \(time.ampm ?? "") \(time.hour):\(String(format: "%02d", time.minute))")
            cancelNotification(for: time)
            viewContext.delete(time)
            
            do {
                try viewContext.save()
                print("시간 항목 삭제됨: \(time.ampm ?? "") \(time.hour):\(String(format: "%02d", time.minute))")
                timeToEdit = nil
            } catch {
                print("시간 삭제 실패: \(error)")
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    private func cancelNotification(for time: Time) {
        let identifier = "\(time.ampm ?? "")\(time.hour)\(time.minute)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("알림 삭제됨: \(time.ampm ?? "") \(time.hour):\(String(format: "%02d", time.minute))")
    }
}

struct TimePickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var timeToEdit: Time?
    
    @State private var selectedAMPM: String
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var isDuplicate: Bool = false

    init(timeToEdit: Binding<Time?>) {
        self._timeToEdit = timeToEdit
        if let time = timeToEdit.wrappedValue {
            _selectedAMPM = State(initialValue: time.ampm ?? "오전")
            _selectedHour = State(initialValue: Int(time.hour))
            _selectedMinute = State(initialValue: Int(time.minute))
        } else {
            _selectedAMPM = State(initialValue: "오전")
            _selectedHour = State(initialValue: 1)
            _selectedMinute = State(initialValue: 0)
        }
    }

    private var buttonWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return screenWidth >= 430 ? 150 : 130
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray)
                .padding(.top, 13)
            
            Text("시간 설정")
                .font(.headline)
                .padding(.vertical, 16)
            
            HStack(spacing: 10) {
                Text("오전/오후")
                    .font(.subheadline)
                    .padding(.leading, 16)
                    .frame(height: 44)
                
                Spacer()
                
                Button(action: {
                    selectedAMPM = "오전"
                    checkForDuplicate()
                }) {
                    Text("오전")
                        .frame(width: buttonWidth, height: 44)
                        .background(selectedAMPM == "오전" ? Color.black : Color.gray.opacity(0.2))
                        .foregroundColor(selectedAMPM == "오전" ? .white : .black)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    selectedAMPM = "오후"
                    checkForDuplicate()
                }) {
                    Text("오후")
                        .frame(width: buttonWidth, height: 44)
                        .background(selectedAMPM == "오후" ? Color.black : Color.gray.opacity(0.2))
                        .foregroundColor(selectedAMPM == "오후" ? .white : .black)
                        .cornerRadius(10)
                }
                .padding(.trailing, 16)
            }
            .padding(.top, 16)
            
            Divider()
            
            VStack(spacing: 10) {
                HStack {
                    Text("시")
                        .font(.subheadline)
                        .padding(.leading, 16)
                        .frame(height: 44)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(1..<13, id: \.self) { hour in
                        Button(action: {
                            selectedHour = hour
                            checkForDuplicate()
                        }) {
                            Text("\(hour)")
                                .frame(width: 40, height: 40)
                                .background(selectedHour == hour ? Color.black : Color.gray.opacity(0.2))
                                .foregroundColor(selectedHour == hour ? .white : .black)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 16)
            
            Divider()
            
            VStack(spacing: 10) {
                HStack {
                    Text("분")
                        .font(.subheadline)
                        .padding(.leading, 16)
                        .frame(height: 44)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { minute in
                        Button(action: {
                            selectedMinute = minute
                            checkForDuplicate()
                        }) {
                            Text(String(format: "%02d", minute))
                                .frame(width: 40, height: 40)
                                .background(selectedMinute == minute ? Color.black : Color.gray.opacity(0.2))
                                .foregroundColor(selectedMinute == minute ? .white : .black)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 16)
            
            Spacer()
            
            Button(action: {
                saveTime()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("완료")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isDuplicate ? Color.gray : Color.blue) // 중복이면 버튼 비활성화
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .padding(.top, 16)
            .disabled(isDuplicate) // 중복이면 버튼 비활성화
        }
        .background(Color.white)
        .cornerRadius(40)
        .onAppear {
            checkForDuplicate() // Check for duplicates as soon as the view appears
        }
    }
    
    private func saveTime() {
        if let time = timeToEdit {
            // 기존 시간 업데이트
            print("시간 업데이트: \(time.ampm ?? "") \(time.hour):\(String(format: "%02d", time.minute)) -> \(selectedAMPM) \(selectedHour):\(String(format: "%02d", selectedMinute))")
            
            cancelNotification(for: time) // 기존 알림 취소
            time.ampm = selectedAMPM
            time.hour = Int16(selectedHour)
            time.minute = Int16(selectedMinute)
        } else {
            // 새로운 시간 생성
            let newTime = Time(context: viewContext)
            newTime.ampm = selectedAMPM
            newTime.hour = Int16(selectedHour)
            newTime.minute = Int16(selectedMinute)
            removeDuplicateTimes(for: newTime) // 중복 시간 제거
            
            do {
                try viewContext.save()
                print("시간 저장됨: \(selectedAMPM) \(selectedHour):\(String(format: "%02d", selectedMinute))")
                scheduleNotification(for: newTime) // 새로운 시간 객체에 대해 알림 예약
            } catch {
                print("시간 저장 실패: \(error)")
            }
            return
        }

        do {
            try viewContext.save()
            print("시간 업데이트됨: \(timeToEdit?.ampm ?? "") \(timeToEdit?.hour ?? 0):\(String(format: "%02d", timeToEdit?.minute ?? 0))")
            scheduleNotification(for: timeToEdit!)
        } catch {
            print("시간 저장/업데이트 실패: \(error)")
        }
    }
    
    private func removeDuplicateTimes(for time: Time) {
        let fetchRequest: NSFetchRequest<Time> = Time.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "ampm == %@ AND hour == %d AND minute == %d", time.ampm ?? "", time.hour, time.minute)
        
        do {
            let matchingTimes = try viewContext.fetch(fetchRequest)
            if matchingTimes.count > 1 {
                for duplicateTime in matchingTimes.dropFirst() {
                    viewContext.delete(duplicateTime)
                }
            }
        } catch {
            print("Failed to fetch duplicate times: \(error)")
        }
    }
    
    private func checkForDuplicate() {
        let fetchRequest: NSFetchRequest<Time> = Time.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "ampm == %@ AND hour == %d AND minute == %d", selectedAMPM, selectedHour, selectedMinute)
        
        do {
            let matchingTimes = try viewContext.fetch(fetchRequest)
            if let timeToEdit = timeToEdit, matchingTimes.contains(where: { $0 == timeToEdit }) {
                // 현재 편집 중인 시간과 동일한 경우
                isDuplicate = true
            } else {
                isDuplicate = !matchingTimes.isEmpty
            }
        } catch {
            print("Failed to check for duplicate times: \(error)")
            isDuplicate = false
        }
    }
    
    // scheduleNotification 함수 내에서 사용 예시
    private func scheduleNotification(for time: Time) {
        let content = UNMutableNotificationContent()
        content.title = "할 일 알림"
        
        // 커스텀 함수로 알림 본문 생성
        content.body = buildNotificationBody(context: viewContext)
        
        content.sound = UNNotificationSound.default
        
        var hour = Int(time.hour)
        if time.ampm == "오후" && hour < 12 {
            hour += 12
        } else if time.ampm == "오전" && hour == 12 {
            hour = 0
        }

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = Int(time.minute)

        let identifier = "\(time.ampm ?? "")\(time.hour)\(time.minute)"
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 예약 오류: \(error)")
            }
        }
    }
    
    func buildNotificationBody(context: NSManagedObjectContext) -> String {
        let fetchRequest: NSFetchRequest<Status> = Status.fetchRequest()
        
        do {
            // Fetch all the Status entities and extract their title properties
            let statuses = try context.fetch(fetchRequest)
            let titles = statuses.compactMap { $0.title } // Get only non-nil titles
            
            if titles.isEmpty {
                return "매일의 결심이 소중합니다." // Default message if there are no titles
            } else {
                // Decorate each title with a bullet or dash
                let decoratedTitles = titles.map { "• \($0)" } // You can replace "•" with "-" if you prefer dashes
                
                if titles.count >= 3 {
                    let firstTwoTitles = decoratedTitles.prefix(2)
                    return firstTwoTitles.joined(separator: "\n") + "\n그리고 다른 할 일"
                } else {
                    return decoratedTitles.joined(separator: "\n")
                }
            }
        } catch {
            print("title 가져오기 실패: \(error)")
            return "매일의 결심이 소중합니다." // Fallback message in case of error
        }
    }




    private func cancelNotification(for time: Time) {
        let identifier = "\(time.ampm ?? "")\(time.hour)\(time.minute)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("알림 삭제됨: \(time.ampm ?? "") \(time.hour):\(String(format: "%02d", time.minute))")
    }
}

struct ClockTimeView_Previews: PreviewProvider {
    static var previews: some View {
        ClockTimeView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
