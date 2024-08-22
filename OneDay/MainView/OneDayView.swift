import SwiftUI
import CoreData

struct OneDayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDateString: String = ""
    @State private var currentMonth: Date = Date()
    @State private var showMenu = false
    @State private var navigateTo: String?
    @State private var userId: UUID?
    @FetchRequest(entity: Category.entity(), sortDescriptors: []) private var categories: FetchedResults<Category>

    @State private var showTextFieldForCategory: Category? // Track the category showing TextField for new task
    @State private var todoText: String = "" // Text entered in the TextField

    var body: some View {
        NavigationView {
            VStack {
                // Custom navigation bar
                HStack {
                    if let userId = userId {
                        HStack {
                            Image(systemName: isTestUser ? "person.fill.xmark" : "person.fill.checkmark")
                        }
                    }
                    Spacer()
                    Menu {
                        Button(action: {
                            navigateTo = "AddCategory"
                        }) {
                            Label("카테고리 등록", systemImage: "plus")
                        }
                        Button(action: {
                            navigateTo = "CategoryManager"
                        }) {
                            Label("카테고리 관리", systemImage: "gearshape")
                        }
                        Button(action: {
                            navigateTo = "ClockTime"
                        }) {
                            Label("알림 시간", systemImage: "clock")
                        }
                    } label: {
                        Image(systemName: "rectangle.and.pencil.and.ellipsis")
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)

                ScrollView {
                    VStack {
                        HStack {
                            Button(action: previousMonth) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.primary)
                            }
                            .disabled(isJanuary2024())
                            
                            Spacer()
                            
                            Text(monthTitle(for: currentMonth))
                                .font(Font.custom("SDSamliphopangcheTTFOutline", size: 30, relativeTo: .largeTitle))
                                .fontWeight(.bold)
                                .padding()
                            
                            Spacer()
                            
                            Button(action: nextMonth) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.primary)
                            }
                        }

                        MonthView(month: currentMonth, selectedDateString: $selectedDateString, onDateSelected: fetchCategoriesForSelectedDate)

                        if categories.isEmpty {
                            Text("카테고리가 없습니다.")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(categories, id: \.self) { category in
                                VStack(alignment: .leading) {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                        Text(category.title ?? "")
                                        Spacer()
                                        Button(action: {
                                            toggleTextField(for: category)
                                        }) {
                                            Image(systemName: "plus")
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 4)

                                    // Show saved tasks for this category
                                    let tasks = fetchTasks(for: category)
                                    ForEach(tasks, id: \.self) { task in
                                        HStack {
                                            Button(action: {
                                                toggleTaskCompletion(for: task)
                                            }) {
                                                Image(systemName: isTaskCompleted(for: task) ? "checkmark.square.fill" : "checkmark.square")
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            Text(task.title ?? "")
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                // Action for modify
                                            }) {
                                                Image(systemName: "ellipsis")
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 4)
                                    }

                                    // Show TextField if this category is active for new task input
                                    if showTextFieldForCategory == category {
                                        HStack {
                                            VStack {
                                                TextField("할 일 입력", text: $todoText)
                                                    .textFieldStyle(PlainTextFieldStyle())
                                                    .padding(.bottom, 4)
                                                    .submitLabel(.done) // Set return key to "Done"
                                                    .onSubmit {
                                                        saveTask(for: category)
                                                    }

                                                Divider()
                                                    .background(Color.gray)
                                            }
                                            
                                            Spacer()

                                            Button(action: {
                                                // Action for modify
                                            }) {
                                                Image(systemName: "ellipsis")
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    
                    NavigationLink(destination: AddCategoryView(), tag: "AddCategory", selection: $navigateTo) { EmptyView() }
                    NavigationLink(destination: CategoryManagerView(), tag: "CategoryManager", selection: $navigateTo) { EmptyView() }
                    NavigationLink(destination: ClockTimeView(), tag: "ClockTime", selection: $navigateTo) { EmptyView() }
                }
            }
            .onAppear {
                currentMonth = getCurrentMonth()
                trackUserID()
                selectTodayDate() // Select today's date when the view appears
            }
        }
    }
    
    private var isTestUser: Bool {
        return userId == UUID(uuidString: "12345678-1234-1234-1234-1234567890ab")
    }
    
    private func trackUserID() {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let users = try viewContext.fetch(fetchRequest)
            if let existingUser = users.first {
                userId = existingUser.id
            } else {
                let newUser = User(context: viewContext)
                newUser.id = UUID()
                userId = newUser.id
                
                try viewContext.save()
            }
        } catch {
            print("Failed to fetch or save user: \(error.localizedDescription)")
        }
    }

    func getCurrentMonth() -> Date {
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month], from: now)
        return Calendar.current.date(from: components)!
    }
    
    func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: date)
    }
    
    func previousMonth() {
        if !isJanuary2024() {
            currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!
        }
    }
    
    func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)!
    }
    
    func isJanuary2024() -> Bool {
        let components = Calendar.current.dateComponents([.year, .month], from: currentMonth)
        return components.year == 2024 && components.month == 1
    }

    private func fetchCategoriesForSelectedDate(date: String) {
        selectedDateString = date
    }
    
    private func toggleTextField(for category: Category) {
        if showTextFieldForCategory == category {
            // Hide the TextField if it was already shown for this category
            showTextFieldForCategory = nil
        } else {
            // Show the TextField for the selected category
            showTextFieldForCategory = category
            todoText = "" // Reset the text for the newly selected category
        }
    }
    
    private func saveTask(for category: Category) {
        guard !todoText.isEmpty else {
            // Hide TextField if no text is entered
            showTextFieldForCategory = nil
            return
        }

        let newTask = Status(context: viewContext)
        newTask.id = UUID()
        newTask.title = todoText
        newTask.isCompleted = false
        newTask.selectedDate = Date()
        newTask.category = category

        do {
            try viewContext.save()
            todoText = "" // Clear the TextField after saving

            // Hide the TextField after saving a task
            showTextFieldForCategory = nil

            print("Task saved: \(newTask.title ?? "")")
            fetchTasksForToday() // Refresh the tasks after saving
        } catch {
            print("Failed to save task: \(error.localizedDescription)")
        }
    }

    private func fetchTasks(for category: Category) -> [Status] {
        let request: NSFetchRequest<Status> = Status.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Status.isCompleted, ascending: false),
            NSSortDescriptor(keyPath: \Status.selectedDate, ascending: false)
        ]

        do {
            let tasks = try viewContext.fetch(request)
            print("Fetched \(tasks.count) tasks for category: \(category.title ?? "")")
            return tasks
        } catch {
            print("Failed to fetch tasks: \(error.localizedDescription)")
            return []
        }
    }
    
    private func toggleTaskCompletion(for task: Status) {
        task.isCompleted.toggle()
        if task.isCompleted {
            task.selectedDate = Date()
        } else {
            task.selectedDate = nil
        }

        do {
            try viewContext.save()
            fetchTasksForToday() // Refresh the tasks after completion status change
        } catch {
            print("Failed to toggle completion: \(error.localizedDescription)")
        }
    }
    
    private func isTaskCompleted(for task: Status) -> Bool {
        return task.isCompleted
    }

    // Helper function to select today's date on app launch
    private func selectTodayDate() {
        let today = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        selectedDateString = formatter.string(from: today)
        fetchCategoriesForSelectedDate(date: selectedDateString)
    }

    // Helper function to refresh tasks for today's date
    private func fetchTasksForToday() {
        fetchCategoriesForSelectedDate(date: selectedDateString)
    }
}



struct OneDayView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return OneDayView()
            .environment(\.managedObjectContext, context)
    }
}
