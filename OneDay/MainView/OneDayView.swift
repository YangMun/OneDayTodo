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

    @State private var showTextFieldForCategory: Category?
    @State private var todoText: String = ""
    
    @State private var editingTask: Status?
    @State private var editedTaskTitle: String = ""
    
    @State private var completedDates: Set<String> = []

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

                        MonthView(month: currentMonth, selectedDateString: $selectedDateString, onDateSelected: fetchCategoriesForSelectedDate, completedDates: completedDates)

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

                                            if editingTask == task {
                                                TextField("할 일 수정", text: $editedTaskTitle, onCommit: {
                                                    saveEditedTask()
                                                })
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                            } else {
                                                Text(task.title ?? "")
                                                    .foregroundColor(.primary)
                                            }

                                            Spacer()

                                            if editingTask == task {
                                                Button(action: {
                                                    saveEditedTask()
                                                }) {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.green)
                                                }
                                                
                                                Button(action: {
                                                    deleteTask(task)
                                                }) {
                                                    Image(systemName: "xmark")
                                                        .foregroundColor(.red)
                                                }
                                            } else {
                                                Button(action: {
                                                    startEditingTask(task)
                                                }) {
                                                    Image(systemName: "ellipsis")
                                                        .foregroundColor(.primary)
                                                }
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
                                                    .submitLabel(.done)
                                                    .onSubmit {
                                                        saveTask(for: category)
                                                    }

                                                Divider()
                                                    .background(Color.gray)
                                            }

                                            Spacer()

                                            Button(action: {
                                                saveTask(for: category)
                                            }) {
                                                Image(systemName: "plus")
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
                selectTodayDate()
                loadCompletedDates()
            }
            .onDisappear {
                saveCompletedDates()
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
            showTextFieldForCategory = nil
        } else {
            showTextFieldForCategory = category
            todoText = ""
        }
    }

    private func saveTask(for category: Category) {
        guard !todoText.isEmpty else {
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
            todoText = ""
            showTextFieldForCategory = nil
            print("Task saved: \(newTask.title ?? "")")
            fetchTasksForToday()
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
            let dateString = formattedDate(task.selectedDate!)
            completedDates.insert(dateString)
        } else {
            let dateString = formattedDate(task.selectedDate!)
            completedDates.remove(dateString)
            task.selectedDate = nil
        }

        do {
            try viewContext.save()
            fetchTasksForToday()
        } catch {
            print("Failed to toggle completion: \(error.localizedDescription)")
        }
    }

    private func isTaskCompleted(for task: Status) -> Bool {
        return task.isCompleted
    }

    private func selectTodayDate() {
        let today = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        selectedDateString = formatter.string(from: today)
        fetchCategoriesForSelectedDate(date: selectedDateString)
    }

    private func fetchTasksForToday() {
        fetchCategoriesForSelectedDate(date: selectedDateString)
    }

    private func startEditingTask(_ task: Status) {
        editingTask = task
        editedTaskTitle = task.title ?? ""
    }

    private func saveEditedTask() {
        guard let task = editingTask, !editedTaskTitle.isEmpty else {
            editingTask = nil
            return
        }

        task.title = editedTaskTitle
        
        do {
            try viewContext.save()
            print("Task updated: \(task.title ?? "")")
            editingTask = nil
            fetchTasksForToday()
        } catch {
            print("Failed to update task: \(error.localizedDescription)")
        }
    }

    private func deleteTask(_ task: Status) {
        viewContext.delete(task)
        
        do {
            try viewContext.save()
            print("Task deleted")
            editingTask = nil
            fetchTasksForToday()
        } catch {
            print("Failed to delete task: \(error.localizedDescription)")
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func loadCompletedDates() {
        if let savedDates = UserDefaults.standard.array(forKey: "CompletedDates") as? [String] {
            completedDates = Set(savedDates)
        }
    }

    private func saveCompletedDates() {
        UserDefaults.standard.set(Array(completedDates), forKey: "CompletedDates")
    }
}

struct OneDayView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return OneDayView()
            .environment(\.managedObjectContext, context)
    }
}
