import 'package:pushnotification/PushNotificationMananger.dart';

abstract class PushNotificationInterface {
  /// Fires when a new token is generated.
  Stream<String> get deviceTokenChangeListener {
    throw UnimplementedError(
      'deviceTokenChangeListener is not implemented',
    );
  }

  /// Returns the default token for this device and optionally [senderId].
  Future<String> getDeviceToken() {
    throw UnimplementedError(
      'getDeviceToken() is not implemented',
    );
  }

  /// To request the permission for push notification in app
  ///
  /// Request push notification permision
  Future<void> registerDevice() {
    throw UnimplementedError(
      'unRegisterDevice() is not implemented',
    );
  }

  /// Removes access to an token previously authorized with optional [senderId].
  ///
  /// Messages sent by the server to this token will fail.
  Future<void> unregisterDevice() {
    throw UnimplementedError(
      'unRegisterDevice() is not implemented',
    );
  }

  /// Fires when a notification is click.
  Future<Map<String, dynamic>?> getClickedNotification() {
    throw UnimplementedError(
      'getClickedNotification() is not implemented',
    );
  }

  /// Fires when a notification is click on app opened.
  Stream<Map<String, dynamic>> get clickedNotificationListener {
    throw UnimplementedError(
      'clickedNotificationListener is not implemented',
    );
  }

  /// Fires when a new notification received.
  Stream<Map<String, dynamic>> get notificationReceivedListener {
    throw UnimplementedError(
      'notificationReceivedListener is not implemented',
    );
  }

  /// Check whether permission is avaliable in device to receive push notification.
  Future<bool> getNotificationPermission(
    IOSPermission? iosPermission,
  ) {
    throw UnimplementedError(
      'getNotificationPermission() is not implemented',
    );
  }

  /// Check whether permission is avaliable in device to receive push notification.
  Future<void> removeNotification({
    String? tag,
    int? id,
  }) {
    throw UnimplementedError(
      'removeNotification() is not implemented',
    );
  }

  /// Check whether permission is avaliable in device to receive push notification.
  Future<void> showNotification(Map<String, dynamic> notification) {
    throw UnimplementedError(
      'showNotification() is not implemented',
    );
  }
}
