package main

import (
	"encoding/json"
	"log"
	"os"
)

// --- File Constants ---
const (
	pendingMessagesFile  = "pending_messages.json"
	userDeviceTokensFile = "user_device_tokens.json"
	invitationsFile      = "invitations.json"
)

// --- Generic Persistence Functions ---

// loadDataFromFile reads a JSON file and unmarshals it into the target interface.
func loadDataFromFile(fileName string, target interface{}) {
	log.Printf("[PERSISTENCE] Loading data from %s...", fileName)
	data, err := os.ReadFile(fileName)
	if err != nil {
		if os.IsNotExist(err) {
			log.Printf("[INFO] Persistence file not found at '%s'. Starting fresh.", fileName)
			return
		}
		log.Printf("[ERROR] Error reading file %s: %v", fileName, err)
		return
	}
	if err := json.Unmarshal(data, target); err != nil {
		log.Printf("[ERROR] Error unmarshalling data from %s: %v", fileName, err)
	} else {
		log.Printf("[INFO] Successfully loaded data from %s.", fileName)
	}
}

// saveDataToFile marshals data into JSON and writes it to a file.
func saveDataToFile(fileName string, data interface{}) {
	log.Printf("[PERSISTENCE] Saving data to %s...", fileName)
	jsonData, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		log.Printf("[ERROR] Error marshalling data for %s: %v", fileName, err)
		return
	}
	if err := os.WriteFile(fileName, jsonData, 0644); err != nil {
		log.Printf("[ERROR] Error writing to file %s: %v", fileName, err)
	} else {
		log.Printf("[INFO] Successfully saved data to %s.", fileName)
	}
}

// --- Specific Persistence Wrappers ---

func loadAllFromDisk() {
	loadDataFromFile(pendingMessagesFile, &pendingMessages)
	loadDataFromFile(userDeviceTokensFile, &userDeviceTokens)
	loadDataFromFile(invitationsFile, &invitations)
}

func savePendingMessagesToFile() {
	pendingMessagesMutex.Lock()
	defer pendingMessagesMutex.Unlock()
	saveDataToFile(pendingMessagesFile, pendingMessages)
}

func saveUserDeviceTokensToFile() {
	userDeviceTokensMutex.Lock()
	defer userDeviceTokensMutex.Unlock()
	saveDataToFile(userDeviceTokensFile, userDeviceTokens)
}

func saveInvitationsToFile() {
	invitationsMutex.Lock()
	defer invitationsMutex.Unlock()
	saveDataToFile(invitationsFile, invitations)
}

// sendPendingMessages delivers stored offline messages to a newly connected user.
func sendPendingMessages(userID string, conn connection) {
	pendingMessagesMutex.Lock()
	messagesForUser, found := pendingMessages[userID]
	if !found || len(messagesForUser) == 0 {
		pendingMessagesMutex.Unlock()
		return
	}

	log.Printf("[INFO] Found %d pending messages for user %s. Attempting to send.", len(messagesForUser), userID)
	// Send messages and if successful, clear them from the pending queue.
	for senderID, msg := range messagesForUser {
		msg.IsPending = true
		if err := conn.WriteJSON(msg); err != nil {
			log.Printf("[ERROR] Failed to send pending message from %s to %s: %v. Will retry later.", senderID, userID, err)
			pendingMessagesMutex.Unlock()
			return // Stop and retry on the next connection
		}
	}

	// All messages sent successfully, clear from queue.
	delete(pendingMessages, userID)
	log.Printf("[INFO] All pending messages for %s sent and cleared.", userID)
	pendingMessagesMutex.Unlock()
	savePendingMessagesToFile() // Persist the change
}

// connection is an interface to allow testing with mock connections.
type connection interface {
	WriteJSON(v interface{}) error
}
