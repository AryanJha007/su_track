import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:su_track/services/geolocation/updateGeolocation.dart';
import 'package:su_track/util/constants.dart' as constants;
import 'package:su_track/services/auth/loggedIn.dart';

class Backgroundservice {


  Future<bool> getPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission is required')),
      );
      return false;
    }
    return true;
  }

  Future<bool> handlePermission() async {
    while (true) {
      PermissionStatus locationPermission = await Permission.location.request();
      if (locationPermission == PermissionStatus.granted) {
        if (Platform.isAndroid) {
          PermissionStatus backgroundPermission = await Permission.locationAlways.request();
          if (backgroundPermission == PermissionStatus.granted) {
            return true;
          }
        } else {
          return true;
        }
      }
      await Future.delayed(Duration(seconds: 1));
    }
  }

  Future<void> getCurrentLocationNowCustom() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
      );
      updateGeolocation(
        position.latitude.toString(),
        position.longitude.toString(),
      );
    } catch (e) {
    }
  }
}


class LocationServiceManager {
  static StreamSubscription<Position>? _positionStream;

  static Future<void> startLocationService() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundServiceStart,
        isForegroundMode: true,
        autoStart: true,
        notificationChannelId: 'location_service',
        initialNotificationTitle: 'Location Service',
        initialNotificationContent: 'Tracking location in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onBackgroundServiceStart,
        onBackground: onBackgroundServiceStart,
        autoStart: true,
      ),
    );
    await service.startService();
  }

  static Future<void> stopLocationService() async {
    await _positionStream?.cancel();
    _positionStream = null;

    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }

  static bool isRunning() {
    return _positionStream != null;
  }
}

@pragma('vm:entry-point')
Future<bool> onBackgroundServiceStart(ServiceInstance service) async {
  service.on("stopService").listen((event) {
    service.stopSelf();
  });

  Timer.periodic(Duration(seconds: 30), (timer) async {
    if (await LoggedIn.isPunchedIn() != true) {
      timer.cancel();
      service.stopSelf();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
      );
      await updateGeolocation(
        position.latitude.toString(),
        position.longitude.toString(),
      );
    } catch (e) {
      print('Error getting background location: $e');
    }
  });

  return true;
}

