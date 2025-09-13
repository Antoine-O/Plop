import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unknown,
}

class LocationService {
  Future<LocationPermissionStatus> checkAndRequestLocationPermission(
      {BuildContext? context}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Location services are disabled. Please enable them in your device settings.")));
        await Geolocator.openLocationSettings();
      }
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionStatus.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.deniedForever;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return LocationPermissionStatus.granted;
    }

    return LocationPermissionStatus.unknown;
  }

  Future<Position?> getCurrentPositionWithPermissionCheck(
      {BuildContext? context}) async {
    final permissionStatus =
        await checkAndRequestLocationPermission(context: context);
    if (permissionStatus == LocationPermissionStatus.granted) {
      try {
        return await Geolocator.getCurrentPosition();
      } catch (e) {
        debugPrint(
            "[LocationService] Error getting current position after permission grant: $e");
        return null;
      }
    } else {
      debugPrint(
          "[LocationService] Not getting position due to permission status: $permissionStatus");
      return null;
    }
  }
}
