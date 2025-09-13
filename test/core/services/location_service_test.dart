
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/services/location_service.dart';

class MockGeolocator extends Mock implements GeolocatorPlatform {}

void main() {
  group('LocationService', () {
    late LocationService locationService;
    late MockGeolocator mockGeolocator;

    setUp(() {
      locationService = LocationService();
      mockGeolocator = MockGeolocator();
      GeolocatorPlatform.instance = mockGeolocator;
    });

    group('checkAndRequestLocationPermission', () {
      test('should return granted when permission is already granted', () async {
        when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.whileInUse);

        final result = await locationService.checkAndRequestLocationPermission();

        expect(result, LocationPermissionStatus.granted);
      });

      test('should request permission when permission is denied and return granted if granted', () async {
        when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.denied);
        when(mockGeolocator.requestPermission()).thenAnswer((_) async => LocationPermission.whileInUse);

        final result = await locationService.checkAndRequestLocationPermission();

        expect(result, LocationPermissionStatus.granted);
      });

      test('should return denied when permission is denied and user denies again', () async {
        when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.denied);
        when(mockGeolocator.requestPermission()).thenAnswer((_) async => LocationPermission.denied);

        final result = await locationService.checkAndRequestLocationPermission();

        expect(result, LocationPermissionStatus.denied);
      });

      test('should return deniedForever when permission is denied forever', () async {
        when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.deniedForever);

        final result = await locationService.checkAndRequestLocationPermission();

        expect(result, LocationPermissionStatus.deniedForever);
      });
    });

    group('getCurrentPositionWithPermissionCheck', () {
      test('should return position when permission is granted and service is enabled', () async {
        final position = Position(latitude: 1.0, longitude: 2.0, timestamp: DateTime.now(), accuracy: 1.0, altitude: 1.0, heading: 1.0, speed: 1.0, speedAccuracy: 1.0, altitudeAccuracy: 1.0, headingAccuracy: 1.0);
        when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.whileInUse);
        when(mockGeolocator.isLocationServiceEnabled()).thenAnswer((_) async => true);
        when(mockGeolocator.getCurrentPosition(
          locationSettings: anyNamed('locationSettings'),
        )).thenAnswer((_) async => position);

        final result = await locationService.getCurrentPositionWithPermissionCheck();

        expect(result, position);
      });

      test('should return null when permission is not granted', () async {
        when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.denied);
        when(mockGeolocator.requestPermission()).thenAnswer((_) async => LocationPermission.denied);

        final result = await locationService.getCurrentPositionWithPermissionCheck();

        expect(result, isNull);
      });

      test('should return null when location services are disabled', () async {
        when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.whileInUse);
        when(mockGeolocator.isLocationServiceEnabled()).thenAnswer((_) async => false);

        final result = await locationService.getCurrentPositionWithPermissionCheck();

        expect(result, isNull);
      });

      test('should return null on error fetching position', () async {
        when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.whileInUse);
        when(mockGeolocator.isLocationServiceEnabled()).thenAnswer((_) async => true);
        when(mockGeolocator.getCurrentPosition(
          locationSettings: anyNamed('locationSettings'),
        )).thenThrow(Exception('Error'));

        final result = await locationService.getCurrentPositionWithPermissionCheck();

        expect(result, isNull);
      });
    });
  });
}
