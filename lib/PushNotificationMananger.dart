import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'PushNotificationInterface.dart';

enum ChannelValue {
  deviceTokenListener,
  getDeviceToken,
  unregister,
  clickedNotificationListener,
  notificationReceiverListener,
  requestPermission,
  showNotification,
  removeNotification,
}

extension MethodName on ChannelValue {
  String get name => [
        'deviceTokenListener',
        'getDeviceToken',
        'unregister',
        'clickedNotificationListener',
        'notificationReceiverListener',
        'requestPermission',
        'showNotification',
        'removeNotification',
      ][index];
}

class IOSPermission {
  final bool

      /// To register the device when we request permission
      ///
      ///ios only.
      registerOnRequest,

      /// Request permission to display alerts. Defaults to `true`.
      ///
      /// iOS only.
      alert,

      /// Request permission for Siri to automatically read out notification messages over AirPods.
      /// Defaults to `false`.
      ///
      /// iOS only.
      announcement,

      /// Request permission to update the application badge. Defaults to `true`.
      ///
      /// iOS only.
      badge,

      /// Request permission to display notifications in a CarPlay environment.
      /// Defaults to `false`.
      ///
      /// iOS only.
      carPlay,

      /// Request permission for critical alerts. Defaults to `false`.
      ///
      /// Note; your application must explicitly state reasoning for enabling
      /// critical alerts during the App Store review process or your may be
      /// rejected.
      ///
      /// iOS only.
      criticalAlert,

      /// Request permission to provisionally create non-interrupting notifications.
      /// Defaults to `false`.
      ///
      /// iOS only.
      provisional,

      /// Request permission to play sounds. Defaults to `true`.
      ///
      /// iOS only.
      sound;

  IOSPermission({
    this.registerOnRequest = true,
    this.alert = true,
    this.announcement = true,
    this.badge = true,
    this.carPlay = true,
    this.criticalAlert = true,
    this.provisional = true,
    this.sound = true,
  });

  toJson() => <String, bool>{
        'alert': alert,
        'announcement': announcement,
        'badge': badge,
        'carPlay': carPlay,
        'criticalAlert': criticalAlert,
        'provisional': provisional,
        'sound': sound,
      };
}

class PushNotificationManager extends PushNotificationInterface {
  late MethodChannel _channel;
  late StreamController<String> _deviceTokenStreamController;
  late StreamController<Map<String, dynamic>>
      _notificationReceivedStreamController;
  late StreamController<Map<String, dynamic>>
      _clickedNotificationStreamController;
  static PushNotificationManager? _instance;

  static PushNotificationManager get instance =>
      _instance ??= PushNotificationManager._();

  PushNotificationManager._() {
    WidgetsFlutterBinding.ensureInitialized(); //all widgets are rendered here
    _channel = const MethodChannel(
      'com.vignesh.pushnotification/messaging',
    );
    _deviceTokenStreamController = StreamController<String>.broadcast();
    _notificationReceivedStreamController =
        StreamController<Map<String, dynamic>>.broadcast();
    _clickedNotificationStreamController =
        StreamController<Map<String, dynamic>>.broadcast();
    _channel.setMethodCallHandler((call) async {
      if (call.method == ChannelValue.deviceTokenListener.name) {
        _deviceTokenStreamController.add(call.arguments as String);
      } else if (call.method ==
          ChannelValue.notificationReceiverListener.name) {
        _notificationReceivedStreamController.add(
          Map<String, dynamic>.from(call.arguments),
        );
      } else if (call.method == ChannelValue.clickedNotificationListener.name) {
        _clickedNotificationStreamController.add(
          Map<String, dynamic>.from(call.arguments),
        );
      }
    });
  }

  @override
  Stream<String> get deviceTokenChangeListener =>
      _deviceTokenStreamController.stream;

  @override
  Future<String> getDeviceToken() async {
    try {
      var data = await _channel.invokeMapMethod<String, String>(
        ChannelValue.getDeviceToken.name,
      );
      return data?['token'] ?? '';
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> unregisterDevice() async {
    try {
      await _channel.invokeMapMethod(
        ChannelValue.unregister.name,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getClickedNotification() async {
    try {
      var response = await _channel.invokeMapMethod(
        ChannelValue.clickedNotificationListener.name,
      );
      if (response == null) return null;
      return Map<String, dynamic>.from(
        response,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<Map<String, dynamic>> get clickedNotificationListener =>
      _clickedNotificationStreamController.stream;

  @override
  Stream<Map<String, dynamic>> get notificationReceivedListener =>
      _notificationReceivedStreamController.stream;

  @override
  Future<bool> getNotificationPermission(
    IOSPermission? iosPermission,
  ) async {
    try {
      return await _channel.invokeMethod(
        ChannelValue.requestPermission.name,
        (iosPermission ?? IOSPermission()).toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> removeNotification({
    String? tag,
    int? id,
  }) async {
    try {
      await _channel.invokeMapMethod<String, String>(
        ChannelValue.removeNotification.name,
        {
          'tag': tag,
          'id': id,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> showNotification(
    Map<String, dynamic> notification,
  ) async {
    try {
      await _channel.invokeMapMethod<String, String>(
        ChannelValue.showNotification.name,
        notification,
      );
    } catch (e) {
      rethrow;
    }
  }
}
