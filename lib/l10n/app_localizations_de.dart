// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Plop';

  @override
  String get settings => 'Einstellungen';

  @override
  String get manageContacts => 'Kontakte verwalten';

  @override
  String get noContactsYet =>
      'Noch keine Kontakte.\nGehen Sie zu \"Kontakte verwalten\", um einen hinzuzufügen.';

  @override
  String get generalSettings => 'Allgemeine Einstellungen';

  @override
  String get syncTitle => 'Exportieren / Importieren';

  @override
  String get language => 'Sprache';

  @override
  String get systemLanguage => 'Systemsprache';

  @override
  String get french => 'Französisch';

  @override
  String get english => 'Englisch';

  @override
  String get german => 'Deutsch';

  @override
  String get spanish => 'Spanisch';

  @override
  String get italian => 'Italienisch';

  @override
  String get myAccount => 'Mein Konto';

  @override
  String get myUsername => 'Mein Benutzername';

  @override
  String get save => 'Speichern';

  @override
  String get myUserId => 'Meine Benutzer-ID (zum Debuggen)';

  @override
  String get copied => 'Kopiert!';

  @override
  String get quickMessages => 'Schnellnachrichten';

  @override
  String get addNewQuickMessage => 'Neue Schnellnachricht';

  @override
  String yourMessages(Object count) {
    return 'Ihre Nachrichten ($count/10)';
  }

  @override
  String get noMessagesConfigured => 'Keine Nachrichten konfiguriert.';

  @override
  String get resetApp => 'Anwendung zurücksetzen';

  @override
  String get inviteContact => 'Kontakt einladen';

  @override
  String get addByCode => 'Per Code hinzufügen';

  @override
  String get manageContactsTitle => 'Kontakte verwalten';

  @override
  String get reorderListHint => 'Lange drücken, um die Liste neu zu ordnen.';

  @override
  String get noContactsToManage => 'Keine Kontakte zu verwalten.';

  @override
  String get advancedSettings => 'Erweiterte Einstellungen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get advancedSettingsTitle => 'Erweiterte Einstellungen';

  @override
  String get contactNameAlias => 'Kontaktname (Alias)';

  @override
  String get ignoreNotifications => 'Benachrichtigungen ignorieren';

  @override
  String get muteThisContact => 'Diesen Kontakt stummschalten.';

  @override
  String get blockThisContact => 'Diesen Kontakt blockieren';

  @override
  String get hideThisContact => 'Diesen Kontakt ausblenden';

  @override
  String get doNotSeeInList =>
      'Diesen Kontakt nicht in der Hauptliste anzeigen.';

  @override
  String get notificationSound => 'Benachrichtigungston';

  @override
  String get defaultSound => 'Standardton';

  @override
  String get overrideDefaultMessage => '\"Plop\"-Nachricht überschreiben';

  @override
  String get exampleNewPlop => 'Z.B. \"Neues Plop!\"';

  @override
  String get saveSettings => 'Einstellungen speichern';

  @override
  String get settingsSaved => 'Einstellungen gespeichert!';

  @override
  String get confirmDeletion => 'Löschen bestätigen';

  @override
  String get deleteContactConfirmation => 'Diese Aktion ist endgültig.';

  @override
  String get cancel => 'ABBRECHEN';

  @override
  String get invitationDialogTitle => 'Ihr Einladungscode';

  @override
  String invitationDialogBody(Object minutes) {
    return 'Teilen Sie diesen Code mit einem Freund. Er ist $minutes Minuten gültig.';
  }

  @override
  String get copy => 'KOPIEREN';

  @override
  String get share => 'TEILEN';

  @override
  String get importAccountTitle => 'Ein bestehendes Konto importieren';

  @override
  String get importAccountBody =>
      'Geben Sie den Synchronisierungscode von Ihrem alten Gerät ein, um Ihr Konto und Ihre Kontakte abzurufen.';

  @override
  String get syncCode => 'Synchronisierungscode';

  @override
  String get import => 'Importieren';

  @override
  String get exportAccountTitle => '1. Dieses Konto exportieren';

  @override
  String get exportAccountBody =>
      'Generieren Sie einen einmaligen und temporären Code auf diesem Gerät (Ihrem \"alten\" Gerät). Dieser Code ist 5 Minuten gültig.';

  @override
  String get generateExportCode => 'Einen Exportcode generieren';

  @override
  String get importAccountTitle2 => '2. Auf einem neuen Gerät importieren';

  @override
  String get importAccountBody2 =>
      'Gehen Sie auf Ihrem NEUEN Gerät in dasselbe Menü und geben Sie den erhaltenen Code ein. Dies ersetzt das Konto auf dem neuen Gerät durch dieses.';

  @override
  String get confirmImportTitle => 'Import bestätigen';

  @override
  String get confirmImportBody =>
      'Diese Aktion ersetzt Ihr aktuelles Konto und alle seine Daten. Sind Sie sicher, dass Sie fortfahren möchten?';

  @override
  String get iConfirm => 'IMPORTIEREN';

  @override
  String get pleaseEnterCode => 'Bitte geben Sie einen Code ein.';

  @override
  String get invalidOrExpiredCode => 'Ungültiger oder abgelaufener Code.';

  @override
  String get addContact => 'Kontakt hinzufügen';

  @override
  String get invitationCode => 'Einladungscode*';

  @override
  String get contactNameOptional => 'Kontaktname (optional)';

  @override
  String get chooseAColor => 'Wählen Sie eine Farbe';

  @override
  String get add => 'Hinzufügen';

  @override
  String messageSentTo(Object contactName) {
    return 'Nachricht an $contactName gesendet!';
  }

  @override
  String get unmute => 'Stummschaltung aufheben';

  @override
  String get mute => 'Stummschalten';

  @override
  String get codeCopied => 'Code kopiert!';

  @override
  String get startByAddingContact =>
      'Beginnen Sie mit dem Hinzufügen eines Kontakts';

  @override
  String get inviteOrEnterCode =>
      'Laden Sie einen Freund ein oder geben Sie seinen Code ein, um mit dem Ploppen zu beginnen.';

  @override
  String get shareMyCode => 'Meinen Code teilen';

  @override
  String get enterInvitationCode => 'Geben Sie einen Einladungscode ein';

  @override
  String get saveUsername => 'Benutzernamen speichern';

  @override
  String get userIdCopied => 'Benutzer-ID kopiert!';

  @override
  String get maxTenMessages =>
      'Sie können nicht mehr als 10 Nachrichten haben.';

  @override
  String get deleteThisContact => 'Diesen Kontakt löschen?';

  @override
  String get actionIsPermanent => 'Diese Aktion ist endgültig.';

  @override
  String get resetAppQuestion => 'Anwendung zurücksetzen?';

  @override
  String get resetWarning =>
      'Alle Ihre Daten (Konto, Kontakte) werden dauerhaft gelöscht. Diese Aktion ist unumkehrbar.';

  @override
  String get importWarning =>
      'Diese Aktion ersetzt Ihr aktuelles Konto und alle seine Daten.';

  @override
  String get syncYourAccount => 'Synchronisieren Sie Ihr Konto';

  @override
  String get enterSyncCodeToRetrieve =>
      'Geben Sie den Synchronisierungscode von Ihrem alten Gerät ein, um Ihr Konto und Ihre Kontakte abzurufen.';

  @override
  String get pleaseEnterSyncCode =>
      'Bitte geben Sie einen Synchronisierungscode ein.';

  @override
  String get userImported => 'Benutzer importiert';

  @override
  String get welcomeToPlop => 'Willkommen bei Plop';

  @override
  String get appTagline =>
      'Der ultra-einfache, ephemere und datenschutzfreundliche Messenger.';

  @override
  String get howItWorks => 'Wie funktioniert es?';

  @override
  String get featureNoSignup => 'Keine Registrierung, nur ein Benutzername.';

  @override
  String get featureTempCodes =>
      'Fügen Sie Kontakte mit einzigartigen, temporären Codes hinzu.';

  @override
  String get featureQuickMessages =>
      'Senden Sie \'Plops\' oder schnelle Nachrichten.';

  @override
  String get featurePrivacy => 'Nichts wird auf unseren Servern gespeichert.';

  @override
  String get useCases => 'Einige Anwendungsfälle';

  @override
  String get useCaseArrival =>
      'Lassen Sie einen geliebten Menschen wissen, dass Sie sicher angekommen sind.';

  @override
  String get useCaseGaming =>
      'Signalisieren Sie Ihrem Team, dass das Online-Spiel beginnt.';

  @override
  String get useCaseSimpleHello =>
      'Ein einfaches \'Hallo\', ohne eine Antwort zu erwarten.';

  @override
  String get letsGo => 'Los geht\'s!';

  @override
  String get chooseYourUsername => 'Wählen Sie Ihren Benutzernamen';

  @override
  String get createMyAccount => 'Mein Konto erstellen';

  @override
  String get importExistingAccount => 'Ein bestehendes Konto importieren';

  @override
  String get supportDevelopment => 'Entwicklung unterstützen ❤️';

  @override
  String get previous => 'Zurück';

  @override
  String get finish => 'Fertigstellen';

  @override
  String get next => 'Weiter';

  @override
  String serverConnectionError(Object server) {
    return 'Fehler: Der Server $server konnte nicht kontaktiert werden. Bitte versuchen Sie es erneut.';
  }

  @override
  String get languageUpdated => 'Sprache aktualisiert!';

  @override
  String get backupAndRestore => 'Sicherung & Wiederherstellung';

  @override
  String get saveConfiguration => 'Konfiguration speichern';

  @override
  String get saveConfigurationDescriptionLocal =>
      'Speichert die aktuelle Konfiguration in einer lokalen Sicherungsdatei. Jede frühere Sicherung wird überschrieben.';

  @override
  String get loadConfiguration => 'Konfiguration laden';

  @override
  String get loadConfigurationDescriptionLocal =>
      'Stellt die Konfiguration aus der lokalen Sicherungsdatei wieder her.';

  @override
  String get loadConfigurationWarningTitle => 'Konfiguration laden?';

  @override
  String get loadConfigurationWarning =>
      'Achtung: Dies ersetzt alle Ihre aktuellen Einstellungen und Kontakte durch die Daten aus der Sicherung. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get load => 'Laden';

  @override
  String get configurationSavedSuccessfully =>
      'Konfiguration erfolgreich gespeichert.';

  @override
  String get configurationLoadedSuccessfully =>
      'Konfiguration erfolgreich geladen.';

  @override
  String errorDuringSave(String error) {
    return 'Fehler beim Speichern: $error';
  }

  @override
  String errorDuringLoad(String error) {
    return 'Fehler beim Laden: $error';
  }

  @override
  String get noBackupFileFound => 'Keine Sicherungsdatei gefunden.';

  @override
  String get restoreYourAccount => 'Stelle dein Konto wieder her';

  @override
  String get restoreFromBackup => 'Aus Backup wiederherstellen';

  @override
  String get restoreBackupBody =>
      'Wähle eine zuvor gespeicherte Sicherungsdatei aus, um deine Kontodaten wiederherzustellen. Dadurch werden alle aktuellen Daten auf diesem Gerät überschrieben.';

  @override
  String get selectBackupFile => 'Sicherungsdatei auswählen';

  @override
  String get deleteContact => 'Kontakt löschen';

  @override
  String get confirmDeletionTitle => 'Löschen bestätigen';

  @override
  String get confirmDeletionBody =>
      'Möchtest du diesen Kontakt wirklich endgültig löschen? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get delete => 'Löschen';

  @override
  String get contactDeletedSuccessfully => 'Kontakt erfolgreich gelöscht';

  @override
  String get muteTooltip => 'Stummschalten';

  @override
  String get unmuteTooltip => 'Stummschaltung aufheben';

  @override
  String get statusSending => 'Wird gesendet...';

  @override
  String get statusSent => 'Gesendet';

  @override
  String get statusAcknowledged => 'Bestätigt';

  @override
  String get statusFailed => 'Fehlgeschlagen';

  @override
  String get statusDistributed => 'Verteilt';

  @override
  String get statusPending => 'Ausstehend';

  @override
  String get startByAddingContactTitle =>
      'Beginnen Sie mit dem Hinzufügen eines Kontakts';

  @override
  String get startByAddingContactSubtitle =>
      'Laden Sie einen Freund ein oder geben Sie dessen Code ein, um mit dem Ploppen zu beginnen.';

  @override
  String get addViaCode => 'Über Code hinzufügen';

  @override
  String get usernameUpdated => 'Benutzername aktualisiert!';

  @override
  String get myUserIdDebug => 'Meine Benutzer-ID (zum Debuggen)';

  @override
  String get wsServerTitle => 'WS-Server';

  @override
  String get httpServerTitle => 'HTTP-Server';

  @override
  String get resetButtonAction => 'ZURÜCKSETZEN';

  @override
  String invitationShareText(String invitationCode) {
    return 'Mein Plop-Einladungscode lautet: $invitationCode';
  }

  @override
  String get errorGeneratingCode =>
      'Fehler: Code konnte nicht generiert werden.';

  @override
  String get tooltipGlobalMute => 'Globaler Stumm-Modus';

  @override
  String errorDuringDeletion(String error) {
    return 'Fehler beim Löschen: $error';
  }

  @override
  String get tooltipMuteContact => 'Kontakt stummschalten';

  @override
  String get tooltipHideContact => 'Kontakt ausblenden';

  @override
  String get tooltipAdvancedSettings => 'Erweiterte Einstellungen';

  @override
  String syncCodeShareText(String generatedCode) {
    return 'Mein Plop-Synchronisationscode lautet: $generatedCode';
  }

  @override
  String get importAccountButtonLabel => 'Konto importieren';

  @override
  String get defaultImportedUsername => 'Imported User';

  @override
  String selectedFileDisplay(String fileName) {
    return 'Selected file: $fileName';
  }

  @override
  String criticalStartupError(String error, String stackTrace) {
    return 'Critical error during startup:\n\n$error\n\n$stackTrace';
  }
}
