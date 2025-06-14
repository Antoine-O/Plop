// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Plop';

  @override
  String get settings => 'Paramètres';

  @override
  String get manageContacts => 'Gérer les contacts';

  @override
  String get noContactsYet =>
      'Aucun contact pour le moment.\nAllez dans \"Gérer les contacts\" pour en ajouter.';

  @override
  String get generalSettings => 'Paramètres Généraux';

  @override
  String get syncTitle => 'Exporter / Importer';

  @override
  String get language => 'Langue';

  @override
  String get systemLanguage => 'Langue du système';

  @override
  String get french => 'Français';

  @override
  String get english => 'Anglais';

  @override
  String get german => 'Allemand';

  @override
  String get spanish => 'Espagnol';

  @override
  String get italian => 'Italien';

  @override
  String get myAccount => 'Mon Compte';

  @override
  String get myUsername => 'Mon pseudo';

  @override
  String get save => 'Enregistrer';

  @override
  String get myUserId => 'Mon User ID (pour le débogage)';

  @override
  String get copied => 'Copié !';

  @override
  String get quickMessages => 'Messages Rapides';

  @override
  String get addNewQuickMessage => 'Nouveau message rapide';

  @override
  String yourMessages(Object count) {
    return 'Vos messages ($count/10)';
  }

  @override
  String get noMessagesConfigured => 'Aucun message configuré.';

  @override
  String get delete => 'Supprimer';

  @override
  String get resetApp => 'Réinitialiser l\'application';

  @override
  String get inviteContact => 'Inviter un contact';

  @override
  String get addByCode => 'Ajouter via un code';

  @override
  String get manageContactsTitle => 'Gérer les contacts';

  @override
  String get reorderListHint =>
      'Faites un appui long pour réorganiser la liste.';

  @override
  String get noContactsToManage => 'Aucun contact à gérer.';

  @override
  String get advancedSettings => 'Paramètres avancés';

  @override
  String get edit => 'Modifier';

  @override
  String get advancedSettingsTitle => 'Paramètres avancés';

  @override
  String get contactNameAlias => 'Nom du contact (alias)';

  @override
  String get ignoreNotifications => 'Ignorer les notifications';

  @override
  String get muteThisContact => 'Met ce contact en silencieux.';

  @override
  String get blockThisContact => 'Bloquer ce contact';

  @override
  String get hideThisContact => 'Cacher ce contact';

  @override
  String get doNotSeeInList =>
      'Ne plus voir ce contact dans la liste principale.';

  @override
  String get notificationSound => 'Son de notification';

  @override
  String get defaultSound => 'Son par défaut';

  @override
  String get overrideDefaultMessage => 'Remplacer le message \"Plop\"';

  @override
  String get exampleNewPlop => 'Ex: \"Nouveau Plop !\"';

  @override
  String get saveSettings => 'Enregistrer les paramètres';

  @override
  String get settingsSaved => 'Paramètres enregistrés !';

  @override
  String get confirmDeletion => 'Confirmer la suppression';

  @override
  String get deleteContactConfirmation => 'Cette action est définitive.';

  @override
  String get cancel => 'ANNULER';

  @override
  String get invitationDialogTitle => 'Votre Code d\'Invitation';

  @override
  String invitationDialogBody(Object minutes) {
    return 'Partagez ce code avec un ami. Il est valide pendant $minutes minutes.';
  }

  @override
  String get copy => 'COPIER';

  @override
  String get share => 'PARTAGER';

  @override
  String get importAccountTitle => 'Importer un compte existant';

  @override
  String get importAccountBody =>
      'Entrez le code de synchronisation obtenu sur votre ancien appareil pour récupérer votre compte et vos contacts.';

  @override
  String get syncCode => 'Code de synchronisation';

  @override
  String get import => 'Importer';

  @override
  String get exportAccountTitle => '1. Exporter ce compte';

  @override
  String get exportAccountBody =>
      'Générez un code unique sur cet appareil (votre \"ancien\" appareil). Ce code est valide 5 minutes.';

  @override
  String get generateExportCode => 'Générer un code d\'export';

  @override
  String get importAccountTitle2 => '2. Importer sur un nouvel appareil';

  @override
  String get importAccountBody2 =>
      'Sur votre NOUVEL appareil, allez dans ce même menu et entrez le code obtenu. Cela remplacera le compte sur le nouvel appareil par celui-ci.';

  @override
  String get confirmImportTitle => 'Confirmer l\'importation';

  @override
  String get confirmImportBody =>
      'Cette action remplacera votre compte actuel et toutes ses données. Êtes-vous sûr de vouloir continuer ?';

  @override
  String get iConfirm => 'IMPORTER';

  @override
  String get pleaseEnterCode => 'Veuillez entrer un code.';

  @override
  String get invalidOrExpiredCode => 'Code invalide ou expiré.';

  @override
  String get addContact => 'Ajouter un contact';

  @override
  String get invitationCode => 'Code d\'invitation*';

  @override
  String get contactNameOptional => 'Nom pour ce contact (optionnel)';

  @override
  String get chooseAColor => 'Choisir une couleur';

  @override
  String get add => 'Ajouter';

  @override
  String messageSentTo(Object contactName) {
    return 'Message envoyé à $contactName !';
  }

  @override
  String get unmute => 'Réactiver le son';

  @override
  String get mute => 'Mettre en sourdine';

  @override
  String get codeCopied => 'Code copié !';

  @override
  String get startByAddingContact => 'Commencez par ajouter un contact';

  @override
  String get inviteOrEnterCode =>
      'Invitez un ami ou entrez son code pour commencer à plopper.';

  @override
  String get shareMyCode => 'Partager mon code';

  @override
  String get enterInvitationCode => 'Entrer un code d\'invitation';

  @override
  String get saveUsername => 'Enregistrer le pseudo';

  @override
  String get userIdCopied => 'User ID copié !';

  @override
  String get maxTenMessages => 'Vous ne pouvez pas avoir plus de 10 messages.';

  @override
  String get deleteThisContact => 'Supprimer ce contact ?';

  @override
  String get actionIsPermanent => 'Cette action est définitive.';

  @override
  String get resetAppQuestion => 'Réinitialiser l\'application ?';

  @override
  String get resetWarning =>
      'Toutes vos données (compte, contacts) seront supprimées définitivement. Cette action est irréversible.';

  @override
  String get importWarning =>
      'Cette action remplacera votre compte actuel et toutes ses données.';

  @override
  String get syncYourAccount => 'Synchronisez votre compte';

  @override
  String get enterSyncCodeToRetrieve =>
      'Entrez le code de synchronisation obtenu sur votre ancien appareil pour récupérer votre compte et vos contacts.';

  @override
  String get pleaseEnterSyncCode =>
      'Veuillez entrer un code de synchronisation.';

  @override
  String get userImported => 'Utilisateur importé';

  @override
  String get welcomeToPlop => 'Bienvenue sur Plop';

  @override
  String get appTagline =>
      'La messagerie ultra-simple, éphémère et respectueuse de votre vie privée.';

  @override
  String get howItWorks => 'Comment ça marche ?';

  @override
  String get featureNoSignup => 'Aucune inscription, juste un pseudo.';

  @override
  String get featureTempCodes =>
      'Ajoutez des contacts avec des codes uniques et temporaires.';

  @override
  String get featureQuickMessages =>
      'Envoyez des \'Plop\' ou des messages rapides.';

  @override
  String get featurePrivacy => 'Rien n\'est stocké sur nos serveurs.';

  @override
  String get useCases => 'Quelques cas d\'usage';

  @override
  String get useCaseArrival => 'Prévenir un proche que vous êtes bien arrivé.';

  @override
  String get useCaseGaming =>
      'Signaler à votre équipe que la partie en ligne commence.';

  @override
  String get useCaseSimpleHello =>
      'Un simple \'coucou\' sans attendre de réponse.';

  @override
  String get letsGo => 'C\'est parti !';

  @override
  String get chooseYourUsername => 'Choisissez votre pseudo';

  @override
  String get createMyAccount => 'Créer mon compte';

  @override
  String get importExistingAccount => 'Importer un compte existant';

  @override
  String get supportDevelopment => 'Soutenir le développement ❤️';

  @override
  String get previous => 'Précédent';

  @override
  String get finish => 'Terminer';

  @override
  String get next => 'Suivant';

  @override
  String serverConnectionError(Object server) {
    return 'Error: Could not contact the server $server. Please try again.';
  }

  @override
  String get languageUpdated => 'Langue mise à jour !';
}
