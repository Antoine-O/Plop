

package main

import (
    "strconv"
    "context"
	"crypto/rand"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"sync"
	"time"
	"fmt"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/rs/cors"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

var firebaseApp *firebase.App
var userDeviceTokens = make(map[string][]string) // La valeur est maintenant une liste de tokens
var userDeviceTokensMutex = &sync.Mutex{}

// --- Structures ---

type Message struct {
	Type       string      `json:"type"`
	To         string      `json:"to,omitempty"`
	From       string      `json:"from,omitempty"`
	Payload    interface{} `json:"payload"`
	IsDefault  bool        `json:"isDefault,omitempty"`
	SourceConn *websocket.Conn `json:"-"` // Champ interne pour ne pas renvoyer le message à l'expéditeur
}

type Invitation struct {
	Code          string
	CreatorUserID string
	CreatorPseudo string
	ExpiresAt     time.Time
}

type SyncCode struct {
	Code      string
	UserID    string
	ExpiresAt time.Time
}

// --- Global Variables & Constants ---

const invitationValidityMinutes = 10

const messageCooldown = 0 * time.Second // NOUVEAU: Temps de rechargement de 5 secondes


const pendingMessagesFile = "pending_messages.json"
const userDeviceTokensFile = "user_device_tokens.json"
const invitationsFile = "invitations.json"

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

var clients = make(map[string]map[*websocket.Conn]bool)
var clientsMutex = &sync.Mutex{}

var userLastMessageTime = make(map[string]time.Time) // NOUVEAU: Pour gérer le cooldown
var userLastMessageMutex = &sync.Mutex{}

var invitations = make(map[string]Invitation)
var invitationsMutex = &sync.Mutex{}

var userPseudos = make(map[string]string)
var userPseudosMutex = &sync.Mutex{}

var syncCodes = make(map[string]SyncCode)
var syncCodesMutex = &sync.Mutex{}

var pendingMessages = make(map[string]map[string]Message) // map[recipientId][senderId]Message
var pendingMessagesMutex = &sync.Mutex{}

// --- Logger ---

func debugLog(format string, v ...interface{}) {
	if os.Getenv("DEBUG") != "" {
		log.Printf("[DEBUG] "+format, v...)
	}
}

func initializeFirebase(){
    ctx := context.Background()
    opt := option.WithCredentialsFile("serviceAccountKey.json") // Le fichier que vous avez téléchargé
    var err error
    firebaseApp, err = firebase.NewApp(ctx, nil, opt)
    if err != nil {
        log.Fatalf("error initializing app: %v\n", err)
    }
}


// --- Main Function ---

func main() {
    initializeFirebase();
    loadPendingMessagesFromFile()
	loadUserDeviceTokensFromFile()
	loadInvitationsFromFile()
	go cleanupExpiredInvitations()
	go cleanupExpiredSyncCodes()

	mux := http.NewServeMux()
	mux.HandleFunc("/connect", handleWebSocket)
	mux.HandleFunc("/invitations/create", handleCreateInvitation)
	mux.HandleFunc("/invitations/use", handleUseInvitation)
	mux.HandleFunc("/users/generate-id", handleGenerateUserID)
	mux.HandleFunc("/users/get-pseudos", handleGetPseudos)
	mux.HandleFunc("/sync/create", handleCreateSyncCode)
	mux.HandleFunc("/sync/use", handleUseSyncCode)
	mux.HandleFunc("/ping", handlePing)
	mux.HandleFunc("/users/update-token", handleUpdateToken)

	handler := cors.New(cors.Options{
		AllowedOrigins: []string{"*"},
		AllowedMethods: []string{"GET", "POST", "OPTIONS"},
		AllowedHeaders: []string{"Content-Type"},
	}).Handler(mux)

	log.Println("Serveur démarré sur http://localhost:8080")
	if err := http.ListenAndServe(":8080", handler); err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}

// --- Handlers ---

func handleGenerateUserID(w http.ResponseWriter, r *http.Request) {
	id := uuid.New()
	debugLog("Génération d'un nouvel UserID: %s", id.String())
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"userId": id.String()})
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	userId := r.URL.Query().Get("userId")
	pseudo := r.URL.Query().Get("pseudo")
	if userId == "" {
		http.Error(w, "userId manquant", http.StatusBadRequest)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Erreur WebSocket: %v", err)
		return
	}
	defer conn.Close()

    debugLog("Utilisateur connection: %s (%s)", userId, pseudo)
	if pseudo != "" {
		userPseudosMutex.Lock()
		userPseudos[userId] = pseudo
		userPseudosMutex.Unlock()
		debugLog("Utilisateur connecté: %s (%s)", userId, pseudo)
	}

	clientsMutex.Lock()
	if clients[userId] == nil {
		clients[userId] = make(map[*websocket.Conn]bool)
	}
	hasOtherDevices := len(clients[userId]) > 0
	clients[userId][conn] = true
	clientsMutex.Unlock()

    go sendPendingMessages(userId, conn)

    // Si d'autres appareils sont déjà connectés, on leur demande la dernière version des données.
	if hasOtherDevices {
		debugLog("Nouvel appareil détecté pour %s. Demande de synchronisation...", userId)
		broadcastMessageToUser(userId, Message{Type: "sync_request"}, conn)
	}

	listenForMessages(conn, userId)

	clientsMutex.Lock()
	delete(clients[userId], conn)
	if len(clients[userId]) == 0 {
		delete(clients, userId)
	}
	clientsMutex.Unlock()
	debugLog("Utilisateur déconnecté: %s", userId)
}

