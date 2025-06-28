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
	invitationsMutex.Lock()
	invitations[code] = invitation
	invitationsMutex.Unlock()
	saveInvitationsToFile()
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

	invitationsMutex.Lock()
	invitation, found := invitations[req.Code]
	if found {
		delete(invitations, req.Code)
	}
	invitationsMutex.Unlock()

	if found {
		saveInvitationsToFile()
	}

	if !found || time.Now().After(invitation.ExpiresAt) {
		http.Error(w, "Invitation code is invalid or has expired", http.StatusNotFound)
		return
	}

	// Notify the creator that a new contact has been added
	notificationPayload := map[string]string{"userId": req.UserID, "pseudo": req.Pseudo}
	notificationMsg := Message{Type: "new_contact", Payload: notificationPayload}
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

	responsePseudos := make(map[string]string)
	userPseudosMutex.Lock()
	for _, id := range req.UserIDs {
		if pseudo, found := userPseudos[id]; found {
			responsePseudos[id] = pseudo
		}
	}
	userPseudosMutex.Unlock()

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

	userPseudosMutex.Lock()
	pseudo := userPseudos[syncData.UserID]
	userPseudosMutex.Unlock()

	json.NewEncoder(w).Encode(map[string]string{"userId": syncData.UserID, "pseudo": pseudo})
	log.Printf("[HTTP] Sync code %s successfully used, linking to user %s", req.Code, syncData.UserID)
}

// handleUpdateToken adds or updates an FCM device token for a user.
// It now saves to the file in a non-blocking way.
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

	userDeviceTokensMutex.Lock()
	tokens := userDeviceTokens[req.UserID]
	tokenExists := false
	for _, t := range tokens {
		if t == req.Token {
			tokenExists = true
			break
		}
	}

	if !tokenExists {
		userDeviceTokens[req.UserID] = append(tokens, req.Token)
		log.Printf("[INFO] New FCM token added for user %s. Responding immediately.", req.UserID)
		userDeviceTokensMutex.Unlock()

		// Run the slow file save operation in the background.
		// This allows the HTTP request to return immediately.
		go saveUserDeviceTokensToFile()

	} else {
		userDeviceTokensMutex.Unlock()
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
