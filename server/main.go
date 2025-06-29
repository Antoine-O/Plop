package main

import (
	"log"
	"net/http"

	"github.com/rs/cors"
)

// main is the entry point of the application.
// It initializes services, sets up routes, and starts the server.
func main() {
	log.Println("[INFO] Starting server...")

	// Initialize external services and database connection
	initializeFirebase()
	initDB() // Initializes connection to PostgreSQL

	// Start background cleanup routines
	go cleanupExpiredInvitations()
	go cleanupExpiredSyncCodes()

	// Create a new ServeMux to register our handlers
	mux := http.NewServeMux()

	// Register all HTTP handlers
	mux.HandleFunc("/connect", handleWebSocket)
	mux.HandleFunc("/invitations/create", handleCreateInvitation)
	mux.HandleFunc("/invitations/use", handleUseInvitation)
	mux.HandleFunc("/users/generate-id", handleGenerateUserID)
	mux.HandleFunc("/users/get-pseudos", handleGetPseudos)
	mux.HandleFunc("/sync/create", handleCreateSyncCode)
	mux.HandleFunc("/sync/use", handleUseSyncCode)
	mux.HandleFunc("/users/update-token", handleUpdateToken)
	mux.HandleFunc("/ping", handlePing)

	// Configure CORS for cross-origin requests
	handler := cors.New(cors.Options{
		AllowedOrigins: []string{"*"},
		AllowedMethods: []string{"GET", "POST", "OPTIONS"},
		AllowedHeaders: []string{"Content-Type"},
	}).Handler(mux)

	log.Println("[INFO] Server started on http://localhost:8080")
	if err := http.ListenAndServe(":8080", handler); err != nil {
		log.Fatal("[FATAL] ListenAndServe: ", err)
	}
}