func handleCreateInvitation(w http.ResponseWriter, r *http.Request) {
	creatorID := r.URL.Query().Get("userId")
	creatorPseudo := r.URL.Query().Get("pseudo")
	if creatorID == "" || creatorPseudo == "" {
		http.Error(w, "'userId' et 'pseudo' sont requis", http.StatusBadRequest)
		return
	}
	code := generateRandomCode(6)
	invitation := Invitation{
		Code:          code, CreatorUserID: creatorID, CreatorPseudo: creatorPseudo,
		ExpiresAt: time.Now().Add(invitationValidityMinutes * time.Minute),
	}
	invitationsMutex.Lock()
	invitations[code] = invitation
	invitationsMutex.Unlock()
	saveInvitationsToFile()
	debugLog("Code '%s' créé pour %s (%s)", code, creatorID, creatorPseudo)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"code": code, "validityMinutes": invitationValidityMinutes})
}

func handleUseInvitation(w http.ResponseWriter, r *http.Request) {
	var requestBody struct { Code, UserID, Pseudo string }
	if err := json.NewDecoder(r.Body).Decode(&requestBody); err != nil {
		http.Error(w, "Corps de requête invalide", http.StatusBadRequest)
		return
	}
	code := requestBody.Code
	invitationsMutex.Lock()
	invitation, found := invitations[code]
	if found {
		delete(invitations, code)
	}
	invitationsMutex.Unlock()
		if found {
    		saveInvitationsToFile()
    	}
	if !found || time.Now().After(invitation.ExpiresAt) {
		http.Error(w, "Code invalide ou expiré", http.StatusNotFound)
		return
	}
	notificationPayload := map[string]string{"userId": requestBody.UserID, "pseudo": requestBody.Pseudo}
	notificationMsg := Message{Type: "new_contact", Payload: notificationPayload}
	broadcastMessageToUser(invitation.CreatorUserID, notificationMsg, nil)
	debugLog("Code '%s' utilisé, mise en relation de %s avec %s", code, requestBody.UserID, invitation.CreatorUserID)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"userId": invitation.CreatorUserID, "pseudo": invitation.CreatorPseudo})
}

func handleGetPseudos(w http.ResponseWriter, r *http.Request) {
	var requestBody struct { UserIDs []string `json:"userIds"` }
	if err := json.NewDecoder(r.Body).Decode(&requestBody); err != nil {
		http.Error(w, "Corps de requête invalide", http.StatusBadRequest)
		return
	}
	responsePseudos := make(map[string]string)
	userPseudosMutex.Lock()
	for _, id := range requestBody.UserIDs {
		if pseudo, found := userPseudos[id]; found {
			responsePseudos[id] = pseudo
		}
	}
	userPseudosMutex.Unlock()
	debugLog("Synchronisation des pseudos pour %d ID(s)", len(requestBody.UserIDs))
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(responsePseudos)
}

