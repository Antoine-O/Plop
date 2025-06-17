import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Plop'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @manageContacts.
  ///
  /// In en, this message translates to:
  /// **'Manage Contacts'**
  String get manageContacts;

  /// No description provided for @noContactsYet.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet.\nGo to \"Manage Contacts\" to add one.'**
  String get noContactsYet;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Export / Import'**
  String get syncTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System Language'**
  String get systemLanguage;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @italian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get italian;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// No description provided for @myUsername.
  ///
  /// In en, this message translates to:
  /// **'My Username'**
  String get myUsername;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @myUserId.
  ///
  /// In en, this message translates to:
  /// **'My User ID (for debugging)'**
  String get myUserId;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// No description provided for @quickMessages.
  ///
  /// In en, this message translates to:
  /// **'Quick Messages'**
  String get quickMessages;

  /// No description provided for @addNewQuickMessage.
  ///
  /// In en, this message translates to:
  /// **'New quick message'**
  String get addNewQuickMessage;

  /// No description provided for @yourMessages.
  ///
  /// In en, this message translates to:
  /// **'Your messages ({count}/10)'**
  String yourMessages(Object count);

  /// No description provided for @noMessagesConfigured.
  ///
  /// In en, this message translates to:
  /// **'No messages configured.'**
  String get noMessagesConfigured;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @resetApp.
  ///
  /// In en, this message translates to:
  /// **'Reset Application'**
  String get resetApp;

  /// No description provided for @inviteContact.
  ///
  /// In en, this message translates to:
  /// **'Invite a contact'**
  String get inviteContact;

  /// No description provided for @addByCode.
  ///
  /// In en, this message translates to:
  /// **'Add via code'**
  String get addByCode;

  /// No description provided for @manageContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Contacts'**
  String get manageContactsTitle;

  /// No description provided for @reorderListHint.
  ///
  /// In en, this message translates to:
  /// **'Long press to reorder the list.'**
  String get reorderListHint;

  /// No description provided for @noContactsToManage.
  ///
  /// In en, this message translates to:
  /// **'No contacts to manage.'**
  String get noContactsToManage;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettings;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @advancedSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettingsTitle;

  /// No description provided for @contactNameAlias.
  ///
  /// In en, this message translates to:
  /// **'Contact Name (alias)'**
  String get contactNameAlias;

  /// No description provided for @ignoreNotifications.
  ///
  /// In en, this message translates to:
  /// **'Ignore notifications'**
  String get ignoreNotifications;

  /// No description provided for @muteThisContact.
  ///
  /// In en, this message translates to:
  /// **'Mute this contact.'**
  String get muteThisContact;

  /// No description provided for @blockThisContact.
  ///
  /// In en, this message translates to:
  /// **'Block this contact'**
  String get blockThisContact;

  /// No description provided for @hideThisContact.
  ///
  /// In en, this message translates to:
  /// **'Hide this contact'**
  String get hideThisContact;

  /// No description provided for @doNotSeeInList.
  ///
  /// In en, this message translates to:
  /// **'Do not see this contact in the main list.'**
  String get doNotSeeInList;

  /// No description provided for @notificationSound.
  ///
  /// In en, this message translates to:
  /// **'Notification Sound'**
  String get notificationSound;

  /// No description provided for @defaultSound.
  ///
  /// In en, this message translates to:
  /// **'Default sound'**
  String get defaultSound;

  /// No description provided for @overrideDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Override \"Plop\" message'**
  String get overrideDefaultMessage;

  /// No description provided for @exampleNewPlop.
  ///
  /// In en, this message translates to:
  /// **'E.g., \"New Plop!\"'**
  String get exampleNewPlop;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved!'**
  String get settingsSaved;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @deleteContactConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent.'**
  String get deleteContactConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @invitationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Invitation Code'**
  String get invitationDialogTitle;

  /// No description provided for @invitationDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Share this code with a friend. It is valid for {minutes} minutes.'**
  String invitationDialogBody(Object minutes);

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'COPY'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'SHARE'**
  String get share;

  /// No description provided for @importAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Import an existing account'**
  String get importAccountTitle;

  /// No description provided for @importAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the sync code obtained from your old device to retrieve your account and contacts.'**
  String get importAccountBody;

  /// No description provided for @syncCode.
  ///
  /// In en, this message translates to:
  /// **'Synchronization Code'**
  String get syncCode;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @exportAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Export this account'**
  String get exportAccountTitle;

  /// No description provided for @exportAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Generate a unique and temporary code on this device (your \"old\" device). This code is valid for 5 minutes.'**
  String get exportAccountBody;

  /// No description provided for @generateExportCode.
  ///
  /// In en, this message translates to:
  /// **'Generate an export code'**
  String get generateExportCode;

  /// No description provided for @importAccountTitle2.
  ///
  /// In en, this message translates to:
  /// **'2. Import on a new device'**
  String get importAccountTitle2;

  /// No description provided for @importAccountBody2.
  ///
  /// In en, this message translates to:
  /// **'On your NEW device, go to this same menu and enter the code obtained. This will replace the account on the new device with this one.'**
  String get importAccountBody2;

  /// No description provided for @confirmImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Import'**
  String get confirmImportTitle;

  /// No description provided for @confirmImportBody.
  ///
  /// In en, this message translates to:
  /// **'This action will replace your current account and all its data. Are you sure you want to continue?'**
  String get confirmImportBody;

  /// No description provided for @iConfirm.
  ///
  /// In en, this message translates to:
  /// **'IMPORT'**
  String get iConfirm;

  /// No description provided for @pleaseEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a code.'**
  String get pleaseEnterCode;

  /// No description provided for @invalidOrExpiredCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code.'**
  String get invalidOrExpiredCode;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add a contact'**
  String get addContact;

  /// No description provided for @invitationCode.
  ///
  /// In en, this message translates to:
  /// **'Invitation Code*'**
  String get invitationCode;

  /// No description provided for @contactNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Contact name (optional)'**
  String get contactNameOptional;

  /// No description provided for @chooseAColor.
  ///
  /// In en, this message translates to:
  /// **'Choose a color'**
  String get chooseAColor;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @messageSentTo.
  ///
  /// In en, this message translates to:
  /// **'Message sent to {contactName}!'**
  String messageSentTo(Object contactName);

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get codeCopied;

  /// No description provided for @startByAddingContact.
  ///
  /// In en, this message translates to:
  /// **'Start by adding a contact'**
  String get startByAddingContact;

  /// No description provided for @inviteOrEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Invite a friend or enter their code to start plopping.'**
  String get inviteOrEnterCode;

  /// No description provided for @shareMyCode.
  ///
  /// In en, this message translates to:
  /// **'Share my code'**
  String get shareMyCode;

  /// No description provided for @enterInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter an invitation code'**
  String get enterInvitationCode;

  /// No description provided for @saveUsername.
  ///
  /// In en, this message translates to:
  /// **'Save username'**
  String get saveUsername;

  /// No description provided for @userIdCopied.
  ///
  /// In en, this message translates to:
  /// **'User ID copied!'**
  String get userIdCopied;

  /// No description provided for @maxTenMessages.
  ///
  /// In en, this message translates to:
  /// **'You cannot have more than 10 messages.'**
  String get maxTenMessages;

  /// No description provided for @deleteThisContact.
  ///
  /// In en, this message translates to:
  /// **'Delete this contact?'**
  String get deleteThisContact;

  /// No description provided for @actionIsPermanent.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent.'**
  String get actionIsPermanent;

  /// No description provided for @resetAppQuestion.
  ///
  /// In en, this message translates to:
  /// **'Reset application?'**
  String get resetAppQuestion;

  /// No description provided for @resetWarning.
  ///
  /// In en, this message translates to:
  /// **'All your data (account, contacts) will be permanently deleted. This action is irreversible.'**
  String get resetWarning;

  /// No description provided for @importWarning.
  ///
  /// In en, this message translates to:
  /// **'This action will replace your current account and all its data.'**
  String get importWarning;

  /// No description provided for @syncYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Sync your account'**
  String get syncYourAccount;

  /// No description provided for @enterSyncCodeToRetrieve.
  ///
  /// In en, this message translates to:
  /// **'Enter the sync code from your old device to retrieve your account and contacts.'**
  String get enterSyncCodeToRetrieve;

  /// No description provided for @pleaseEnterSyncCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a sync code.'**
  String get pleaseEnterSyncCode;

  /// No description provided for @userImported.
  ///
  /// In en, this message translates to:
  /// **'User imported'**
  String get userImported;

  /// No description provided for @welcomeToPlop.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Plop'**
  String get welcomeToPlop;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'The ultra-simple, ephemeral, and privacy-respecting messenger.'**
  String get appTagline;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works?'**
  String get howItWorks;

  /// No description provided for @featureNoSignup.
  ///
  /// In en, this message translates to:
  /// **'No registration, just a username.'**
  String get featureNoSignup;

  /// No description provided for @featureTempCodes.
  ///
  /// In en, this message translates to:
  /// **'Add contacts with unique, temporary codes.'**
  String get featureTempCodes;

  /// No description provided for @featureQuickMessages.
  ///
  /// In en, this message translates to:
  /// **'Send \'Plops\' or quick messages.'**
  String get featureQuickMessages;

  /// No description provided for @featurePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Nothing is stored on our servers.'**
  String get featurePrivacy;

  /// No description provided for @useCases.
  ///
  /// In en, this message translates to:
  /// **'Some use cases'**
  String get useCases;

  /// No description provided for @useCaseArrival.
  ///
  /// In en, this message translates to:
  /// **'Let a loved one know you\'ve arrived safely.'**
  String get useCaseArrival;

  /// No description provided for @useCaseGaming.
  ///
  /// In en, this message translates to:
  /// **'Signal your team that the online game is starting.'**
  String get useCaseGaming;

  /// No description provided for @useCaseSimpleHello.
  ///
  /// In en, this message translates to:
  /// **'A simple \'hello\' without expecting a reply.'**
  String get useCaseSimpleHello;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get letsGo;

  /// No description provided for @chooseYourUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose your username'**
  String get chooseYourUsername;

  /// No description provided for @createMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Create my account'**
  String get createMyAccount;

  /// No description provided for @importExistingAccount.
  ///
  /// In en, this message translates to:
  /// **'Import an existing account'**
  String get importExistingAccount;

  /// No description provided for @supportDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Support development ❤️'**
  String get supportDevelopment;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @serverConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Error: Could not contact the server {server}. Please try again.'**
  String serverConnectionError(Object server);

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated!'**
  String get languageUpdated;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
