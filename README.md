# **Plop - Application de Communication Minimaliste**

**Une application de communication minimaliste, sécurisée et multiplateforme, basée sur un système d'invitations privées et temporaires.**

Plop réinvente la manière de se connecter en supprimant les frictions habituelles (inscription, mot de passe, recherche de contacts publics) pour se concentrer sur l'essentiel : une communication rapide et privée entre des personnes qui se connaissent déjà. Clairement inspiré de l'application Yo! 

## **Objectif du Projet**

L'objectif de Plop est de fournir un outil de notification ultra-rapide qui respecte la vie privée et redonne le contrôle à l'utilisateur. La philosophie du projet repose sur quatre piliers :

1. **Accès Immédiat :** L'application est utilisable dès son premier lancement. Aucun compte à créer, aucun mot de passe à retenir. Le compte est généré automatiquement et lié à l'appareil.
2. **Contrôle Total de l'Identité :** L'identité de l'utilisateur est matérialisée par une "Clé Secrète" unique. Seul l'utilisateur peut la sauvegarder et la restaurer, lui garantissant un contrôle total sur son compte et ses données.
3. **Connexions Basées sur la Confiance :** Fini les annuaires publics et la recherche par pseudo. Pour se connecter, les utilisateurs s'échangent des codes d'invitation uniques, à usage unique et à durée de vie limitée.
4. **Indépendance et Flexibilité :** L'architecture est découplée. L'application client communique avec une API "maison", la rendant indépendante de la logique interne du backend.

## **Fonctionnalités Clés**

### **Gestion de Compte**

- **Création Automatique :** Compte généré localement au premier lancement.
- **Profil Personnalisable :** Choix d'un pseudo public unique après la création.
- **Synchronisation :** Possibilité d’installer sur plusieurs plateformes et de synchroniser le contenu (Attention, la synchronisation ne se fait que si l’appareil à synchroniser est connecté).

### **Système d'Invitations**

- **Codes Uniques :** Génération de codes d'invitation courts et à usage unique.
- **Connexion Mutuelle :** Lorsqu'un code est utilisé, un contact est créé dans les deux sens entre le créateur de l'invitation et celui qui l'accepte.

### **Communication**

- **Messages Rapides :** Envoi d'un "Plop" (ou message par défaut personnalisé) d'un simple appui.
- **Messages contextuels :** Un appui long permet de choisir un message dans une liste personnalisable.
- **Modération :** Possibilité de mettre en sourdine un contact pour ne plus recevoir ses notifications.

### **Intégration API (Webhooks)**

- **Si j’ai le temps.**

## **Cas d'Utilisation**

Plop est conçu pour plusieurs scénarios :

- **Pour les Particuliers et les Familles :** Un canal de communication simple et privé pour la famille ou un groupe d'amis proches, pour se notifier rapidement ("J'arrive", "Appelle-moi") sans le bruit des messageries traditionnelles.
- **Pour les Petites Équipes :** Un système de "pager" moderne pour des notifications simples et rapides au sein d'une équipe ("Déploiement terminé", "Réunion dans 5 min").
- **Pour les Développeurs et Power-Users :** Un hub de notification personnel et centralisé. Avec l’integration API, un développeur pourrait recevoir des alertes de ses serveurs, des notifications de builds de son intégration continue (CI/CD), des alertes de monitoring, ou tout autre événement programmable, directement dans une seule application.

## **Stack Technique**

- **Application Client :** Flutter (Android, Linux, Windows, macOS) et iOS dès que j’ai les fonds pour.
- **Backend :** API REST

Soutenir le développement : <https://buymeacoffee.com/antoineo>

--------

# **Plop - Minimalist Communication App**

**A minimalist, secure, and cross-platform communication application based on a system of private and temporary invitations.**

Plop reinvents how we connect by removing common frictions (registration, passwords, searching for public contacts) to focus on the essential: fast and private communication between people who already know each other. Clearly inspired by the Yo! app.

## **Project Goal**

The goal of Plop is to provide an ultra-fast notification tool that respects privacy and gives control back to the user. The project's philosophy is based on four pillars:

1. **Immediate Access:** The application is usable from the very first launch. No account to create, no password to remember. The account is generated automatically and linked to the device.
2. **Total Identity Control:** The user's identity is embodied by a unique "Secret Key." Only the user can save and restore it, guaranteeing them complete control over their account and data.
3. **Trust-Based Connections:** No more public directories or searching by username. to connect, users exchange unique, single-use invitation codes with a limited lifespan.
4. **Independence and Flexibility:** The architecture is decoupled. The client application communicates with a "homemade" API, making it independent of the backend's internal logic.