func handleCreateSyncCode(w http.ResponseWriter, r *http.Request) {
	userId := r.URL.Query().Get("userId")
	if userId == "" {
		http.Error(w, "userId requis", http.StatusBadRequest)
		return
	}
	code := generateRandomCode(6)
	syncCode := SyncCode{Code: code, UserID: userId, ExpiresAt: time.Now().Add(5 * time.Minute)}

	syncCodesMutex.Lock()
	syncCodes[code] = syncCode
	syncCodesMutex.Unlock()

	debugLog("Code de synchro '%s' créé pour %s", code, userId)
	json.NewEncoder(w).Encode(map[string]string{"code": code})
}
func handleUseSyncCode(w http.ResponseWriter, r *http.Request) {
	var requestBody struct{ Code string `json:"code"` }
	if err := json.NewDecoder(r.Body).Decode(&requestBody); err != nil {
		http.Error(w, "Corps de requête invalide", http.StatusBadRequest)
		return
	}

	syncCodesMutex.Lock()
	syncData, found := syncCodes[requestBody.Code]
	if found {
		delete(syncCodes, requestBody.Code)
	}
	syncCodesMutex.Unlock()

	if !found || time.Now().After(syncData.ExpiresAt) {
		http.Error(w, "Code de synchro invalide ou expiré", http.StatusNotFound)
		return
	}

	debugLog("Code de synchro '%s' validé. Envoi de 'sync_request' à l'utilisateur %s", requestBody.Code, syncData.UserID)
	broadcastMessageToUser(syncData.UserID, Message{Type: "sync_request"}, nil)

	userPseudosMutex.Lock()
	pseudo := userPseudos[syncData.UserID]
	userPseudosMutex.Unlock()
    debugLog("Pseudo récupéré pour la synchro : %s", pseudo)

	json.NewEncoder(w).Encode(map[string]string{
		"userId": syncData.UserID,
		"pseudo": pseudo,
	})
}

// La nouvelle fonction handler
func handleUpdateToken(w http.ResponseWriter, r *http.Request) {
    debugLog("handleUpdateToken")
    var requestBody struct {
        UserID string `json:"userId"`
        Token  string `json:"token"`
    }
    if err := json.NewDecoder(r.Body).Decode(&requestBody); err != nil {
        http.Error(w, "Corps de requête invalide", http.StatusBadRequest)
        return
    }

    if requestBody.UserID == "" || requestBody.Token == "" {
        http.Error(w, "userId et token sont requis", http.StatusBadRequest)
        return
    }
    debugLog("handleUpdateToken  %s %s", requestBody.UserID, requestBody.Token)


    // Récupère la liste existante de tokens pour cet utilisateur
    userDeviceTokensMutex.Lock()
    tokens := userDeviceTokens[requestBody.UserID]

    // Vérifie si le token est déjà dans la liste pour éviter les doublons
    tokenExists := false
    for _, t := range tokens {
        if t == requestBody.Token {
            tokenExists = true
            break
        }
    }

    // Si le token n'existe pas, on l'ajoute
    if !tokenExists {
        userDeviceTokens[requestBody.UserID] = append(tokens, requestBody.Token)
        debugLog("Nouveau token FCM ajouté pour l'utilisateur %s", requestBody.UserID)
		userDeviceTokensMutex.Unlock()
		saveUserDeviceTokensToFile()
    } else {
		userDeviceTokensMutex.Unlock()
        debugLog("Token FCM déjà existant pour l'utilisateur %s", requestBody.UserID)
    }

    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(map[string]bool{"success": true})
}

// --- WebSocket Message Logic ---

// CORRECTION MAJEURE: La logique de routage est maintenant plus claire.
func listenForMessages(conn *websocket.Conn, fromUserId string) {
	for {
		_, p, err := conn.ReadMessage()
		if err != nil { break }
		var msg Message
		if err := json.Unmarshal(p, &msg); err != nil { continue }

		msg.From = fromUserId

		debugLog("Message reçu de %s, type: %s", fromUserId, msg.Type)

		switch msg.Type {
		case "plop":
			userLastMessageMutex.Lock()
			lastTime, found := userLastMessageTime[fromUserId]
			// Vérifie si l'utilisateur peut envoyer un message
			if !found || time.Since(lastTime) > messageCooldown {
				userLastMessageTime[fromUserId] = time.Now()
				userLastMessageMutex.Unlock()
				payload := map[string]string{"recipientId":msg.To,"From": "server"}
				ackMessage := Message{Type: "message_ack",Payload:payload}
                				if err := conn.WriteJSON(ackMessage); err != nil {
                					debugLog("Impossible d'envoyer l'ack à %s: %v", fromUserId, err)
                				}
				sendDirectMessage(msg)
			} else {
				userLastMessageMutex.Unlock()
				debugLog("Cooldown pour %s. Message ignoré.", fromUserId)
			}
		case "sync_data_broadcast":
			// Les données de synchro sont diffusées à tous les appareils de l'expéditeur.
			// On exclut la source pour éviter un écho inutile.
			debugLog("Données de synchro reçues de %s. Relais en cours...", fromUserId)
			broadcastMessageToUser(fromUserId, msg, conn)
		case "ping":
            debugLog("Ping de %s", fromUserId)
		default:
			debugLog("Type de message inconnu: %s", msg.Type)
		}
	}
}

