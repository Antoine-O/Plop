import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/notification_service.dart';
import 'package:plop/core/services/user_service.dart';

import 'notification_service_test.mocks.dart';

@GenerateMocks([
  DatabaseService,
  UserService,
  FlutterLocalNotificationsPlugin,
  AudioPlayer,
  AndroidFlutterLocalNotificationsPlugin
])
void main() {
  group('NotificationService', () {
    late NotificationService notificationService;
    late MockDatabaseService mockDatabaseService;

    late MockFlutterLocalNotificationsPlugin mockLocalNotifications;

    late MockAndroidFlutterLocalNotificationsPlugin
        mockAndroidFlutterLocalNotificationsPlugin;

    setUp(() {
      mockDatabaseService = MockDatabaseService();

      mockLocalNotifications = MockFlutterLocalNotificationsPlugin();

      mockAndroidFlutterLocalNotificationsPlugin =
          MockAndroidFlutterLocalNotificationsPlugin();

      notificationService = NotificationService.test(
        mockDatabaseService,
        mockLocalNotifications,
      );
    });

    test('init initializes local notifications', () async {
      when(mockLocalNotifications.initialize(any,
              onDidReceiveNotificationResponse:
                  anyNamed('onDidReceiveNotificationResponse')))
          .thenAnswer((_) async => true);
      when(mockLocalNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>())
          .thenReturn(mockAndroidFlutterLocalNotificationsPlugin);

      await notificationService.init();

      verify(mockLocalNotifications.initialize(any,
              onDidReceiveNotificationResponse:
                  anyNamed('onDidReceiveNotificationResponse')))
          .called(1);
    });
  });
}
