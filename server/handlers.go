package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/google/uuid"
)

// --- HTTP Handlers ---
const (
	invitationValidityMinutes = 10
)

// handleGenerateUserID creates and returns a new unique user ID.
func handleGenerateUserID(w http.ResponseWriter, r *http.Request) {
	log.Println("[HTTP] Received request for /users/generate-id")
	id := uuid.New()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"userId": id.String()})
	log.Printf("[HTTP] Generated new UserID: %s", id.String())
}

// handleCreateInvitation creates a new invitation code for a user.
func handleCreateInvitation(w http.ResponseWriter, r *http.Request) {
	log.Println("[HTTP] Received request for /invitations/create")
	creatorID := r.URL.Query().Get("userId")
	creatorPseudo := r.URL.Query().Get("pseudo")
	if creatorID == "" || creatorPseudo == "" {
		http.Error(w, "'userId' and 'pseudo' are required", http.StatusBadRequest)
		return
	}
	code := generateRandomCode(6)
	invitation := Invitation{
		Code:          code,
		CreatorUserID: creatorID,
		CreatorPseudo: creatorPseudo,
		ExpiresAt:     time.Now().Add(invitationValidityMinutes * time.Minute),
	}
	go dbSaveInvitation(invitation)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"code": code, "validityMinutes": invitationValidityMinutes})
	log.Printf("[HTTP] Invitation code %s created for user %s", code, creatorID)
}

// handleUseInvitation allows a user to consume an invitation code to connect with its creator.
func handleUseInvitation(w http.ResponseWriter, r *http.Request) {
	log.Println("[HTTP] Received request for /invitations/use")
	var req struct{ Code, UserID, Pseudo string }
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	invitation, found, err := dbGetInvitation(req.Code)
	if err != nil {
		log.Printf("[ERROR] Failed to get invitation %s: %v", req.Code, err)
		http.Error(w, "Error checking invitation", http.StatusInternalServerError)
		return
	}

	if !found || time.Now().After(invitation.ExpiresAt) {
		http.Error(w, "Invitation code is invalid or has expired", http.StatusNotFound)
		return
	}

	go dbDeleteInvitation(req.Code)

	// Notify the creator that a new contact has been added
	// Notify the creator that a new contact has been added
	contactPayload := MessagePayload{
		UserID: req.UserID,
		Pseudo: req.Pseudo,
		// Text: fmt.Sprintf("%s (%s) has been added to your contacts!", req.Pseudo, req.UserID), // Optional: add a text field too
	}
	notificationMsg := Message{
		Type:    "new_contact",
		Payload: contactPayload, // Now using the MessagePayload struct instance
	}
	broadcastMessageToUser(invitation.CreatorUserID, notificationMsg, nil)

	log.Printf("[HTTP] Invitation code %s successfully used by %s to connect with %s", req.Code, req.UserID, invitation.CreatorUserID)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"userId": invitation.CreatorUserID, "pseudo": invitation.CreatorPseudo})
}

// handleGetPseudos returns the pseudos for a given list of user IDs.
func handleGetPseudos(w http.ResponseWriter, r *http.Request) {
	log.Println("[HTTP] Received request for /users/get-pseudos")
	var req struct{ UserIDs []string `json:"userIds"` }
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	responsePseudos, err := dbGetUsersPseudos(req.UserIDs)
	if err != nil {
		http.Error(w, "Failed to retrieve pseudos", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(responsePseudos)
}

// handleCreateSyncCode creates a new synchronization code for a user.
func handleCreateSyncCode(w http.ResponseWriter, r *http.Request) {
	log.Println("[HTTP] Received request for /sync/create")
	userId := r.URL.Query().Get("userId")
	if userId == "" {
		http.Error(w, "userId is required", http.StatusBadRequest)
		return
	}
	code := generateRandomCode(6)
	syncCode := SyncCode{Code: code, UserID: userId, ExpiresAt: time.Now().Add(5 * time.Minute)}

	syncCodesMutex.Lock()
	syncCodes[code] = syncCode
	syncCodesMutex.Unlock()

	json.NewEncoder(w).Encode(map[string]string{"code": code})
	log.Printf("[HTTP] Sync code created for user %s", userId)
}

// handleUseSyncCode allows a user to consume a sync code to link a new device.
func handleUseSyncCode(w http.ResponseWriter, r *http.Request) {
	log.Println("[HTTP] Received request for /sync/use")
	var req struct{ Code string `json:"code"` }
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	syncCodesMutex.Lock()
	syncData, found := syncCodes[req.Code]
	if found {
		delete(syncCodes, req.Code)
	}
	syncCodesMutex.Unlock()

	if !found || time.Now().After(syncData.ExpiresAt) {
		http.Error(w, "Sync code is invalid or has expired", http.StatusNotFound)
		return
	}

	// Trigger a sync event on the user's other devices
	broadcastMessageToUser(syncData.UserID, Message{Type: "sync_request"}, nil)

	pseudo, err := dbGetUserPseudo(syncData.UserID)
	if err != nil {
		http.Error(w, "Failed to retrieve user pseudo", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]string{"userId": syncData.UserID, "pseudo": pseudo})
	log.Printf("[HTTP] Sync code %s successfully used, linking to user %s", req.Code, syncData.UserID)
}

// handleUpdateToken adds or updates an FCM device token for a user.
func handleUpdateToken(w http.ResponseWriter, r *http.Request) {
	log.Println("[HTTP] Received request for /users/update-token")
	var req struct{ UserID, Token string }
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if req.UserID == "" || req.Token == "" {
		http.Error(w, "userId and token are required", http.StatusBadRequest)
		return
	}

	tokens, err := dbGetUserDeviceTokens(req.UserID)
	if err != nil {
		http.Error(w, "Failed to retrieve tokens", http.StatusInternalServerError)
		return
	}

	tokenExists := false
	for _, t := range tokens {
		if t == req.Token {
			tokenExists = true
			break
		}
	}

	if !tokenExists {
		newTokens := append(tokens, req.Token)
		go dbSaveUserDeviceTokens(req.UserID, newTokens)
		log.Printf("[INFO] New FCM token added for user %s.", req.UserID)
	} else {
		log.Printf("[INFO] Existing FCM token received for user %s", req.UserID)
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]bool{"success": true})
}

// handlePing is a simple health check endpoint.
func handlePing(w http.ResponseWriter, r *http.Request) {
	log.Println("[HTTP] Received request on /ping")
	fmt.Fprint(w, "pong")
}