// CORRECTION: Nouvelle fonction pour diffuser un message à tous les appareils d'un utilisateur.
// L'argument 'excludeConn' permet d'éviter de renvoyer un message à l'expéditeur.
func broadcastMessageToUser(userID string, msg Message, excludeConn *websocket.Conn) {
    clientsMutex.Lock()
    defer clientsMutex.Unlock()

    if conns, found := clients[userID]; found {
        debugLog("Diffusion du message de type '%s' à %d appareil(s) pour l'utilisateur %s", msg.Type, len(conns), userID)
        for conn := range conns {
            if conn != excludeConn {
                err := conn.WriteJSON(msg)
                if err != nil {
                    debugLog("Erreur d'envoi (broadcast) à %s: %v", userID, err)
                } else {
                    debugLog("Message envoyé avec succès à une connexion pour %s", userID)
                }
            }
        }
    } else {
        debugLog("Aucun appareil trouvé pour l'utilisateur %s", userID)
    }
}

// CORRECTION: Nouvelle fonction pour envoyer un message direct à un utilisateur.
func sendDirectMessage(msg Message) {
  if msg.To == "" {
        // On log l'erreur pour savoir pourquoi le message n'a pas été envoyé.
        // Inclure msg.From est utile pour le débogage.
        debugLog("Arrêt de sendDirectMessage: msg.To est vide. Message de 'from': %s", msg.From)
        // 'return' arrête l'exécution de la fonction ici.
        return
    }
    clientsMutex.Lock()
    recipientConns, found := clients[msg.To]
    clientsMutex.Unlock() // Libérer le mutex plus tôt

    if found && len(recipientConns) > 0 {
        debugLog("Envoi d'un message direct de %s à %s", msg.From, msg.To)
        clientsMutex.Lock() // Re-verrouiller pour accéder à la map
        for conn := range recipientConns {
            err := conn.WriteJSON(msg)
            if err != nil {
                debugLog("Erreur d'envoi (direct) de %s à %s : %v", msg.From, msg.To, err)
            }
        }
        clientsMutex.Unlock()
    } else {
        debugLog("Envoi d'un message direct de %s à %s - Destinataire non trouvé", msg.From, msg.To)
        pendingMessagesMutex.Lock()
        if _, ok := pendingMessages[msg.To]; !ok {
            pendingMessages[msg.To] = make(map[string]Message)
        }
        // Écrase le message précédent du même expéditeur
        pendingMessages[msg.To][msg.From] = msg
        debugLog("Message de %s pour %s stocké pour livraison ultérieure.", msg.From, msg.To)
        pendingMessagesMutex.Unlock()

        // Sauvegarde la mise à jour dans le fichier
        savePendingMessagesToFile()
        // L'UTILISATEUR N'EST PAS CONNECTÉ ---
        sendDirectMessageThroughFirebase(msg)
    }
}


