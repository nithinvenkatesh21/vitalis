import SwiftUI
import SwiftData
import VitalisPersistence

@main
struct VitalisApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(VitalisDataController.shared.container)
    }
}
