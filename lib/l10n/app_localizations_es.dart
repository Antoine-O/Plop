// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Plop';

  @override
  String get settings => 'Ajustes';

  @override
  String get manageContacts => 'Gestionar contactos';

  @override
  String get noContactsYet =>
      'Aún no hay contactos.\nVaya a \"Gestionar contactos\" para añadir uno.';

  @override
  String get generalSettings => 'Ajustes Generales';

  @override
  String get syncTitle => 'Exportar / Importar';

  @override
  String get language => 'Idioma';

  @override
  String get systemLanguage => 'Idioma del sistema';

  @override
  String get french => 'Francés';

  @override
  String get english => 'Inglés';

  @override
  String get german => 'Alemán';

  @override
  String get spanish => 'Español';

  @override
  String get italian => 'Italiano';

  @override
  String get myAccount => 'Mi Cuenta';

  @override
  String get myUsername => 'Mi nombre de usuario';

  @override
  String get save => 'Guardar';

  @override
  String get myUserId => 'Mi ID de usuario (para depuración)';

  @override
  String get copied => '¡Copiado!';

  @override
  String get quickMessages => 'Mensajes Rápidos';

  @override
  String get addNewQuickMessage => 'Nuevo mensaje rápido';

  @override
  String yourMessages(Object count) {
    return 'Tus mensajes ($count/10)';
  }

  @override
  String get noMessagesConfigured => 'No hay mensajes configurados.';

  @override
  String get delete => 'Eliminar';

  @override
  String get resetApp => 'Restablecer aplicación';

  @override
  String get inviteContact => 'Invitar a un contacto';

  @override
  String get addByCode => 'Añadir por código';

  @override
  String get manageContactsTitle => 'Gestionar contactos';

  @override
  String get reorderListHint => 'Mantenga presionado para reordenar la lista.';

  @override
  String get noContactsToManage => 'No hay contactos que gestionar.';

  @override
  String get advancedSettings => 'Ajustes avanzados';

  @override
  String get edit => 'Editar';

  @override
  String get advancedSettingsTitle => 'Ajustes avanzados';

  @override
  String get contactNameAlias => 'Nombre del contacto (alias)';

  @override
  String get ignoreNotifications => 'Ignorar notificaciones';

  @override
  String get muteThisContact => 'Silenciar este contacto.';

  @override
  String get blockThisContact => 'Bloquear este contacto';

  @override
  String get hideThisContact => 'Ocultar este contacto';

  @override
  String get doNotSeeInList => 'No ver este contacto en la lista principal.';

  @override
  String get notificationSound => 'Sonido de notificación';

  @override
  String get defaultSound => 'Sonido predeterminado';

  @override
  String get overrideDefaultMessage => 'Sobrescribir mensaje \"Plop\"';

  @override
  String get exampleNewPlop => 'Ej: \"¡Nuevo Plop!\"';

  @override
  String get saveSettings => 'Guardar ajustes';

  @override
  String get settingsSaved => '¡Ajustes guardados!';

  @override
  String get confirmDeletion => 'Confirmar eliminación';

  @override
  String get deleteContactConfirmation => 'Esta acción es permanente.';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get invitationDialogTitle => 'Tu Código de Invitación';

  @override
  String invitationDialogBody(Object minutes) {
    return 'Comparte este código con un amigo. Es válido durante $minutes minutos.';
  }

  @override
  String get copy => 'COPIAR';

  @override
  String get share => 'COMPARTIR';

  @override
  String get importAccountTitle => 'Importar una cuenta existente';

  @override
  String get importAccountBody =>
      'Introduce el código de sincronización obtenido en tu antiguo dispositivo para recuperar tu cuenta y tus contactos.';

  @override
  String get syncCode => 'Código de sincronización';

  @override
  String get import => 'Importar';

  @override
  String get exportAccountTitle => '1. Exportar esta cuenta';

  @override
  String get exportAccountBody =>
      'Genere un código único y temporal en este dispositivo (su \"antiguo\" dispositivo). Este código es válido por 5 minutos.';

  @override
  String get generateExportCode => 'Generar un código de exportación';

  @override
  String get importAccountTitle2 => '2. Importar en un nuevo dispositivo';

  @override
  String get importAccountBody2 =>
      'En su NUEVO dispositivo, vaya a este mismo menú e introduzca el código obtenido. Esto reemplazará la cuenta en el nuevo dispositivo con esta.';

  @override
  String get confirmImportTitle => 'Confirmar importación';

  @override
  String get confirmImportBody =>
      'Esta acción reemplazará su cuenta actual y todos sus datos. ¿Está seguro de que desea continuar?';

  @override
  String get iConfirm => 'IMPORTAR';

  @override
  String get pleaseEnterCode => 'Por favor, introduzca un código.';

  @override
  String get invalidOrExpiredCode => 'Código inválido o caducado.';

  @override
  String get addContact => 'Añadir contacto';

  @override
  String get invitationCode => 'Código de invitación*';

  @override
  String get contactNameOptional => 'Nombre del contacto (opcional)';

  @override
  String get chooseAColor => 'Elige un color';

  @override
  String get add => 'Añadir';

  @override
  String messageSentTo(Object contactName) {
    return '¡Mensaje enviado a $contactName!';
  }

  @override
  String get unmute => 'Reactivar sonido';

  @override
  String get mute => 'Silenciar';

  @override
  String get codeCopied => '¡Código copiado!';

  @override
  String get startByAddingContact => 'Empieza por añadir un contacto';

  @override
  String get inviteOrEnterCode =>
      'Invita a un amigo o introduce su código para empezar a plopear.';

  @override
  String get shareMyCode => 'Compartir mi código';

  @override
  String get enterInvitationCode => 'Introducir un código de invitación';

  @override
  String get saveUsername => 'Guardar nombre de usuario';

  @override
  String get userIdCopied => '¡ID de usuario copiado!';

  @override
  String get maxTenMessages => 'No puedes tener más de 10 mensajes.';

  @override
  String get deleteThisContact => '¿Eliminar este contacto?';

  @override
  String get actionIsPermanent => 'Esta acción es permanente.';

  @override
  String get resetAppQuestion => '¿Restablecer la aplicación?';

  @override
  String get resetWarning =>
      'Todos sus datos (cuenta, contactos) se eliminarán permanentemente. Esta acción es irreversible.';

  @override
  String get importWarning =>
      'Esta acción reemplazará su cuenta actual y todos sus datos.';

  @override
  String get syncYourAccount => 'Sincroniza tu cuenta';

  @override
  String get enterSyncCodeToRetrieve =>
      'Introduce el código de sincronización obtenido en tu antiguo dispositivo para recuperar tu cuenta y tus contactos.';

  @override
  String get pleaseEnterSyncCode =>
      'Por favor, introduzca un código de sincronización.';

  @override
  String get userImported => 'Usuario importado';

  @override
  String get welcomeToPlop => 'Bienvenido a Plop';

  @override
  String get appTagline =>
      'El mensajero ultra simple, efímero y respetuoso con la privacidad.';

  @override
  String get howItWorks => '¿Cómo funciona?';

  @override
  String get featureNoSignup => 'Sin registro, solo un nombre de usuario.';

  @override
  String get featureTempCodes =>
      'Añade contactos con códigos únicos y temporales.';

  @override
  String get featureQuickMessages => 'Envía \'Plops\' o mensajes rápidos.';

  @override
  String get featurePrivacy => 'No se almacena nada en nuestros servidores.';

  @override
  String get useCases => 'Algunos casos de uso';

  @override
  String get useCaseArrival =>
      'Avisa a un ser querido de que has llegado bien.';

  @override
  String get useCaseGaming =>
      'Señala a tu equipo que el juego en línea está comenzando.';

  @override
  String get useCaseSimpleHello => 'Un simple \'hola\' sin esperar respuesta.';

  @override
  String get letsGo => '¡Vamos allá!';

  @override
  String get chooseYourUsername => 'Elige tu nombre de usuario';

  @override
  String get createMyAccount => 'Crear mi cuenta';

  @override
  String get importExistingAccount => 'Importar una cuenta existente';

  @override
  String get supportDevelopment => 'Apoyar el desarrollo ❤️';

  @override
  String get previous => 'Anterior';

  @override
  String get finish => 'Terminar';

  @override
  String get next => 'Siguiente';

  @override
  String serverConnectionError(Object server) {
    return 'Error: No se pudo contactar con el servidor $server. Por favor, inténtelo de nuevo.';
  }

  @override
  String get languageUpdated => '¡Idioma actualizado!';

  @override
  String get backupAndRestore => 'Copia de seguridad y Restauración';

  @override
  String get saveConfiguration => 'Guardar configuración';

  @override
  String get saveConfigurationDescriptionLocal =>
      'Guarda la configuración actual en un archivo de copia de seguridad local. Cualquier copia anterior será sobrescrita.';

  @override
  String get loadConfiguration => 'Cargar configuración';

  @override
  String get loadConfigurationDescriptionLocal =>
      'Restaura la configuración desde el archivo de copia de seguridad local.';

  @override
  String get loadConfigurationWarningTitle => '¿Cargar la configuración?';

  @override
  String get loadConfigurationWarning =>
      'Atención: Esto reemplazará todos sus ajustes y contactos actuales con los datos de la copia de seguridad. Esta acción no se puede deshacer.';

  @override
  String get load => 'Cargar';

  @override
  String get configurationSavedSuccessfully =>
      'Configuración guardada correctamente.';

  @override
  String get configurationLoadedSuccessfully =>
      'Configuración cargada correctamente.';

  @override
  String errorDuringSave(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String errorDuringLoad(String error) {
    return 'Error al cargar: $error';
  }

  @override
  String get noBackupFileFound =>
      'No se encontró ningún archivo de copia de seguridad.';

  @override
  String get restoreYourAccount => 'Restaura tu cuenta';

  @override
  String get restoreFromBackup => 'Restaurar desde copia de seguridad';

  @override
  String get restoreBackupBody =>
      'Selecciona un archivo de copia de seguridad guardado previamente para restaurar los datos de tu cuenta. Esto sobrescribirá todos los datos actuales en este dispositivo.';

  @override
  String get selectBackupFile => 'Seleccionar archivo de copia';

  @override
  String get deleteContact => 'Eliminar Contacto';

  @override
  String get confirmDeletionTitle => 'Confirmar Eliminación';

  @override
  String get confirmDeletionBody =>
      '¿Estás seguro de que quieres eliminar este contacto de forma permanente? Esta acción no se puede deshacer.';

  @override
  String get contactDeletedSuccessfully => 'Contacto eliminado con éxito';
}