func sendDirectMessageThroughFirebase(msg Message) {

    debugLog("Destinataire %s non connecté. Tentative d'envoi de notification push.", msg.To)

    // Étape A: Récupérer la LISTE des tokens de l'appareil
    userDeviceTokensMutex.Lock()
    deviceTokens, tokenFound := userDeviceTokens[msg.To]
    userDeviceTokensMutex.Unlock()

    if !tokenFound || len(deviceTokens) == 0 {
        debugLog("Aucun token FCM trouvé pour l'utilisateur %s", msg.To)
        return
    }

    // Étape B: Construire le message
    ctx := context.Background()
    client, err := firebaseApp.Messaging(ctx)
    if err != nil {
        log.Printf("Erreur lors de l'obtention du client Messaging: %v", err)
        return
    }

    // Récupérer le pseudo de l'expéditeur
    userPseudosMutex.Lock()
    senderPseudo := userPseudos[msg.From]
    userPseudosMutex.Unlock()
    if senderPseudo == "" {
        senderPseudo = "Quelqu'un"
    }
    var notificationBody string
    switch p := msg.Payload.(type) {
    case map[string]interface{}:
        // CAS 1 : Le payload est bien un objet JSON (une map)
        // On cherche la clé "text" à l'intérieur.
        if text, ok := p["text"].(string); ok {
            notificationBody = text
        } else {
            notificationBody = "Vous avez reçu un plop !" // Message par défaut si la clé "text" manque
        }
    case string:
        // CAS 2 : Le payload est une simple chaîne de caractères
        notificationBody = p
    default:
        // CAS 3 : Pour tous les autres types de payload, on met un message par défaut.
        notificationBody = "Vous avez reçu une notification."
        debugLog("Type de payload inattendu: %T", p)
    }

// Étape C: Envoyer via Send
  var tokensToRemove []string

    // On parcourt chaque token individuellement
    for _, token := range deviceTokens {

        // On crée un message pour un seul token
        message := &messaging.Message{
            Notification: &messaging.Notification{
                Title: senderPseudo,
                Body:  notificationBody,
            },
            Data: map[string]string{
                "senderId": msg.From,
                "payload": notificationBody,
                "isDefault": strconv.FormatBool(msg.IsDefault),
            },
            // --- L'AJOUT IMPORTANT EST ICI ---
            Android: &messaging.AndroidConfig{
                Notification: &messaging.AndroidNotification{
                    // On spécifie le canal pour chaque message individuel
                    ChannelID: "plop_channel_id",
                    Icon: "icon",
                },
            },

            // --- NOUVEAU : Configuration pour iOS et macOS ---
            APNS: &messaging.APNSConfig{
                Payload: &messaging.APNSPayload{
                    Aps: &messaging.Aps{
                        // Le contenu de l'alerte
                        Alert: &messaging.ApsAlert{
                            Title: senderPseudo,
                            Body:  notificationBody,
                        },
                        // Pour mettre à jour le badge sur l'icône de l'app
                        Badge: intPtr(1),
                        // Pour spécifier le son personnalisé !
                        Sound: "plop.aiff", // Doit correspondre au nom du fichier dans vos assets Flutter
                    },
                },
            },
            Token: token, // On assigne le token de l'itération actuelle
        }

        // On envoie le message avec client.Send()
        _, err := client.Send(ctx, message)

        // On gère l'erreur pour cet envoi spécifique
        if err != nil {
            log.Printf("Échec de l'envoi au token %s: %v", token, err)
            // On vérifie si l'erreur est due à un token invalide
            if messaging.IsUnregistered(err) || messaging.IsInvalidArgument(err) {
                debugLog("Token invalide détecté: %s. Planifié pour suppression.", token)
                tokensToRemove = append(tokensToRemove, token)
            }
        }else{
            debugLog("Message envoyé avec succès à %s", token);
        }
    }

    // On nettoie les tokens invalides après la boucle
    if len(tokensToRemove) > 0 {
        removeInvalidTokens(msg.To, tokensToRemove)
    }

    // Étape C: Envoyer via SendMulticast
    /*
     // Utiliser un MulticastMessage pour envoyer à plusieurs tokens
    multicastMessage := &messaging.MulticastMessage{
        Notification: &messaging.Notification{
            Title: senderPseudo,
            Body:  notificationBody,
        },
        Tokens: deviceTokens, // La liste de tous les tokens de l'utilisateur
    } */
    /* response, err := client.SendMulticast(ctx, multicastMessage)
    if err != nil {
        log.Printf("Erreur lors de l'envoi multicast: %v", err)
        return
    }

    debugLog("Rapport d'envoi multicast: %d succès, %d échecs", response.SuccessCount, response.FailureCount)

    // --- Étape D: Analyser la réponse et nettoyer les tokens invalides ---
    if response.FailureCount > 0 {
    var tokensToRemove []string
    for idx, resp := range response.Responses {
        if !resp.Success {
            // Le token à l'index `idx` a échoué. Vérifions pourquoi.
            if messaging.IsUnregistered(resp.Error) || messaging.IsInvalidArgument(resp.Error) {
            // Le token est invalide (app désinstallée, etc.)
            invalidToken := deviceTokens[idx]
            debugLog("Token invalide détecté (%v): %s. Planifié pour suppression.", resp.Error, invalidToken)
            tokensToRemove = append(tokensToRemove, invalidToken)
            }
        }
    } */

    if len(tokensToRemove) > 0 {
        // Ici, vous supprimez les tokens de votre base de données.
        // Simulons avec notre map.
        removeInvalidTokens(msg.To, tokensToRemove)
    }
}