## **Key Features**

### **Account Management**

- **Automatic Creation:** The account is generated locally on the first launch.
- **Customizable Profile:** Choose a unique public username after creation.
- **Synchronization:** Ability to install on multiple platforms and synchronize content (Note: synchronization only occurs if the device to be synced is connected).

### **Invitation System**

- **Unique Codes:** Generation of short, single-use invitation codes.
- **Mutual Connection:** When a code is used, a mutual contact is created between the invitation's creator and the person who accepts it.

### **Communication**

- **Quick Messages:** Send a "Plop" (or a custom default message) with a single tap.
- **Contextual Messages:** A long press allows you to choose a message from a customizable list.
- **Moderation:** Ability to mute a contact to stop receiving their notifications.

### **API Integration (Webhooks)**

- **If I have time.**

## **Use Cases**

Plop is designed for several scenarios:

- **For Individuals and Families:** A simple and private communication channel for family or a close group of friends, for quick notifications ("I'm on my way," "Call me") without the noise of traditional messaging apps.
- **For Small Teams:** A modern "pager" system for simple and fast notifications within a team ("Deployment finished," "Meeting in 5 mins").
- **For Developers and Power-Users:** A personal and centralized notification hub. With API integration, a developer could receive alerts from their servers, build notifications from their continuous integration (CI/CD), monitoring alerts, or any other programmable event, directly in a single application.

## **Tech Stack**

- **Client Application:** Flutter (Android, Linux, Windows, macOS) and iOS as soon as I have the funds.
- **Backend:** REST API

Support the development: <https://buymeacoffee.com/antoineo>

--------

# **Plop - Minimalistische Kommunikations-App**

**Eine minimalistische, sichere und plattformübergreifende Kommunikations-App, die auf einem System privater und temporärer Einladungen basiert.**

Plop erfindet die Art und Weise, wie man sich verbindet, neu, indem es die üblichen Hürden (Registrierung, Passwort, Suche nach öffentlichen Kontakten) beseitigt, um sich auf das Wesentliche zu konzentrieren: eine schnelle und private Kommunikation zwischen Personen, die sich bereits kennen. Klar inspiriert von der Yo!-App.

## **Projektziel**

Das Ziel von Plop ist es, ein ultraschnelles Benachrichtigungstool bereitzustellen, das die Privatsphäre respektiert und dem Benutzer die Kontrolle zurückgibt. Die Philosophie des Projekts basiert auf vier Säulen:

1. **Sofortiger Zugriff:** Die Anwendung ist ab dem ersten Start nutzbar. Kein Konto erstellen, kein Passwort merken. Das Konto wird automatisch generiert und mit dem Gerät verknüpft.
2. **Vollständige Kontrolle über die Identität:** Die Identität des Benutzers wird durch einen einzigartigen "Geheimschlüssel" verkörpert. Nur der Benutzer kann ihn speichern und wiederherstellen, was ihm die volle Kontrolle über sein Konto und seine Daten garantiert.
3. **Vertrauensbasierte Verbindungen:** Schluss mit öffentlichen Verzeichnissen und der Suche nach Benutzernamen. Um sich zu verbinden, tauschen die Benutzer einmalig verwendbare Einladungscodes mit begrenzter Lebensdauer aus.
4. **Unabhängigkeit und Flexibilität:** Die Architektur ist entkoppelt. Die Client-Anwendung kommuniziert mit einer "hausgemachten" API, was sie von der internen Logik des Backends unabhängig macht.

## **Hauptfunktionen**

### **Kontoverwaltung**

- **Automatische Erstellung:** Das Konto wird beim ersten Start lokal generiert.
- **Anpassbares Profil:** Wahl eines einzigartigen öffentlichen Benutzernamens nach der Erstellung.
- **Synchronisierung:** Möglichkeit, die App auf mehreren Plattformen zu installieren und Inhalte zu synchronisieren (Achtung, die Synchronisierung erfolgt nur, wenn das zu synchronisierende Gerät verbunden ist).

### **Einladungssystem**

- **Einzigartige Codes:** Generierung von kurzen, einmalig verwendbaren Einladungscodes.
- **Gegenseitige Verbindung:** Wenn ein Code verwendet wird, wird in beide Richtungen ein Kontakt zwischen dem Ersteller der Einladung und demjenigen, der sie annimmt, erstellt.

### **Kommunikation**

