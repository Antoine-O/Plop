package main

import (
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

// --- Global State & Mutexes ---

// clients maps a userID to a set of their active WebSocket connections.
// This remains in memory as it represents the current live connections, which is ephemeral state.
var clients = make(map[string]map[*websocket.Conn]bool)
var clientsMutex = &sync.Mutex{}

// syncCodes stores active synchronization codes. These are short-lived and can remain in memory.
var syncCodes = make(map[string]SyncCode)
var syncCodesMutex = &sync.Mutex{}

// userLastMessageTime is used for message rate-limiting/cooldown. This is also ephemeral state.
var userLastMessageTime = make(map[string]time.Time)
var userLastMessageMutex = &sync.Mutex{}

// --- Background Cleanup Routines ---

// cleanupExpiredInvitations periodically removes expired invitation codes from the database.
func cleanupExpiredInvitations() {
	log.Println("[CLEANUP] Starting expired invitations cleanup routine...")
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()
	for range ticker.C {
		dbDeleteExpiredInvitations()
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