// Fonction utilitaire pour le nettoyage (à placer dans votre fichier)
func removeInvalidTokens(userID string, tokensToRemove []string) {
    userDeviceTokensMutex.Lock()
    defer userDeviceTokensMutex.Unlock()

    if currentTokens, found := userDeviceTokens[userID]; found {
        var validTokens []string
        for _, token := range currentTokens {
            isInvalid := false
            for _, tokenToRemove := range tokensToRemove {
                if token == tokenToRemove {
                    isInvalid = true
                    break
                }
            }
            if !isInvalid {
                validTokens = append(validTokens, token)
            }
        }
        userDeviceTokens[userID] = validTokens
        debugLog("Nettoyage de %d token(s) invalide(s) pour l'utilisateur %s", len(tokensToRemove), userID)
        saveUserDeviceTokensToFile()
    }
}

// --- Utility Functions ---

func generateRandomCode(length int) string {
	const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789"
	b := make([]byte, length)
	if _, err := rand.Read(b); err != nil {
		log.Fatalf("Erreur lors de la génération du code aléatoire: %v", err)
	}
	for i := 0; i < length; i++ {
		b[i] = chars[int(b[i])%len(chars)]
	}
	return string(b)
}

func cleanupExpiredInvitations() {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()
	for range ticker.C {
		now := time.Now()
		invitationsMutex.Lock()
		deleted := false
		for code, inv := range invitations {
			if now.After(inv.ExpiresAt) {
			    deleted = true
				delete(invitations, code)
				debugLog("Code d'invitation expiré supprimé: %s", code)
			}
		}
		invitationsMutex.Unlock()
        if deleted {
            saveInvitationsToFile()
        }
	}
}

func cleanupExpiredSyncCodes() {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()
	for range ticker.C {
		now := time.Now()
		syncCodesMutex.Lock()
		for code, sc := range syncCodes {
			if now.After(sc.ExpiresAt) {
				delete(syncCodes, code)
				debugLog("Code de synchro expiré supprimé: %s", code)
			}
		}
		syncCodesMutex.Unlock()
	}
}


func handlePing(w http.ResponseWriter, r *http.Request) {
	// Affiche un message dans la console du serveur à chaque appel pour le suivi.
	log.Println("Requête reçue sur /ping")

	// Écrit la réponse "ping" dans le corps de la réponse HTTP.
	// Fprintf est une manière simple d'écrire du texte dans la réponse.
	fmt.Fprintf(w, "pong")
}

func intPtr(i int) *int {
     return &i
}


// --- Utility Functions --- (Ajoutez ces fonctions à la fin du fichier)

// NOUVEAU: Charge les messages en attente depuis le fichier JSON au démarrage.
func loadPendingMessagesFromFile() {
	pendingMessagesMutex.Lock()
	defer pendingMessagesMutex.Unlock()

	data, err := os.ReadFile(pendingMessagesFile)
	if err != nil {
		if os.IsNotExist(err) {
			debugLog("Aucun fichier de messages en attente ('%s') trouvé. Démarrage avec une liste vide.", pendingMessagesFile)
			return // Le fichier n'existe pas encore, c'est normal au premier lancement.
		}
		log.Printf("Erreur lors de la lecture du fichier de messages en attente : %v", err)
		return
	}

	if err := json.Unmarshal(data, &pendingMessages); err != nil {
		log.Printf("Erreur lors du démarshalling des messages en attente : %v", err)
	} else {
		debugLog("%d utilisateur(s) avec des messages en attente chargés depuis le fichier.", len(pendingMessages))
	}
}

// NOUVEAU: Sauvegarde la map des messages en attente dans le fichier JSON.
func savePendingMessagesToFile() {
	pendingMessagesMutex.Lock()
	defer pendingMessagesMutex.Unlock()

	data, err := json.MarshalIndent(pendingMessages, "", "  ")
	if err != nil {
		log.Printf("Erreur lors du marshalling des messages en attente : %v", err)
		return
	}

	if err := os.WriteFile(pendingMessagesFile, data, 0644); err != nil {
		log.Printf("Erreur lors de l'écriture dans le fichier de messages en attente : %v", err)
	}
}

