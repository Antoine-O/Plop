package main

import (
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

// --- Global State & Mutexes ---

// clients maps a userID to a set of their active WebSocket connections.
var clients = make(map[string]map[*websocket.Conn]bool)
var clientsMutex = &sync.Mutex{}

// userDeviceTokens maps a userID to their list of FCM device tokens.
var userDeviceTokens = make(map[string][]string)
var userDeviceTokensMutex = &sync.Mutex{}

// invitations stores active invitation codes.
var invitations = make(map[string]Invitation)
var invitationsMutex = &sync.Mutex{}

// syncCodes stores active synchronization codes.
var syncCodes = make(map[string]SyncCode)
var syncCodesMutex = &sync.Mutex{}

// pendingMessages stores messages for offline users.
// The structure is map[recipientId][senderId]Message.
var pendingMessages = make(map[string]map[string]Message)
var pendingMessagesMutex = &sync.Mutex{}

// userPseudos maps a userID to their chosen pseudo.
var userPseudos = make(map[string]string)
var userPseudosMutex = &sync.Mutex{}

// userLastMessageTime is used for message rate-limiting/cooldown.
var userLastMessageTime = make(map[string]time.Time)
var userLastMessageMutex = &sync.Mutex{}

// --- Background Cleanup Routines ---

// cleanupExpiredInvitations periodically removes expired invitation codes from memory.
func cleanupExpiredInvitations() {
	log.Println("[CLEANUP] Starting expired invitations cleanup routine...")
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
				log.Printf("[CLEANUP] Deleted expired invitation code: %s", code)
			}
		}
		invitationsMutex.Unlock()
		if deleted {
			saveInvitationsToFile()
		}
	}
}

// cleanupExpiredSyncCodes periodically removes expired sync codes from memory.
func cleanupExpiredSyncCodes() {
	log.Println("[CLEANUP] Starting expired sync codes cleanup routine...")
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()
	for range ticker.C {
		now := time.Now()
		syncCodesMutex.Lock()
		for code, sc := range syncCodes {
			if now.After(sc.ExpiresAt) {
				delete(syncCodes, code)
				log.Printf("[CLEANUP] Deleted expired sync code: %s", code)
			}
		}
		syncCodesMutex.Unlock()
	}
}
