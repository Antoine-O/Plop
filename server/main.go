

package main

import (
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
)

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

const invitationValidityMinutes = 5

const messageCooldown = 5 * time.Second // NOUVEAU: Temps de rechargement de 5 secondes


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

// --- Logger ---

func debugLog(format string, v ...interface{}) {
	if os.Getenv("DEBUG") != "" {
		log.Printf("[DEBUG] "+format, v...)
	}
}

// --- Main Function ---

func main() {
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
    clientsMutex.Lock()
    defer clientsMutex.Unlock()

    if recipientConns, found := clients[msg.To]; found {
        debugLog("Envoi d'un message direct de %s à %s", msg.From, msg.To)
        for conn := range recipientConns {
            err := conn.WriteJSON(msg)
            if err != nil {
                debugLog("Erreur d'envoi (direct) de %s à %s : %v", msg.From, msg.To, err)
            }
        }
    } else {
        debugLog("Envoi d'un message direct de %s à %s - Destinataire non trouvé", msg.From, msg.To)
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
		for code, inv := range invitations {
			if now.After(inv.ExpiresAt) {
				delete(invitations, code)
				debugLog("Code d'invitation expiré supprimé: %s", code)
			}
		}
		invitationsMutex.Unlock()
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