// NOUVEAU: Vérifie et envoie les messages stockés à un utilisateur qui vient de se connecter.
func sendPendingMessages(userID string, conn *websocket.Conn) {
    pendingMessagesMutex.Lock()

    messagesForUser, found := pendingMessages[userID]
    if !found || len(messagesForUser) == 0 {
        pendingMessagesMutex.Unlock()
        return // Aucun message en attente pour cet utilisateur
    }

    debugLog("Envoi de %d message(s) en attente à l'utilisateur %s", len(messagesForUser), userID)

    // On envoie chaque message stocké
    for senderID, msg := range messagesForUser {
        if err := conn.WriteJSON(msg); err != nil {
            debugLog("Erreur lors de l'envoi du message en attente de %s à %s: %v", senderID, userID, err)
            // Si l'envoi échoue, on arrête et on ne supprime pas les messages pour réessayer plus tard.
            pendingMessagesMutex.Unlock()
            return
        }
    }

    // Tous les messages ont été envoyés avec succès, on peut nettoyer la map.
    delete(pendingMessages, userID)
    debugLog("Messages en attente pour %s envoyés et supprimés de la file d'attente.", userID)

    pendingMessagesMutex.Unlock()

    // On met à jour le fichier pour refléter que les messages ont été livrés.
    savePendingMessagesToFile()
}

// NOUVEAU: Charge les invitations depuis le fichier JSON.
func loadInvitationsFromFile() {
	invitationsMutex.Lock()
	defer invitationsMutex.Unlock()
	data, err := os.ReadFile(invitationsFile)
	if err != nil {
		if os.IsNotExist(err) {
			debugLog("Aucun fichier d'invitations ('%s') trouvé.", invitationsFile)
			return
		}
		log.Printf("Erreur lecture fichier invitations : %v", err)
		return
	}
	if err := json.Unmarshal(data, &invitations); err != nil {
		log.Printf("Erreur démarshalling invitations : %v", err)
	} else {
		debugLog("%d invitation(s) chargée(s) depuis le fichier.", len(invitations))
	}
}

// NOUVEAU: Sauvegarde les invitations dans le fichier JSON.
func saveInvitationsToFile() {
	invitationsMutex.Lock()
	defer invitationsMutex.Unlock()
	data, err := json.MarshalIndent(invitations, "", "  ")
	if err != nil {
		log.Printf("Erreur marshalling invitations : %v", err)
		return
	}
	if err := os.WriteFile(invitationsFile, data, 0644); err != nil {
		log.Printf("Erreur écriture fichier invitations : %v", err)
	}
}


// --- PERSISTANCE DES TOKENS FCM ---

// NOUVEAU: Charge les tokens FCM des utilisateurs depuis le fichier JSON.
func loadUserDeviceTokensFromFile() {
	userDeviceTokensMutex.Lock()
	defer userDeviceTokensMutex.Unlock()
	data, err := os.ReadFile(userDeviceTokensFile)
	if err != nil {
		if os.IsNotExist(err) {
			debugLog("Aucun fichier de tokens FCM ('%s') trouvé.", userDeviceTokensFile)
			return
		}
		log.Printf("Erreur lecture fichier tokens : %v", err)
		return
	}
	if err := json.Unmarshal(data, &userDeviceTokens); err != nil {
		log.Printf("Erreur démarshalling tokens : %v", err)
	} else {
		debugLog("%d utilisateur(s) avec tokens chargés depuis le fichier.", len(userDeviceTokens))
	}
}

// NOUVEAU: Sauvegarde les tokens FCM des utilisateurs dans le fichier JSON.
func saveUserDeviceTokensToFile() {
	userDeviceTokensMutex.Lock()
	defer userDeviceTokensMutex.Unlock()
	data, err := json.MarshalIndent(userDeviceTokens, "", "  ")
	if err != nil {
		log.Printf("Erreur marshalling tokens : %v", err)
		return
	}
	if err := os.WriteFile(userDeviceTokensFile, data, 0644); err != nil {
		log.Printf("Erreur écriture fichier tokens : %v", err)
	}
}