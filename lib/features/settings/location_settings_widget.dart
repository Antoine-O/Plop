import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plop/core/services/location_service.dart';

class LocationSettingsWidget extends StatefulWidget {
  const LocationSettingsWidget({super.key});

  @override
  State<LocationSettingsWidget> createState() => _LocationSettingsWidgetState();
}

class _LocationSettingsWidgetState extends State<LocationSettingsWidget> {
  final LocationService _locationService = LocationService();
  LocationPermissionStatus _uiPermissionStatus = LocationPermissionStatus.unknown;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermission();
  }

  Future<void> _checkInitialPermission() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    // Silently check, don't request yet if just checking initial state
    final currentGeolocatorPerm = await Geolocator.checkPermission();
    if (!mounted) return;

    setState(() {
      if (currentGeolocatorPerm == LocationPermission.whileInUse ||
          currentGeolocatorPerm == LocationPermission.always) {
        _uiPermissionStatus = LocationPermissionStatus.granted;
      } else if (currentGeolocatorPerm == LocationPermission.deniedForever) {
        _uiPermissionStatus = LocationPermissionStatus.deniedForever;
      } else if (currentGeolocatorPerm == LocationPermission.denied) {
        _uiPermissionStatus = LocationPermissionStatus.denied;
      } else {
        _uiPermissionStatus = LocationPermissionStatus.unknown; // Should ideally not happen if denied maps
      }
      _isLoading = false;
    });
    debugPrint(
        "[LocationSettingsWidget] Initial permission status: $_uiPermissionStatus (from Geolocator: $currentGeolocatorPerm)");
  }

  Future<void> _requestPermissionFlow() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    // Handle deniedForever case first by guiding to settings
    if (_uiPermissionStatus == LocationPermissionStatus.deniedForever) {
      debugPrint("[LocationSettingsWidget] Permission denied forever, opening app settings.");
      await Geolocator.openAppSettings();
      // After returning from settings, re-check the permission
      // Small delay to allow settings to apply if user changed them quickly
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) { // Re-check mounted after async gap
        await _checkInitialPermission(); // Re-fetch the status
      }
      return; // Exit here as we've guided to settings
    }

    // Otherwise, request permission using the service
    // The service handles the actual Geolocator.requestPermission()
    final statusMapping = await _locationService.checkAndRequestLocationPermission(context: context);
    if (!mounted) return;

    LocationPermissionStatus newUiStatus;
    String message = "";

    switch (statusMapping) {
      case LocationPermissionStatus.granted:
        newUiStatus = LocationPermissionStatus.granted;
        message = "Location permission granted!";
        break;
      case LocationPermissionStatus.deniedForever:
        newUiStatus = LocationPermissionStatus.deniedForever;
        message = "Location permission permanently denied. Please enable in app settings.";
        // Offer to open settings again if they somehow got here without the above check
        // Geolocator.openAppSettings();
        break;
      case LocationPermissionStatus.denied:
      default: // Also catches serviceDisabled if you had that in your enum
        newUiStatus = LocationPermissionStatus.denied;
        message = "Location permission denied.";
        break;
    }

    setState(() {
      _uiPermissionStatus = newUiStatus;
      _isLoading = false;
    });

    if (message.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String statusText;
    String buttonText;
    VoidCallback? buttonAction = _requestPermissionFlow;

    switch (_uiPermissionStatus) {
      case LocationPermissionStatus.granted:
        statusText = "Granted";
        buttonText = "Permission Granted";
        buttonAction = null; // Disable button if already granted
        break;
      case LocationPermissionStatus.deniedForever:
        statusText = "Permanently Denied";
        buttonText = "Open App Settings";
        // Action is still _requestPermissionFlow, which handles deniedForever by opening settings
        break;
      case LocationPermissionStatus.denied:
        statusText = "Denied";
        buttonText = "Request Permission";
        break;
      case LocationPermissionStatus.unknown:
      default:
        statusText = "Checking...";
        buttonText = "Check Permission";
        break;
    }

    return ListTile(
      title: const Text("Location Data Sharing"),
      subtitle: Text(
          _isLoading ? "Loading..." : "Status: $statusText"),
      trailing: ElevatedButton(
        onPressed: _isLoading ? null : buttonAction,
        child: Text(buttonText),
      ),
      onTap: _isLoading ? null : () {
        // Allow tapping the whole tile to also trigger the action,
        // especially useful for "Open App Settings".
        if (buttonAction != null) {
          buttonAction();
        } else if (_uiPermissionStatus == LocationPermissionStatus.deniedForever) {
          // If button is disabled but status is deniedForever, still allow opening settings
          Geolocator.openAppSettings().then((_) async {
            await Future.delayed(const Duration(milliseconds: 500));
            if(mounted) await _checkInitialPermission();
          });
        }
      },
    );
  }
}
