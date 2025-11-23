
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:plop/core/services/location_service.dart';

// A fake implementation of the GeolocatorPlatform that extends it.
// This is the correct way to test platform interfaces, avoiding `implements`.
class FakeGeolocatorPlatform extends GeolocatorPlatform {
  var _checkPermissionResult = LocationPermission.denied;
  var _requestPermissionResult = LocationPermission.denied;
  var _isLocationServiceEnabledResult = false;
  Position? _getCurrentPositionResult;
  Exception? _getCurrentPositionException;

  // Methods to programmatically set the results for each test case.
  void setCheckPermissionResult(LocationPermission result) {
    _checkPermissionResult = result;
  }

  void setRequestPermissionResult(LocationPermission result) {
    _requestPermissionResult = result;
  }

  void setIsLocationServiceEnabledResult(bool result) {
    _isLocationServiceEnabledResult = result;
  }

  void setGetCurrentPositionResult(Position result) {
    _getCurrentPositionResult = result;
    _getCurrentPositionException = null;
  }

  void setGetCurrentPositionException(Exception exception) {
    _getCurrentPositionException = exception;
    _getCurrentPositionResult = null;
  }

  // Overridden platform interface methods.
  @override
  Future<LocationPermission> checkPermission() async {
    return _checkPermissionResult;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    return _requestPermissionResult;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return _isLocationServiceEnabledResult;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (_getCurrentPositionException != null) {
      throw _getCurrentPositionException!;
    }
    return _getCurrentPositionResult!;
  }
}

void main() {
  group('LocationService', () {
    late LocationService locationService;
    late FakeGeolocatorPlatform fakeGeolocator;

    setUp(() {
      locationService = LocationService();
      fakeGeolocator = FakeGeolocatorPlatform();
      // Set the singleton instance to our fake implementation.
      GeolocatorPlatform.instance = fakeGeolocator;
    });

    group('checkAndRequestLocationPermission', () {
      test('should return granted when permission is already granted',
          () async {
        fakeGeolocator.setCheckPermissionResult(LocationPermission.whileInUse);
        fakeGeolocator.setIsLocationServiceEnabledResult(true);

        final result =
            await locationService.checkAndRequestLocationPermission();

        expect(result, LocationPermissionStatus.granted);
      });

      test(
          'should request permission when permission is denied and return granted if granted',
          () async {
        fakeGeolocator.setCheckPermissionResult(LocationPermission.denied);
        fakeGeolocator.setRequestPermissionResult(LocationPermission.whileInUse);
        fakeGeolocator.setIsLocationServiceEnabledResult(true);

        final result =
            await locationService.checkAndRequestLocationPermission();

        expect(result, LocationPermissionStatus.granted);
      });

      test(
          'should return denied when permission is denied and user denies again',
          () async {
        fakeGeolocator.setCheckPermissionResult(LocationPermission.denied);
        fakeGeolocator.setRequestPermissionResult(LocationPermission.denied);
        fakeGeolocator.setIsLocationServiceEnabledResult(true);

        final result =
            await locationService.checkAndRequestLocationPermission();

        expect(result, LocationPermissionStatus.denied);
      });

      test('should return deniedForever when permission is denied forever',
          () async {
        fakeGeolocator.setCheckPermissionResult(LocationPermission.deniedForever);
        fakeGeolocator.setIsLocationServiceEnabledResult(true);

        final result =
            await locationService.checkAndRequestLocationPermission();

        expect(result, LocationPermissionStatus.deniedForever);
      });
    });

    group('getCurrentPositionWithPermissionCheck', () {
      test(
          'should return position when permission is granted and service is enabled',
          () async {
        final position = Position(
            latitude: 1.0,
            longitude: 2.0,
            timestamp: DateTime.now(),
            accuracy: 1.0,
            altitude: 1.0,
            heading: 1.0,
            speed: 1.0,
            speedAccuracy: 1.0,
            altitudeAccuracy: 1.0,
            headingAccuracy: 1.0);
        
        fakeGeolocator.setCheckPermissionResult(LocationPermission.whileInUse);
        fakeGeolocator.setIsLocationServiceEnabledResult(true);
        fakeGeolocator.setGetCurrentPositionResult(position);

        final result =
            await locationService.getCurrentPositionWithPermissionCheck();

        expect(result, position);
      });

      test('should return null when permission is not granted', () async {
        fakeGeolocator.setCheckPermissionResult(LocationPermission.denied);
        fakeGeolocator.setRequestPermissionResult(LocationPermission.denied);
        fakeGeolocator.setIsLocationServiceEnabledResult(true);

        final result =
            await locationService.getCurrentPositionWithPermissionCheck();

        expect(result, isNull);
      });

      test('should return null when location services are disabled', () async {
        fakeGeolocator.setCheckPermissionResult(LocationPermission.whileInUse);
        fakeGeolocator.setIsLocationServiceEnabledResult(false);

        final result =
            await locationService.getCurrentPositionWithPermissionCheck();

        expect(result, isNull);
      });

      test('should return null on error fetching position', () async {
        fakeGeolocator.setCheckPermissionResult(LocationPermission.whileInUse);
        fakeGeolocator.setIsLocationServiceEnabledResult(true);
        fakeGeolocator.setGetCurrentPositionException(Exception('Error'));

        final result =
            await locationService.getCurrentPositionWithPermissionCheck();

        expect(result, isNull);
      });
    });
  });
}
