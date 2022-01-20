import Flutter
import UIKit
import UserNotifications

@available(iOS 10.0, *)
public class SwiftPushnotificationPlugin: NSObject, FlutterPlugin {
    
    private var methodChannel: FlutterMethodChannel?
    private var rawOptions: [String: Bool] = [:]
    private var currentOptions: UNAuthorizationOptions = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var pendingNotification: [String: Any]?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.vignesh.pushnotification/messaging", binaryMessenger: registrar.messenger())
        let instance = SwiftPushnotificationPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    init(channel: FlutterMethodChannel) {
        super.init()
        methodChannel = channel
        notificationCenter.delegate = self
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let event = MTIncomingChannel(rawValue: call.method) else {
            return result(nil)
        }
        switch event {
        case .requestPermission:
            let options = call.arguments as? [String: Bool] ?? [:]
            requestPermission(options: options, result: result)
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
            let devicetoken = MTUserDefaults.shared.deviceToken
            result(devicetoken)
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
        case .pendingNotification:
            if let pendingNotification = pendingNotification {
                let payload = generatePayload(with: pendingNotification)
                result(payload)
            } else {
                result(nil)
            }
            break
        }
    }
    
    // MARK: - Notification methods
    
    public func requestPermission(options: [String: Bool], result: @escaping FlutterResult) {
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
        
        self.currentOptions = currentOptions
        
        notificationCenter.requestAuthorization(options: currentOptions) { granted, error in
            if let error = error {
                NSLog("Error while requesting pushnotification permission: %@", error.localizedDescription)
            }
            if granted {
                self.registerPushNotification()
                result(true)
            } else {
                result(false)
            }
        }
    }
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        MTUserDefaults.shared.deviceToken = tokenString
        invokeMethod(.updateDeviceToken, arguments: tokenString)
    }
    
    // MARK: - Register methods
    
    public func registerPushNotification() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    public func unregisterNotification() {
        DispatchQueue.main.async {
            UIApplication.shared.unregisterForRemoteNotifications()
            MTUserDefaults.shared.deviceToken = nil
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
        notificationContent.badge = NSNumber(value: payload.badge ?? 0)
        
        if let image = payload.image, let url = Bundle.main.url(forResource: image, withExtension: payload.fileType) {
            if let attachment = try? UNNotificationAttachment(identifier: image, url: url, options: nil) {
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
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        if let remoteNotification = launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] as? [String: Any] {
            pendingNotification = remoteNotification
        }
        return true
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let payload = generatePayload(with: userInfo)
        completionHandler(.noData)
    }
    
    public func invokeMethod(_ method: MTOutgoingChannel, arguments: Any?) {
        methodChannel?.invokeMethod(method.rawValue, arguments: arguments)
    }
    
    public func generatePayload(with userInfo: [AnyHashable: Any]) -> [AnyHashable: Any] {
        guard let aps = userInfo["aps"] as? [AnyHashable: Any] else { return userInfo }
        var payload = [AnyHashable: Any]()
        payload["notification"] = ["title": aps["title"], "apple": aps]
        payload["data"] = userInfo["acme2"]
        return payload
    }
    
}

@available(iOS 10.0, *)
extension SwiftPushnotificationPlugin: UNUserNotificationCenterDelegate {
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.sound, .badge, .banner, .list])
        } else {
            completionHandler([.sound, .badge, .alert])
        }
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        let payload = generatePayload(with: userInfo)
        invokeMethod(.notificationClickedListener, arguments: payload)
        completionHandler(.noData)
        return true
    }
    
}

public struct Payload: Codable {
    var title: String
    var body: String
    var badge: Int?
    var image: String?
    var fileType: String?
    var identifier: String
}

class MTUserDefaults: NSObject {
    
    static let shared: MTUserDefaults = MTUserDefaults()
    
    let deviceTokenKey = "DeviceToken"
    
    var deviceToken: String? {
        get {
            return UserDefaults.standard.string(forKey: deviceTokenKey)
        } set {
            UserDefaults.standard.set(newValue, forKey: deviceTokenKey)
        }
    }
    
}
