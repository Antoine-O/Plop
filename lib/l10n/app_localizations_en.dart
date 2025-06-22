// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Plop';

  @override
  String get settings => 'Settings';

  @override
  String get manageContacts => 'Manage Contacts';

  @override
  String get noContactsYet =>
      'No contacts yet.\nGo to \"Manage Contacts\" to add one.';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get syncTitle => 'Export / Import';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System Language';

  @override
  String get french => 'French';

  @override
  String get english => 'English';

  @override
  String get german => 'German';

  @override
  String get spanish => 'Spanish';

  @override
  String get italian => 'Italian';

  @override
  String get myAccount => 'My Account';

  @override
  String get myUsername => 'My Username';

  @override
  String get save => 'Save';

  @override
  String get myUserId => 'My User ID (for debugging)';

  @override
  String get copied => 'Copied!';

  @override
  String get quickMessages => 'Quick Messages';

  @override
  String get addNewQuickMessage => 'New quick message';

  @override
  String yourMessages(Object count) {
    return 'Your messages ($count/10)';
  }

  @override
  String get noMessagesConfigured => 'No messages configured.';

  @override
  String get delete => 'Delete';

  @override
  String get resetApp => 'Reset Application';

  @override
  String get inviteContact => 'Invite a contact';

  @override
  String get addByCode => 'Add via code';

  @override
  String get manageContactsTitle => 'Manage Contacts';

  @override
  String get reorderListHint => 'Long press to reorder the list.';

  @override
  String get noContactsToManage => 'No contacts to manage.';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get edit => 'Edit';

  @override
  String get advancedSettingsTitle => 'Advanced Settings';

  @override
  String get contactNameAlias => 'Contact Name (alias)';

  @override
  String get ignoreNotifications => 'Ignore notifications';

  @override
  String get muteThisContact => 'Mute this contact.';

  @override
  String get blockThisContact => 'Block this contact';

  @override
  String get hideThisContact => 'Hide this contact';

  @override
  String get doNotSeeInList => 'Do not see this contact in the main list.';

  @override
  String get notificationSound => 'Notification Sound';

  @override
  String get defaultSound => 'Default sound';

  @override
  String get overrideDefaultMessage => 'Override \"Plop\" message';

  @override
  String get exampleNewPlop => 'E.g., \"New Plop!\"';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get settingsSaved => 'Settings saved!';

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String get deleteContactConfirmation => 'This action is permanent.';

  @override
  String get cancel => 'CANCEL';

  @override
  String get invitationDialogTitle => 'Your Invitation Code';

  @override
  String invitationDialogBody(Object minutes) {
    return 'Share this code with a friend. It is valid for $minutes minutes.';
  }

  @override
  String get copy => 'COPY';

  @override
  String get share => 'SHARE';

  @override
  String get importAccountTitle => 'Import an existing account';

  @override
  String get importAccountBody =>
      'Enter the sync code obtained from your old device to retrieve your account and contacts.';

  @override
  String get syncCode => 'Synchronization Code';

  @override
  String get import => 'Import';

  @override
  String get exportAccountTitle => '1. Export this account';

  @override
  String get exportAccountBody =>
      'Generate a unique and temporary code on this device (your \"old\" device). This code is valid for 5 minutes.';

  @override
  String get generateExportCode => 'Generate an export code';

  @override
  String get importAccountTitle2 => '2. Import on a new device';

  @override
  String get importAccountBody2 =>
      'On your NEW device, go to this same menu and enter the code obtained. This will replace the account on the new device with this one.';

  @override
  String get confirmImportTitle => 'Confirm Import';

  @override
  String get confirmImportBody =>
      'This action will replace your current account and all its data. Are you sure you want to continue?';

  @override
  String get iConfirm => 'IMPORT';

  @override
  String get pleaseEnterCode => 'Please enter a code.';

  @override
  String get invalidOrExpiredCode => 'Invalid or expired code.';

  @override
  String get addContact => 'Add a contact';

  @override
  String get invitationCode => 'Invitation Code*';

  @override
  String get contactNameOptional => 'Contact name (optional)';

  @override
  String get chooseAColor => 'Choose a color';

  @override
  String get add => 'Add';

  @override
  String messageSentTo(Object contactName) {
    return 'Message sent to $contactName!';
  }

  @override
  String get unmute => 'Unmute';

  @override
  String get mute => 'Mute';

  @override
  String get codeCopied => 'Code copied!';

  @override
  String get startByAddingContact => 'Start by adding a contact';

  @override
  String get inviteOrEnterCode =>
      'Invite a friend or enter their code to start plopping.';

  @override
  String get shareMyCode => 'Share my code';

  @override
  String get enterInvitationCode => 'Enter an invitation code';

  @override
  String get saveUsername => 'Save username';

  @override
  String get userIdCopied => 'User ID copied!';

  @override
  String get maxTenMessages => 'You cannot have more than 10 messages.';

  @override
  String get deleteThisContact => 'Delete this contact?';

  @override
  String get actionIsPermanent => 'This action is permanent.';

  @override
  String get resetAppQuestion => 'Reset application?';

  @override
  String get resetWarning =>
      'All your data (account, contacts) will be permanently deleted. This action is irreversible.';

  @override
  String get importWarning =>
      'This action will replace your current account and all its data.';

  @override
  String get syncYourAccount => 'Sync your account';

  @override
  String get enterSyncCodeToRetrieve =>
      'Enter the sync code from your old device to retrieve your account and contacts.';

  @override
  String get pleaseEnterSyncCode => 'Please enter a sync code.';

  @override
  String get userImported => 'User imported';

  @override
  String get welcomeToPlop => 'Welcome to Plop';

  @override
  String get appTagline =>
      'The ultra-simple, ephemeral, and privacy-respecting messenger.';

  @override
  String get howItWorks => 'How it works?';

  @override
  String get featureNoSignup => 'No registration, just a username.';

  @override
  String get featureTempCodes => 'Add contacts with unique, temporary codes.';

  @override
  String get featureQuickMessages => 'Send \'Plops\' or quick messages.';

  @override
  String get featurePrivacy => 'Nothing is stored on our servers.';

  @override
  String get useCases => 'Some use cases';

  @override
  String get useCaseArrival => 'Let a loved one know you\'ve arrived safely.';

  @override
  String get useCaseGaming =>
      'Signal your team that the online game is starting.';

  @override
  String get useCaseSimpleHello =>
      'A simple \'hello\' without expecting a reply.';

  @override
  String get letsGo => 'Let\'s go!';

  @override
  String get chooseYourUsername => 'Choose your username';

  @override
  String get createMyAccount => 'Create my account';

  @override
  String get importExistingAccount => 'Import an existing account';

  @override
  String get supportDevelopment => 'Support development ❤️';

  @override
  String get previous => 'Previous';

  @override
  String get finish => 'Finish';

  @override
  String get next => 'Next';

  @override
  String serverConnectionError(Object server) {
    return 'Error: Could not contact the server $server. Please try again.';
  }

  @override
  String get languageUpdated => 'Language updated!';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get saveConfiguration => 'Save Configuration';

  @override
  String get saveConfigurationDescriptionLocal =>
      'Saves the current configuration to a local backup file. Any previous backup will be overwritten.';

  @override
  String get loadConfiguration => 'Load Configuration';

  @override
  String get loadConfigurationDescriptionLocal =>
      'Restores the configuration from the local backup file.';

  @override
  String get loadConfigurationWarningTitle => 'Load Configuration?';

  @override
  String get loadConfigurationWarning =>
      'Warning: This will replace all your current settings and contacts with the data from the backup. This action cannot be undone.';

  @override
  String get load => 'Load';

  @override
  String get configurationSavedSuccessfully =>
      'Configuration saved successfully.';

  @override
  String get configurationLoadedSuccessfully =>
      'Configuration loaded successfully.';

  @override
  String errorDuringSave(String error) {
    return 'Error during save: $error';
  }

  @override
  String errorDuringLoad(String error) {
    return 'Error during load: $error';
  }

  @override
  String get noBackupFileFound => 'No backup file found.';
}
