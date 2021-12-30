//
//  MTEnumeration.swift
//  
//
//  Created by Kavinkumar Veerakumar on 30/12/21.
//

import UIKit

public enum MTIncomingChannel: String {
    case requestPermission = "requestPermission"
    case register = "register"
    case unregister = "unregister"
    case getDeviceToken = "getDeviceToken"
    case showNotification = "showNotification"
    case removeNotification = "removeNotification"
}

public enum MTOutgoingChannel: String {
    case registered = "registered"
    case unregistered = "unregistered"
    case updateDeviceToken = "deviceTokenListener"
    case notificationClickedListener = "notificationClickedListener"
}
