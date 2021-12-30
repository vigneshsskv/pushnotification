import 'package:pushnotification/PushNotificationMananger.dart';

class Pushnotification {
  static final PushNotificationManager _mediator =
      PushNotificationManager.instance;

  /// Fires when a new token is generated.
  static Stream<String> get deviceTokenChangeListener =>
      _mediator.deviceTokenChangeListener;

  /// Returns the default token for this device and optionally [senderId].
  static Future<String> getDeviceToken() => _mediator.getDeviceToken();

  /// Removes access to an token previously authorized with optional [senderId].
  ///
  /// Messages sent by the server to this token will fail.
  static Future<void> unregisterDevice() => _mediator.unregisterDevice();

  /// Fires when a notification is click.
  static Future<Map<String, dynamic>?> notificationClicked() =>
      _mediator.notificationClicked();

  /// Fires when a notification is click when app is on foreground.
  static Stream<Map<String, dynamic>> get notificationClickedListener =>
      _mediator.notificationClickedListener;

  /// Fires when a new notification received.
  static Stream<Map<String, dynamic>> get notificationReceivedListener =>
      _mediator.notificationReceivedListener;

  /// Check whether permission is avaliable in device to receive push notification.
  static Future<void> getNotificationPermission() =>
      _mediator.getNotificationPermission();

  /// Check whether permission is avaliable in device to receive push notification.
  static Future<void> removeNotification({
    String? tag,
    int? id,
  }) =>
      _mediator.removeNotification(
        id: id,
        tag: tag,
      );

  /// Check whether permission is avaliable in device to receive push notification.
  static Future<void> showNotification(
    Map<String, dynamic> notification,
  ) =>
      _mediator.showNotification(
        notification,
      );
}
