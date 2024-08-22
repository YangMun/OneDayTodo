import SwiftUI
import UserNotifications

@main
struct OneDayApp: App {
    
    let persistenceController = PersistenceController.shared
    
    init() {
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            OneDayView()
                .environment(\.managedObjectContext, persistenceController.context)
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission denied: \(error.localizedDescription)")
            }
        }
    }
}
