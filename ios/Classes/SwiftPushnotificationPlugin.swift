import Flutter
import UIKit
import UserNotifications

@available(iOS 10.0, *)
public class SwiftPushnotificationPlugin: NSObject, FlutterPlugin {
    
    private var methodChannel: FlutterMethodChannel?
    private var rawOptions: [String: Bool] = [:]
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var currentDeviceToken: String?
    private var pendingNotification: [String: Any]?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pushnotification", binaryMessenger: registrar.messenger())
        let instance = SwiftPushnotificationPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    init(channel: FlutterMethodChannel) {
        methodChannel = channel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let event = MTIncomingChannel(rawValue: call.method)
        switch event {
        case .requestPermission:
            let options = call.arguments as? [String: Bool] ?? [:]
            requestPermission(options: options)
            result(true)
        case .register:
            registerPushNotification()
            result(true)
            break
        case .unregister:
            unregisterNotification()
            result(true)
            break
        case .getDeviceToken:
            result(currentDeviceToken)
            break
        case .showNotification:
            let args = call.arguments as? [String: Any] ?? [:]
            let data = try? JSONSerialization.data(withJSONObject: args, options: [])
            guard let payload = try? JSONDecoder().decode(Payload.self, from: data ?? Data()) else { break }
            showNotification(payload: payload)
            result(true)
            break
        case .removeNotification:
            removeNotification()
            result(true)
            break
        case .none:
            break
        }
    }
    
    // MARK: - Notification methods
    
    public func requestPermission(options: [String: Bool]) {
        var currentOptions: UNAuthorizationOptions = []
        rawOptions = options
        
        if options["sound"] ?? false {
            currentOptions.insert(.sound)
        }
        if options["alert"] ?? false {
            currentOptions.insert(.alert)
        }
        if options["badge"] ?? false {
            currentOptions.insert(.badge)
        }
        
        notificationCenter.requestAuthorization(options: currentOptions) { granted, error in
            if let error = error {
                NSLog("Error while requesting pushnotification permission: %@", error.localizedDescription)
            }
            if granted {
                self.registerPushNotification()
            } else {
                
            }
        }
    }
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        currentDeviceToken = tokenString
        invokeMethod(.updateDeviceToken, arguments: tokenString)
    }
    
    // MARK: - Register methods
    
    public func registerPushNotification() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            self.invokeMethod(.registered, arguments: self.rawOptions)
        }
    }
    
    public func unregisterNotification() {
        DispatchQueue.main.async {
            UIApplication.shared.unregisterForRemoteNotifications()
            self.invokeMethod(.unregistered, arguments: self.rawOptions)
        }
    }
    
    public func removeNotification() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    public func showNotification(payload: Payload) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = payload.title
        notificationContent.body = payload.body
        notificationContent.badge = NSNumber(value: payload.badge)
        
        if let url = Bundle.main.url(forResource: payload.image, withExtension: payload.fileType) {
            if let attachment = try? UNNotificationAttachment(identifier: payload.image, url: url, options: nil) {
                notificationContent.attachments = [attachment]
            }
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: payload.identifier, content: notificationContent, trigger: trigger)
        
        notificationCenter.add(request) { (error) in
            if let error = error {
                NSLog("Error on showing pushnotification identifier: %s error: %s", payload.identifier, error.localizedDescription)
            }
        }
    }
    
    public func invokeMethod(_ method: MTOutgoingChannel, arguments: Any?) {
        methodChannel?.invokeMethod(method.rawValue, arguments: arguments)
    }
    
}

@available(iOS 10.0, *)
extension SwiftPushnotificationPlugin: UNUserNotificationCenterDelegate {
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        invokeMethod(.notificationClickedListener, arguments: userInfo)
        completionHandler(.noData)
        return true
    }
    
}

public struct Payload: Codable {
    var title: String
    var body: String
    var badge: Int
    var image: String
    var fileType: String
    var identifier: String
}
