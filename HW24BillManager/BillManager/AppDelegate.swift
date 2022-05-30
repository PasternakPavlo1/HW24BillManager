import UIKit

// MARK: - Classes
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    //MARK: - Properties
    let remindIdentifier = "RemindIdentifier"
    let markTheBillAsPaidIdentifier = "MarkTheBillAsPaidIdentifier"
    
    // MARK: - Methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let remindAction = UNNotificationAction(identifier: remindIdentifier,
                                                title: "Remind in an 1 hour",
                                                options: [])
        
        let markTheBillAsPaidAction = UNNotificationAction(identifier: markTheBillAsPaidIdentifier,
                                                           title: "Marked the bill as paid",
                                                           options: [.authenticationRequired])
        
        let category = UNNotificationCategory(identifier: Bill.notificationCategoryID,
                                              actions: [remindAction, markTheBillAsPaidAction],
                                              intentIdentifiers: [],
                                              options: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let notificationID = response.notification.request.identifier
        guard var bill = Database.shared.getBill(notificationID: notificationID) else { completionHandler(); return }
        
        switch response.actionIdentifier {
        case remindIdentifier:
            let remindDate = Date().addingTimeInterval(60 * 60)
            
            bill.schedulingReminders(date: remindDate) { (updatedBill) in
                Database.shared.updateAndSave(updatedBill)
            }
        case markTheBillAsPaidIdentifier:
            bill.paidDate = Date()
            Database.shared.updateAndSave(bill)
        default:
            break
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    //MARK: - UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration",
                                    sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}