- **Schnelle Nachrichten:** Senden eines "Plop" (oder einer benutzerdefinierten Standardnachricht) mit einem einzigen Fingertipp.
- **Kontextbezogene Nachrichten:** Ein langes Drücken ermöglicht die Auswahl einer Nachricht aus einer anpassbaren Liste.
- **Moderation:** Möglichkeit, einen Kontakt stummzuschalten, um keine Benachrichtigungen mehr von ihm zu erhalten.

### **API-Integration (Webhooks)**

- **Wenn ich Zeit dafür habe.**

## **Anwendungsfälle**

Plop ist für verschiedene Szenarien konzipiert:

- **Für Privatpersonen und Familien:** Ein einfacher und privater Kommunikationskanal für die Familie oder eine enge Freundesgruppe, um sich schnell zu benachrichtigen ("Ich komme", "Ruf mich an"), ohne den Lärm herkömmlicher Messenger.
- **Für kleine Teams:** Ein modernes "Pager"-System für einfache und schnelle Benachrichtigungen innerhalb eines Teams ("Deployment abgeschlossen", "Meeting in 5 Min.").
- **Für Entwickler und Power-User:** Ein persönlicher und zentraler Benachrichtigungs-Hub. Mit der API-Integration könnte ein Entwickler Warnungen von seinen Servern, Build-Benachrichtigungen seiner Continuous Integration (CI/CD), Monitoring-Alarme oder jedes andere programmierbare Ereignis direkt in einer einzigen Anwendung erhalten.

## **Technischer Stack**

- **Client-Anwendung:** Flutter (Android, Linux, Windows, macOS) und iOS, sobald ich die Mittel dafür habe.
- **Backend:** REST-API

Unterstütze die Entwicklung: <https://buymeacoffee.com/antoineo>


--------


# **Plop - Aplicación de Comunicación Minimalista**

**Una aplicación de comunicación minimalista, segura y multiplataforma, basada en un sistema de invitaciones privadas y temporales.**

Plop reinventa la forma de conectarse eliminando las fricciones habituales (registro, contraseña, búsqueda de contactos públicos) para centrarse en lo esencial: una comunicación rápida y privada entre personas que ya se conocen. Claramente inspirada en la aplicación Yo!

## **Objetivo del Proyecto**

El objetivo de Plop es proporcionar una herramienta de notificación ultrarrápida que respeta la privacidad y devuelve el control al usuario. La filosofía del proyecto se basa en cuatro pilares:

1. **Acceso Inmediato:** La aplicación se puede utilizar desde el primer momento. Sin cuentas que crear ni contraseñas que recordar. La cuenta se genera automáticamente y se vincula al dispositivo.
2. **Control Total de la Identidad:** La identidad del usuario se materializa en una "Clave Secreta" única. Solo el usuario puede guardarla y restaurarla, garantizándole un control total sobre su cuenta y sus datos.
3. **Conexiones Basadas en la Confianza:** Se acabaron los directorios públicos y la búsqueda por apodo. Para conectarse, los usuarios intercambian códigos de invitación únicos, de un solo uso y con una duración limitada.
4. **Independencia y Flexibilidad:** La arquitectura está desacoplada. La aplicación cliente se comunica con una API "propia", lo que la hace independiente de la lógica interna del backend.

## **Funcionalidades Clave**

### **Gestión de la Cuenta**

- **Creación Automática:** La cuenta se genera localmente en el primer uso.
- **Perfil Personalizable:** Elección de un apodo público único después de la creación.
- **Sincronización:** Posibilidad de instalar en varias plataformas y sincronizar el contenido (Atención: la sincronización solo se realiza si el dispositivo a sincronizar está conectado).

### **Sistema de Invitaciones**

- **Códigos Únicos:** Generación de códigos de invitación cortos y de un solo uso.
- **Conexión Mutua:** Cuando se utiliza un código, se crea un contacto en ambos sentidos entre el creador de la invitación y quien la acepta.

### **Comunicación**

- **Mensajes Rápidos:** Envío de un "Plop" (o un mensaje predeterminado personalizado) con una simple pulsación.
- **Mensajes contextuales:** Una pulsación larga permite elegir un mensaje de una lista personalizable.
- **Moderación:** Posibilidad de silenciar a un contacto para no recibir sus notificaciones.

### **Integración API (Webhooks)**

- **Si tengo tiempo.**

## **Casos de Uso**

Plop está diseñado para varios escenarios:

- **Para Particulares y Familias:** Un canal de comunicación simple y privado para la familia o un grupo de amigos cercanos, para notificarse rápidamente ("Estoy llegando", "Llámame") sin el ruido de las aplicaciones de mensajería tradicionales.
- **Para Pequeños Equipos:** Un sistema de "pager" moderno para notificaciones simples y rápidas dentro de un equipo ("Despliegue terminado", "Reunión en 5 min").
- **Para Desarrolladores y Power-Users:** Un centro de notificaciones personal y centralizado. Con la integración de la API, un desarrollador podría recibir alertas de sus servidores, notificaciones de builds de su integración continua (CI/CD), alertas de monitorización o cualquier otro evento programable, directamente en una sola aplicación.

## **Stack Técnico**

- **Aplicación Cliente:** Flutter (Android, Linux, Windows, macOS) e iOS en cuanto tenga los fondos.
- **Backend:** API REST

Apoya el desarrollo: <https://buymeacoffee.com/antoineo>


--------

# **Plop - Applicazione di Comunicazione Minimalista**

**Un'applicazione di comunicazione minimalista, sicura e multipiattaforma, basata su un sistema di inviti privati e temporanei.**

Plop reinventa il modo di connettersi eliminando le frizioni abituali (registrazione, password, ricerca di contatti pubblici) per concentrarsi sull'essenziale: una comunicazione rapida e privata tra persone che già si conoscono. Chiaramente ispirata all'app Yo!

## **Obiettivo del Progetto**

L'obiettivo di Plop è fornire uno strumento di notifica ultra-rapido che rispetta la privacy e restituisce il controllo all'utente. La filosofia del progetto si basa su quattro pilastri:

1. **Accesso Immediato:** L'applicazione è utilizzabile fin dal primo avvio. Nessun account da creare, nessuna password da ricordare. L'account viene generato automaticamente e collegato al dispositivo.
2. **Controllo Totale dell'Identità:** L'identità dell'utente è materializzata da una "Chiave Segreta" unica. Solo l'utente può salvarla e ripristinarla, garantendogli un controllo totale sul suo account e sui suoi dati.
3. **Connessioni Basate sulla Fiducia:** Basta con le directory pubbliche e la ricerca per nickname. Per connettersi, gli utenti si scambiano codici di invito unici, monouso e a durata limitata.
4. **Indipendenza e Flessibilità:** L'architettura è disaccoppiata. L'applicazione client comunica con un'API "fatta in casa", rendendola indipendente dalla logica interna del backend.

## **Funzionalità Chiave**

### **Gestione dell'Account**

- **Creazione Automatica:** L'account viene generato localmente al primo avvio.
- **Profilo Personalizzabile:** Scelta di un nickname pubblico unico dopo la creazione.
- **Sincronizzazione:** Possibilità di installare su più piattaforme e di sincronizzare i contenuti (Attenzione: la sincronizzazione avviene solo se il dispositivo da sincronizzare è connesso).

### **Sistema di Inviti**

- **Codici Unici:** Generazione di codici di invito brevi e monouso.
- **Connessione Reciproca:** Quando un codice viene utilizzato, viene creato un contatto in entrambe le direzioni tra il creatore dell'invito e chi lo accetta.

### **Comunicazione**

- **Messaggi Rapidi:** Invio di un "Plop" (o di un messaggio predefinito personalizzato) con un singolo tocco.
- **Messaggi contestuali:** Una pressione prolungata permette di scegliere un messaggio da una lista personalizzabile.
- **Moderazione:** Possibilità di silenziare un contatto per non ricevere più le sue notifiche.

### **Integrazione API (Webhooks)**

- **Se avrò tempo.**

## **Casi d'Uso**

Plop è progettato per diversi scenari:

- **Per Privati e Famiglie:** Un canale di comunicazione semplice e privato per la famiglia o un gruppo di amici stretti, per notificarsi rapidamente ("Sto arrivando", "Chiamami") senza il rumore delle tradizionali app di messaggistica.
- **Per Piccoli Team:** Un sistema di "pager" moderno per notifiche semplici e veloci all'interno di un team ("Deployment completato", "Riunione tra 5 min").
- **Per Sviluppatori e Power-User:** Un hub di notifiche personale e centralizzato. Con l'integrazione API, uno sviluppatore potrebbe ricevere avvisi dai propri server, notifiche di build dalla loro integrazione continua (CI/CD), allarmi di monitoraggio, o qualsiasi altro evento programmabile, direttamente in un'unica applicazione.

## **Stack Tecnologico**

- **Applicazione Client:** Flutter (Android, Linux, Windows, macOS) e iOS non appena avrò i fondi.
- **Backend:** API REST

Sostieni lo sviluppo: <https://buymeacoffee.com/antoineo>