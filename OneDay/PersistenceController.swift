import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    // Preview instance for SwiftUI Previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        controller.addSampleData(context: controller.container.viewContext)
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CategoryModel") // Name should match your .xcdatamodeld file
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    var context: NSManagedObjectContext {
        return container.viewContext
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func addSampleData(context: NSManagedObjectContext) {
        // Create a mock User
        let mockUser = User(context: context)
        mockUser.id = UUID(uuidString: "12345678-1234-1234-1234-1234567890ab")!

        // Create a mock Category
        let mockCategory = Category(context: context)
        mockCategory.id = UUID()
        mockCategory.title = "예시 카테고리"
        mockCategory.user = mockUser
        
        let sampleTime1 = Time(context: context)
        sampleTime1.ampm = "오전"
        sampleTime1.hour = 9
        sampleTime1.minute = 30

        let sampleTime2 = Time(context: context)
        sampleTime2.ampm = "오후"
        sampleTime2.hour = 5
        sampleTime2.minute = 45

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

}
