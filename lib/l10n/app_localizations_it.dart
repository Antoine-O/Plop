// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Plop';

  @override
  String get settings => 'Impostazioni';

  @override
  String get manageContacts => 'Gestisci contatti';

  @override
  String get noContactsYet =>
      'Nessun contatto ancora.\nVai a \"Gestisci contatti\" per aggiungerne uno.';

  @override
  String get generalSettings => 'Impostazioni Generali';

  @override
  String get syncTitle => 'Esporta / Importa';

  @override
  String get language => 'Lingua';

  @override
  String get systemLanguage => 'Lingua di sistema';

  @override
  String get french => 'Francese';

  @override
  String get english => 'Inglese';

  @override
  String get german => 'Tedesco';

  @override
  String get spanish => 'Spagnolo';

  @override
  String get italian => 'Italiano';

  @override
  String get myAccount => 'Il Mio Account';

  @override
  String get myUsername => 'Il mio nome utente';

  @override
  String get save => 'Salva';

  @override
  String get myUserId => 'Il mio ID utente (per il debug)';

  @override
  String get copied => 'Copiato!';

  @override
  String get quickMessages => 'Messaggi Rapidi';

  @override
  String get addNewQuickMessage => 'Nuovo messaggio rapido';

  @override
  String yourMessages(Object count) {
    return 'I tuoi messaggi ($count/10)';
  }

  @override
  String get noMessagesConfigured => 'Nessun messaggio configurato.';

  @override
  String get delete => 'Elimina';

  @override
  String get resetApp => 'Reimposta applicazione';

  @override
  String get inviteContact => 'Invita un contatto';

  @override
  String get addByCode => 'Aggiungi tramite codice';

  @override
  String get manageContactsTitle => 'Gestisci contatti';

  @override
  String get reorderListHint => 'Premi a lungo per riordinare l\'elenco.';

  @override
  String get noContactsToManage => 'Nessun contatto da gestire.';

  @override
  String get advancedSettings => 'Impostazioni avanzate';

  @override
  String get edit => 'Modifica';

  @override
  String get advancedSettingsTitle => 'Impostazioni avanzate';

  @override
  String get contactNameAlias => 'Nome contatto (alias)';

  @override
  String get ignoreNotifications => 'Ignora notifiche';

  @override
  String get muteThisContact => 'Silenzia questo contatto.';

  @override
  String get blockThisContact => 'Blocca questo contatto';

  @override
  String get hideThisContact => 'Nascondi questo contatto';

  @override
  String get doNotSeeInList =>
      'Non visualizzare questo contatto nell\'elenco principale.';

  @override
  String get notificationSound => 'Suono di notifica';

  @override
  String get defaultSound => 'Suono predefinito';

  @override
  String get overrideDefaultMessage => 'Sovrascrivi messaggio \"Plop\"';

  @override
  String get exampleNewPlop => 'Es: \"Nuovo Plop!\"';

  @override
  String get saveSettings => 'Salva impostazioni';

  @override
  String get settingsSaved => 'Impostazioni salvate!';

  @override
  String get confirmDeletion => 'Conferma eliminazione';

  @override
  String get deleteContactConfirmation => 'Questa azione è permanente.';

  @override
  String get cancel => 'ANNULLA';

  @override
  String get invitationDialogTitle => 'Il Tuo Codice di Invito';

  @override
  String invitationDialogBody(Object minutes) {
    return 'Condividi questo codice con un amico. È valido per $minutes minuti.';
  }

  @override
  String get copy => 'COPIA';

  @override
  String get share => 'CONDIVIDI';

  @override
  String get importAccountTitle => 'Importa un account esistente';

  @override
  String get importAccountBody =>
      'Inserisci il codice di sincronizzazione ottenuto dal tuo vecchio dispositivo per recuperare il tuo account e i tuoi contatti.';

  @override
  String get syncCode => 'Codice di sincronizzazione';

  @override
  String get import => 'Importa';

  @override
  String get exportAccountTitle => '1. Esporta questo account';

  @override
  String get exportAccountBody =>
      'Genera un codice unico e temporaneo su questo dispositivo (il tuo \"vecchio\" dispositivo). Questo codice è valido per 5 minuti.';

  @override
  String get generateExportCode => 'Genera un codice di esportazione';

  @override
  String get importAccountTitle2 => '2. Importa su un nuovo dispositivo';

  @override
  String get importAccountBody2 =>
      'Sul tuo NUOVO dispositivo, vai in questo stesso menu e inserisci il codice ottenuto. Questo sostituirà l\'account sul nuovo dispositivo con questo.';

  @override
  String get confirmImportTitle => 'Conferma importazione';

  @override
  String get confirmImportBody =>
      'Questa azione sostituirà il tuo account attuale e tutti i suoi dati. Sei sicuro di voler continuare?';

  @override
  String get iConfirm => 'IMPORTA';

  @override
  String get pleaseEnterCode => 'Per favore, inserisci un codice.';

  @override
  String get invalidOrExpiredCode => 'Codice non valido o scaduto.';

  @override
  String get addContact => 'Aggiungi contatto';

  @override
  String get invitationCode => 'Codice di invito*';

  @override
  String get contactNameOptional => 'Nome del contatto (opzionale)';

  @override
  String get chooseAColor => 'Scegli un colore';

  @override
  String get add => 'Aggiungi';

  @override
  String messageSentTo(Object contactName) {
    return 'Messaggio inviato a $contactName!';
  }

  @override
  String get unmute => 'Riattiva l\'audio';

  @override
  String get mute => 'Silenzia';

  @override
  String get codeCopied => 'Codice copiato!';

  @override
  String get startByAddingContact => 'Inizia aggiungendo un contatto';

  @override
  String get inviteOrEnterCode =>
      'Invita un amico o inserisci il suo codice per iniziare a ploppare.';

  @override
  String get shareMyCode => 'Condividi il mio codice';

  @override
  String get enterInvitationCode => 'Inserisci un codice di invito';

  @override
  String get saveUsername => 'Salva nome utente';

  @override
  String get userIdCopied => 'ID utente copiato!';

  @override
  String get maxTenMessages => 'Non puoi avere più di 10 messaggi.';

  @override
  String get deleteThisContact => 'Eliminare questo contatto?';

  @override
  String get actionIsPermanent => 'Questa azione è permanente.';

  @override
  String get resetAppQuestion => 'Reimpostare l\'applicazione?';

  @override
  String get resetWarning =>
      'Tutti i tuoi dati (account, contatti) verranno eliminati definitivamente. Questa azione è irreversibile.';

  @override
  String get importWarning =>
      'Questa azione sostituirà il tuo account corrente e tutti i suoi dati.';

  @override
  String get syncYourAccount => 'Sincronizza il tuo account';

  @override
  String get enterSyncCodeToRetrieve =>
      'Inserisci il codice di sincronizzazione ottenuto dal tuo vecchio dispositivo per recuperare il tuo account e i tuoi contatti.';

  @override
  String get pleaseEnterSyncCode =>
      'Per favore, inserisci un codice di sincronizzazione.';

  @override
  String get userImported => 'Utente importato';

  @override
  String get welcomeToPlop => 'Benvenuto su Plop';

  @override
  String get appTagline =>
      'Il messenger ultra-semplice, effimero e rispettoso della privacy.';

  @override
  String get howItWorks => 'Come funziona?';

  @override
  String get featureNoSignup => 'Nessuna registrazione, solo un nome utente.';

  @override
  String get featureTempCodes =>
      'Aggiungi contatti con codici unici e temporanei.';

  @override
  String get featureQuickMessages => 'Invia \'Plop\' o messaggi veloci.';

  @override
  String get featurePrivacy => 'Niente viene memorizzato sui nostri server.';

  @override
  String get useCases => 'Alcuni casi d\'uso';

  @override
  String get useCaseArrival =>
      'Fai sapere a una persona cara che sei arrivato sano e salvo.';

  @override
  String get useCaseGaming =>
      'Segnala alla tua squadra che il gioco online sta iniziando.';

  @override
  String get useCaseSimpleHello =>
      'Un semplice \'ciao\' senza aspettarsi una risposta.';

  @override
  String get letsGo => 'Andiamo!';

  @override
  String get chooseYourUsername => 'Scegli il tuo nome utente';

  @override
  String get createMyAccount => 'Crea il mio account';

  @override
  String get importExistingAccount => 'Importa un account esistente';

  @override
  String get supportDevelopment => 'Sostieni lo sviluppo ❤️';

  @override
  String get previous => 'Precedente';

  @override
  String get finish => 'Fine';

  @override
  String get next => 'Avanti';

  @override
  String serverConnectionError(Object server) {
    return 'Errore: Impossibile contattare il server $server. Si prega di riprovare.';
  }

  @override
  String get languageUpdated => 'Lingua aggiornata!';

  @override
  String get backupAndRestore => 'Backup e Ripristino';

  @override
  String get saveConfiguration => 'Salva configurazione';

  @override
  String get saveConfigurationDescriptionLocal =>
      'Salva la configurazione corrente in un file di backup locale. Qualsiasi backup precedente verrà sovrascritto.';

  @override
  String get loadConfiguration => 'Carica configurazione';

  @override
  String get loadConfigurationDescriptionLocal =>
      'Ripristina la configurazione dal file di backup locale.';

  @override
  String get loadConfigurationWarningTitle => 'Caricare la configurazione?';

  @override
  String get loadConfigurationWarning =>
      'Attenzione: Questo sostituirà tutte le impostazioni e i contatti attuali con i dati del backup. Questa azione è irreversibile.';

  @override
  String get load => 'Carica';

  @override
  String get configurationSavedSuccessfully =>
      'Configurazione salvata con successo.';

  @override
  String get configurationLoadedSuccessfully =>
      'Configurazione caricata con successo.';

  @override
  String errorDuringSave(String error) {
    return 'Errore durante il salvataggio: $error';
  }

  @override
  String errorDuringLoad(String error) {
    return 'Errore durante il caricamento: $error';
  }

  @override
  String get noBackupFileFound => 'Nessun file di backup trovato.';

  @override
  String get restoreYourAccount => 'Ripristina il tuo account';

  @override
  String get restoreFromBackup => 'Ripristina da backup';

  @override
  String get restoreBackupBody =>
      'Seleziona un file di backup salvato in precedenza per ripristinare i dati del tuo account. Questo sovrascriverà tutti i dati attuali su questo dispositivo.';

  @override
  String get selectBackupFile => 'Seleziona file di backup';
}
