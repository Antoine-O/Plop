// In contact_tile.dart (or a dedicated location_service.dart)

import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart'; // For context if showing dialogs

class LocationService { // Example of extracting to a service
  Future<LocationPermissionStatus> checkAndRequestLocationPermission({BuildContext? context}) async {
    debugPrint('[LocationService] checkAndRequestLocationPermission - Checking location permission.');
    LocationPermission permission;

    // Check current permission status
    permission = await Geolocator.checkPermission();
    debugPrint('[LocationService] checkAndRequestLocationPermission - Current permission status: $permission');

    if (permission == LocationPermission.denied) {
      debugPrint('[LocationService] checkAndRequestLocationPermission - Permission denied, requesting...');
      permission = await Geolocator.requestPermission();
      debugPrint('[LocationService] checkAndRequestLocationPermission - Permission after request: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('[LocationService] checkAndRequestLocationPermission - Permission DENIED by user after request.');
        // Optionally, show a dialog explaining why you need the permission if they deny it
        if (context != null && context.mounted) { // Ensure context is valid
          // _showPermissionDeniedDialog(context, "Location permission is needed to share your position with messages.");
        }
        return LocationPermissionStatus.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[LocationService] checkAndRequestLocationPermission - Permission DENIED FOREVER.');
      // Optionally, show a dialog guiding them to app settings
      if (context != null && context.mounted) {
        // _showPermissionDeniedForeverDialog(context, "Location permission was permanently denied. Please enable it in app settings to share your position.");
      }
      return LocationPermissionStatus.deniedForever;
    }

    // If we reach here, permission is whileInUse or always (granted)
    debugPrint('[LocationService] checkAndRequestLocationPermission - Permission granted: $permission');
    return LocationPermissionStatus.granted; // Or map specific enums
  }


  Future<Position?>getCurrentPositionWithPermissionCheck({BuildContext? context}) async {
    debugPrint('[LocationService] getCurrentPositionWithPermissionCheck - Attempting to get current position.');

    // 1. Check/Request Permission
    final permissionStatus = await checkAndRequestLocationPermission(context: context);
    if (permissionStatus != LocationPermissionStatus.granted) {
      debugPrint('[LocationService] getCurrentPositionWithPermissionCheck - Permission not granted ($permissionStatus). Cannot fetch location.');
      return null; // Or throw an exception
    }

    // 2. Check if Location Services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[LocationService] getCurrentPositionWithPermissionCheck - Location services are disabled.');
      if (context != null && context.mounted) {
        // Optionally, prompt user to enable location services or guide them
        // For example, show a dialog with a button to Geolocator.openLocationSettings();
        // await _showLocationServicesDisabledDialog(context);
      }
      // Consider throwing an error or returning a specific result
      // For now, returning null if service is disabled after permission is granted
      return null;
    }


    // 3. Fetch Position
    debugPrint('[LocationService] getCurrentPositionWithPermissionCheck - Permissions granted and service enabled. Fetching position...');
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      debugPrint('[LocationService] getCurrentPositionWithPermissionCheck - Fetched position: Lat: ${position.latitude}, Lon: ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('[LocationService] getCurrentPositionWithPermissionCheck - Error fetching position: $e');
      return null;
    }
  }

// You can add helper methods to show dialogs if you want:
// void _showPermissionDeniedDialog(BuildContext context, String message) { ... }
// void _showPermissionDeniedForeverDialog(BuildContext context, String message) { ... }
// Future<void> _showLocationServicesDisabledDialog(BuildContext context) async { ... }
}

// Enum to make status clearer if not using Geolocator.LocationPermission directly
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled, // Could add this for more clarity
  unknown, // Could add this for more clarity
}