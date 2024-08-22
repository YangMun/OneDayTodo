//import SwiftUI
//import CoreData
//
//struct OneDayView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//    @State private var showModal = false
//    @State private var selectedDateString: String = ""
//    @State private var currentMonth: Date = Date()
//    @State private var showMenu = false
//    @State private var navigateTo: String?
//    @State private var userId: UUID?
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                ScrollView {
//                    VStack {
//                        HStack {
//                            Spacer()
//                            Menu {
//                                Button(action: {
//                                    navigateTo = "AddCategory"
//                                }) {
//                                    Label("카테고리 등록", systemImage: "plus")
//                                }
//                                Button(action: {
//                                    navigateTo = "CategoryManager"
//                                }) {
//                                    Label("카테고리 관리", systemImage: "gearshape")
//                                }
//                                Button(action: {
//                                    navigateTo = "ClockTime"
//                                }) {
//                                    Label("알림 시간", systemImage: "clock")
//                                }
//                            } label: {
//                                Image(systemName: "rectangle.and.pencil.and.ellipsis")
//                                    .foregroundColor(.primary)
//                            }
//                        }
//                        HStack {
//                            Button(action: previousMonth) {
//                                Image(systemName: "chevron.left")
//                                    .foregroundColor(.primary)
//                            }
//                            .disabled(isJanuary2024())
//                            
//                            Spacer()
//                            
//                            Text(monthTitle(for: currentMonth))
//                                .font(Font.custom("SDSamliphopangcheTTFOutline", size: 30, relativeTo: .largeTitle))
//                                .fontWeight(.bold)
//                                .padding()
//                            
//                            Spacer()
//                            
//                            Button(action: nextMonth) {
//                                Image(systemName: "chevron.right")
//                                    .foregroundColor(.primary)
//                            }
//                        }
//                        .padding()
//                        
//                        MonthView(month: currentMonth, selectedDateString: $selectedDateString, showModal: $showModal)
//                    }
//                    .padding()
//                    
//                    NavigationLink(destination: AddCategoryView(), tag: "AddCategory", selection: $navigateTo) { EmptyView() }
//                    NavigationLink(destination: CategoryManagerView(), tag: "CategoryManager", selection: $navigateTo) { EmptyView() }
//                    NavigationLink(destination: ClockTimeView(), tag: "ClockTime", selection: $navigateTo) { EmptyView() }
//                }
//                
//                if showModal {
//                    ModalView(showModal: $showModal, selectedDateString: selectedDateString)
//                        .background(Color.black.opacity(0.6).ignoresSafeArea())
//                }
//            }
//            .onAppear {
//                currentMonth = getCurrentMonth()
//                trackUserID()
//            }
//        }
//    }
//
//    private func trackUserID() {
//        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
//        fetchRequest.fetchLimit = 1
//        
//        do {
//            let users = try viewContext.fetch(fetchRequest)
//            if let existingUser = users.first {
//                // User already exists
//                userId = existingUser.id
//                print("이미 저장된 아이디:", userId)
//            } else {
//                // No user found, create a new one
//                let newUser = User(context: viewContext)
//                newUser.id = UUID()
//                userId = newUser.id
//                
//                // Save the context to persist the new user
//                try viewContext.save()
//                print("아이디 저장하겠음:", userId)
//            }
//        } catch {
//            print("Failed to fetch or save user: \(error.localizedDescription)")
//        }
//    }
//    
//    func getCurrentMonth() -> Date {
//        let now = Date()
//        let components = Calendar.current.dateComponents([.year, .month], from: now)
//        return Calendar.current.date(from: components)!
//    }
//    
//    func monthTitle(for date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.locale = Locale(identifier: "ko_KR")
//        formatter.dateFormat = "yyyy년 M월"
//        return formatter.string(from: date)
//    }
//    
//    func previousMonth() {
//        if !isJanuary2024() {
//            currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!
//        }
//    }
//    
//    func nextMonth() {
//        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)!
//    }
//    
//    func isJanuary2024() -> Bool {
//        let components = Calendar.current.dateComponents([.year, .month], from: currentMonth)
//        return components.year == 2024 && components.month == 1
//    }
//}
//
//struct MonthView: View {
//    let month: Date
//    @Binding var selectedDateString: String
//    @Binding var showModal: Bool
//    
//    var body: some View {
//        VStack {
//            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
//                ForEach(daysOfWeek(), id: \.self) { day in
//                    Text(day)
//                        .frame(maxWidth: .infinity)
//                        .font(Font.custom("MangoDdobak-R", size: 20, relativeTo: .subheadline))
//                        .fontWeight(.bold)
//                        .foregroundColor(.gray)
//                }
//                
//                ForEach(datesInMonth(month: month), id: \.self) { date in
//                    if let date = date {
//                        let dateString = formattedDate(date)
//                        
//                        Text("\(Calendar.current.component(.day, from: date))")
//                            .font(Font.custom("KNPSKkomi", size: 15, relativeTo: .body))
//                            .frame(width: 40, height: 40)
//                            .background(Color.blue.opacity(0.2))
//                            .foregroundColor(.primary)
//                            .cornerRadius(8)
//                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
//                            .onTapGesture {
//                                selectedDateString = dateString
//                                showModal = true
//                            }
//                    } else {
//                        Color.clear
//                            .frame(width: 40, height: 40)
//                    }
//                }
//            }
//        }
//        .padding()
//    }
//    
//    func datesInMonth(month: Date) -> [Date?] {
//        var dates = [Date?]()
//        let range = Calendar.current.range(of: .day, in: .month, for: month)!
//        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: month))!
//        
//        let firstWeekday = Calendar.current.component(.weekday, from: startOfMonth)
//        for _ in 1..<firstWeekday {
//            dates.append(nil)
//        }
//        
//        for day in range {
//            let date = Calendar.current.date(byAdding: .day, value: day - 1, to: startOfMonth)!
//            dates.append(date)
//        }
//        
//        while dates.count % 7 != 0 {
//            dates.append(nil)
//        }
//        
//        return dates
//    }
//    
//    func daysOfWeek() -> [String] {
//        let formatter = DateFormatter()
//        formatter.locale = Locale(identifier: "ko_KR")
//        return formatter.veryShortStandaloneWeekdaySymbols
//    }
//    
//    func formattedDate(_ date: Date?) -> String {
//        guard let date = date else { return "" }
//        let formatter = DateFormatter()
//        formatter.locale = Locale(identifier: "ko_KR")
//        formatter.dateFormat = "yyyy-MM-dd"
//        return formatter.string(from: date)
//    }
//}
//
//struct ModalView: View {
//    @Binding var showModal: Bool
//    let selectedDateString: String
//
//    var body: some View {
//        ZStack {
//            Color.black.opacity(0.8)
//                .ignoresSafeArea()
//                .onTapGesture {
//                    showModal = false
//                }
//            
//            VStack {
//                Text("Selected Date: \(selectedDateString)")
//                    .padding()
//                    .background(Color.white)
//                    .cornerRadius(10)
//                
//                Spacer()
//                
//                Button(action: {
//                    showModal = false
//                }) {
//                    Text("Close")
//                        .font(.headline)
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }
//                .padding(.bottom, 20)
//            }
//            .padding()
//            .background(Color.white)
//            .cornerRadius(20)
//            .shadow(radius: 10)
//        }
//    }
//}
//
//struct OneDayView_Previews: PreviewProvider {
//    static var previews: some View {
//        let context = PersistenceController.preview.container.viewContext
//        
//        // Create a mock User in the preview context
//        let mockUser = User(context: context)
//        mockUser.id = UUID(uuidString: "12345678-1234-1234-1234-1234567890ab")!
//        
//        return OneDayView()
//            .environment(\.managedObjectContext, context)
//    }
//}
