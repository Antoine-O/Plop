import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/services/location_service.dart';

class MockGeolocatorPlatform extends Mock implements GeolocatorPlatform {}

void main() {
  group('LocationService', () {
    late LocationService locationService;
    late MockGeolocatorPlatform mockGeolocatorPlatform;

    setUp(() {
      locationService = LocationService();
      mockGeolocatorPlatform = MockGeolocatorPlatform();
      GeolocatorPlatform.instance = mockGeolocatorPlatform;
    });

    test(
        'checkAndRequestLocationPermission returns granted when permission is granted',
        () async {
      when(mockGeolocatorPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      final result = await locationService.checkAndRequestLocationPermission();
      expect(result, LocationPermissionStatus.granted);
    });

    test('checkAndRequestLocationPermission requests permission when denied',
        () async {
      when(mockGeolocatorPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(mockGeolocatorPlatform.requestPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      final result = await locationService.checkAndRequestLocationPermission();
      expect(result, LocationPermissionStatus.granted);
      verify(mockGeolocatorPlatform.requestPermission()).called(1);
    });

    test(
        'getCurrentPositionWithPermissionCheck returns position when permission is granted',
        () async {
      final position = Position(
          latitude: 1,
          longitude: 1,
          timestamp: DateTime.now(),
          accuracy: 1,
          altitude: 1,
          heading: 1,
          speed: 1,
          speedAccuracy: 1,
          altitudeAccuracy: 1.0,
          headingAccuracy: 1.0);
      when(mockGeolocatorPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(mockGeolocatorPlatform.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockGeolocatorPlatform.getCurrentPosition(
              locationSettings: anyNamed('locationSettings')))
          .thenAnswer((_) async => position);
      final result =
          await locationService.getCurrentPositionWithPermissionCheck();
      expect(result, equals(position));
    });
  });
}
