import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'PushNotificationInterface.dart';

enum ChannelValue {
  deviceTokenListener,
  getDeviceToken,
  deleteDeviceToken,
  notificationClickedListener,
  notificationReceiverListener,
  requestPermission,
  showNotification,
  removeNotification,
}

extension MethodName on ChannelValue {
  String get name => [
        'deviceTokenListener',
        'getDeviceToken',
        'deleteDeviceToken',
        'notificationClickedListener',
        'notificationReceiverListener',
        'requestPermission',
        'showNotification',
        'removeNotification',
      ][index];
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
      } else if (call.method == ChannelValue.notificationClickedListener.name) {
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
        ChannelValue.getDeviceToken.name,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getClickedNotification() async {
    try {
      var data = await _channel.invokeMapMethod<String, String>(
        ChannelValue.notificationClickedListener.name,
      );
      return data;
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
  Future<void> getNotificationPermission() async {
    try {
      await _channel.invokeMapMethod<String, String>(
        ChannelValue.requestPermission.name,
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
