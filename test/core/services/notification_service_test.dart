import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/notification_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

import 'notification_service_test.mocks.dart';

@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  DatabaseService,
  UserService,
  AudioPlayer
])
void main() {
  group('NotificationService', () {
    late NotificationService notificationService;
    late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
    late MockDatabaseService mockDatabaseService;
    late MockUserService mockUserService;
    late MockAudioPlayer mockAudioPlayer;

    setUp(() {
      mockLocalNotifications = MockFlutterLocalNotificationsPlugin();
      mockDatabaseService = MockDatabaseService();
      mockUserService = MockUserService();
      mockAudioPlayer = MockAudioPlayer();
      notificationService = NotificationService(
         ,
        mockUserService,
        mockLocalNotifications,
        mockAudioPlayer,
      );
    });

    test('init initializes local notifications', () async {
      // Stub the initialize method to avoid null pointer exceptions
      when(mockLocalNotifications.initialize(any, onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse')))
          .thenAnswer((_) async => true);

      await notificationService.init();

      verify(mockLocalNotifications.initialize(any,
              onDidReceiveNotificationResponse:
                  anyNamed('onDidReceiveNotificationResponse')))
          .called(1);
    });

    test('showNotification displays a notification', () async {
      // Stub the show method
      when(mockLocalNotifications.show(any, any, any, any, payload: anyNamed('payload')))
          .thenAnswer((_) async => {});

      await notificationService.showNotification(
          title: 'Test', body: 'Test Body');
          
      verify(mockLocalNotifications.show(any, 'Test', 'Test Body', any,
              payload: anyNamed('payload')))
          .called(1);
    });

    test('handlePlop updates contact and shows notification', () async {
      final contact = Contact(
          userId: '123', originalPseudo: 'Test', alias: 'Test', colorValue: 1);
      when(mockDatabaseService.getContact('123')).thenAnswer((_) async => contact);
      when(mockUserService.isGlobalMute).thenReturn(false);
      when(mockLocalNotifications.show(any, any, any, any, payload: anyNamed('payload')))
          .thenAnswer((_) async => {});

      await notificationService.handlePlop(
          fromUserId: '123', messageText: 'Plop!');

      verify(mockDatabaseService.updateContact(any)).called(1);
      verify(mockLocalNotifications.show(any, 'Test', 'Plop!', any,
              payload: anyNamed('payload')))
          .called(1);
    });

    test('handlePlop does not show notification if contact is blocked',
        () async {
      final contact = Contact(
          userId: '123',
          originalPseudo: 'Test',
          alias: 'Test',
          colorValue: 1,
          isBlocked: true);
      when(mockDatabaseService.getContact('123')).thenAnswer((_) async => contact);

      await notificationService.handlePlop(
          fromUserId: '123', messageText: 'Plop!');

      verifyNever(mockLocalNotifications.show(any, any, any, any,
          payload: anyNamed('payload')));
    });

    test('handlePlop uses default message override', () async {
      final contact = Contact(
          userId: '123',
          originalPseudo: 'Test',
          alias: 'Test',
          colorValue: 1,
          defaultMessageOverride: 'Override');
      when(mockDatabaseService.getContact('123')).thenAnswer((_) async => contact);
      when(mockUserService.isGlobalMute).thenReturn(false);
      when(mockLocalNotifications.show(any, any, any, any, payload: anyNamed('payload')))
          .thenAnswer((_) async => {});

      await notificationService.handlePlop(
          fromUserId: '123', isDefaultMessage: true);

      verify(mockLocalNotifications.show(any, 'Test', 'Override', any,
              payload: anyNamed('payload')))
          .called(1);
    });
  });
}
