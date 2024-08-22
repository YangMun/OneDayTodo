import SwiftUI
import CoreData

struct AddCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var categoryName: String = ""
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            TextField("카테고리 입력", text: $categoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Spacer()
        }
        .navigationBarTitle("카테고리 등록", displayMode: .inline)
        .navigationBarItems(trailing: Button("완료") {
            saveCategory()
        })
    }

    private func saveCategory() {
        guard !categoryName.isEmpty else {
            // Handle empty category name if needed
            return
        }
        
        // Fetch the current user (assuming userId is stored somewhere accessible)
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let users = try viewContext.fetch(fetchRequest)
            if let currentUser = users.first {
                // Create a new Category entity
                let newCategory = Category(context: viewContext)
                newCategory.id = UUID()
                newCategory.title = categoryName
                newCategory.user = currentUser
                
                // Save the context
                try viewContext.save()
                
                // Navigate back to OneDayView
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            print("Failed to save category: \(error.localizedDescription)")
        }
    }
}

struct AddCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddCategoryView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
