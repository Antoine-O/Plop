package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/lib/pq"
	_ "github.com/lib/pq"
)

var db *sql.DB

// --- Database Initialization ---

// initDB connects to the PostgreSQL database and creates tables if they don't exist.
func initDB() {
	// Get database connection details from environment variables or use defaults.
	user := getEnv("POSTGRES_USER", "postgres_user")
	password := getEnv("POSTGRES_PASSWORD", "postgres_password")
	dbname := getEnv("POSTGRES_DB", "plop_database")
	host := getEnv("POSTGRES_HOST", "plop_server")
	port := getEnv("POSTGRES_PORT", "5432")

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	var err error
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("[FATAL] Error connecting to the database: %v", err)
	}

	err = db.Ping()
	if err != nil {
		log.Fatalf("[FATAL] Could not ping the database: %v", err)
	}

	log.Println("[INFO] Successfully connected to the database.")
	createTables()
}

// getEnv retrieves an environment variable or returns a default value.
func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

// createTables ensures all necessary tables exist in the database.
func createTables() {
	// Use TEXT for user IDs as they are UUIDs.
	// Use JSONB for payload to flexibly store message data.
	createPendingMessagesTable := `
    CREATE TABLE IF NOT EXISTS pending_messages (
        recipient_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        message_payload JSONB NOT NULL,
        PRIMARY KEY (recipient_id, sender_id)
    );`

	// Stores FCM tokens for push notifications.
	createUserDeviceTokensTable := `
    CREATE TABLE IF NOT EXISTS user_device_tokens (
        user_id TEXT PRIMARY KEY,
        tokens TEXT[] NOT NULL
    );`

	// Stores user-chosen nicknames.
	createUserPseudosTable := `
	CREATE TABLE IF NOT EXISTS user_pseudos (
		user_id TEXT PRIMARY KEY,
		pseudo TEXT NOT NULL
	);`

	// Stores active invitation codes.
	createInvitationsTable := `
    CREATE TABLE IF NOT EXISTS invitations (
        code TEXT PRIMARY KEY,
        creator_user_id TEXT NOT NULL,
        creator_pseudo TEXT NOT NULL,
        expires_at TIMESTAMPTZ NOT NULL
    );`

	tables := []string{
		createPendingMessagesTable,
		createUserDeviceTokensTable,
		createUserPseudosTable,
		createInvitationsTable,
	}

	for _, table := range tables {
		if _, err := db.Exec(table); err != nil {
			log.Fatalf("[FATAL] Could not create table: %v", err)
		}
	}
	log.Println("[INFO] Database tables verified/created successfully.")
}

// --- Data Getters (On-Demand) ---

// dbGetUserDeviceTokens retrieves all FCM tokens for a specific user.
func dbGetUserDeviceTokens(userID string) ([]string, error) {
	var tokens []string
	err := db.QueryRow("SELECT tokens FROM user_device_tokens WHERE user_id = $1", userID).Scan(pq.Array(&tokens))
	if err != nil {
		// If no rows are found, it's not an error; it just means the user has no tokens.
		if err == sql.ErrNoRows {
			return []string{}, nil
		}
		log.Printf("[ERROR] Failed to query device tokens for user %s: %v", userID, err)
		return nil, err
	}
	return tokens, nil
}

// dbGetUserPseudo retrieves the pseudo for a specific user.
func dbGetUserPseudo(userID string) (string, error) {
	var pseudo string
	err := db.QueryRow("SELECT pseudo FROM user_pseudos WHERE user_id = $1", userID).Scan(&pseudo)
	if err != nil {
		if err == sql.ErrNoRows {
			// Return empty string if not found, which is a valid state.
			return "", nil
		}
		log.Printf("[ERROR] Failed to query pseudo for user %s: %v", userID, err)
		return "", err
	}
	return pseudo, nil
}

// dbGetUsersPseudos retrieves pseudos for a list of user IDs.
func dbGetUsersPseudos(userIDs []string) (map[string]string, error) {
	pseudos := make(map[string]string)
	if len(userIDs) == 0 {
		return pseudos, nil
	}

	rows, err := db.Query("SELECT user_id, pseudo FROM user_pseudos WHERE user_id = ANY($1)", pq.Array(userIDs))
	if err != nil {
		log.Printf("[ERROR] Failed to query pseudos: %v", err)
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var userID, pseudo string
		if err := rows.Scan(&userID, &pseudo); err != nil {
			log.Printf("[ERROR] Failed to scan pseudo row: %v", err)
			continue
		}
		pseudos[userID] = pseudo
	}
	return pseudos, nil
}

// dbGetInvitation retrieves an invitation by its code.
func dbGetInvitation(code string) (Invitation, bool, error) {
	var inv Invitation
	err := db.QueryRow("SELECT code, creator_user_id, creator_pseudo, expires_at FROM invitations WHERE code = $1", code).Scan(&inv.Code, &inv.CreatorUserID, &inv.CreatorPseudo, &inv.ExpiresAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return Invitation{}, false, nil // Not found, not an error.
		}
		log.Printf("[ERROR] Failed to query invitation %s: %v", code, err)
		return Invitation{}, false, err // A real error occurred.
	}
	return inv, true, nil
}

// --- Data Savers/Deleters ---

// dbSaveUserPseudo saves or updates a user's pseudo in the database.
func dbSaveUserPseudo(userID, pseudo string) {
	query := `
    INSERT INTO user_pseudos (user_id, pseudo)
    VALUES ($1, $2)
    ON CONFLICT (user_id) DO UPDATE SET pseudo = $2;`
	_, err := db.Exec(query, userID, pseudo)
	if err != nil {
		log.Printf("[ERROR] Failed to save pseudo for user %s: %v", userID, err)
	}
}

// dbSaveUserDeviceTokens saves or updates a user's FCM tokens in the database.
func dbSaveUserDeviceTokens(userID string, tokens []string) {
	query := `
    INSERT INTO user_device_tokens (user_id, tokens)
    VALUES ($1, $2)
    ON CONFLICT (user_id) DO UPDATE SET tokens = $2;`
	_, err := db.Exec(query, userID, pq.Array(tokens))
	if err != nil {
		log.Printf("[ERROR] Failed to save device tokens for user %s: %v", userID, err)
	}
}

// dbSaveInvitation adds a new invitation to the database.
func dbSaveInvitation(inv Invitation) {
	query := `
    INSERT INTO invitations (code, creator_user_id, creator_pseudo, expires_at)
    VALUES ($1, $2, $3, $4);`
	_, err := db.Exec(query, inv.Code, inv.CreatorUserID, inv.CreatorPseudo, inv.ExpiresAt)
	if err != nil {
		log.Printf("[ERROR] Failed to save invitation %s: %v", inv.Code, err)
	}
}

// dbDeleteInvitation removes an invitation from the database.
func dbDeleteInvitation(code string) {
	_, err := db.Exec("DELETE FROM invitations WHERE code = $1", code)
	if err != nil {
		log.Printf("[ERROR] Failed to delete invitation %s: %v", code, err)
	}
}

// dbSavePendingMessage stores an offline message in the database.
func dbSavePendingMessage(msg Message) {
	payloadBytes, err := json.Marshal(msg.Payload)
	if err != nil {
		log.Printf("[ERROR] Failed to marshal payload for pending message to %s: %v", msg.To, err)
		return
	}

	query := `
    INSERT INTO pending_messages (recipient_id, sender_id, message_payload)
    VALUES ($1, $2, $3)
    ON CONFLICT (recipient_id, sender_id) DO UPDATE SET message_payload = $3;`
	_, err = db.Exec(query, msg.To, msg.From, payloadBytes)
	if err != nil {
		log.Printf("[ERROR] Failed to save pending message for %s from %s: %v", msg.To, msg.From, err)
	}
}

// dbDeletePendingMessagesForUser removes all pending messages for a user from the database.
func dbDeletePendingMessagesForUser(userID string) {
	_, err := db.Exec("DELETE FROM pending_messages WHERE recipient_id = $1", userID)
	if err != nil {
		log.Printf("[ERROR] Failed to delete pending messages for user %s: %v", userID, err)
	}
}

// dbDeleteExpiredInvitations removes all expired invitations from the database.
func dbDeleteExpiredInvitations() {
	res, err := db.Exec("DELETE FROM invitations WHERE expires_at < NOW()")
	if err != nil {
		log.Printf("[ERROR] Failed to delete expired invitations: %v", err)
		return
	}
	rowsAffected, _ := res.RowsAffected()
	if rowsAffected > 0 {
		log.Printf("[CLEANUP] Deleted %d expired invitations from database.", rowsAffected)
	}
}

// --- Business Logic Wrappers ---

// dbSendPendingMessages queries and delivers stored offline messages from the database.
func dbSendPendingMessages(userID string, conn connection) {
	rows, err := db.Query("SELECT sender_id, message_payload FROM pending_messages WHERE recipient_id = $1", userID)
	if err != nil {
		log.Printf("[ERROR] Failed to query pending messages for user %s: %v", userID, err)
		return
	}
	defer rows.Close()

	var messagesToSend []Message
	for rows.Next() {
		var senderID string
		var payloadBytes []byte
		if err := rows.Scan(&senderID, &payloadBytes); err != nil {
			log.Printf("[ERROR] Failed to scan pending message row for user %s: %v", userID, err)
			continue
		}

		var payload interface{}
		if err := json.Unmarshal(payloadBytes, &payload); err != nil {
			log.Printf("[ERROR] Failed to unmarshal pending message payload for user %s: %v", userID, err)
			continue
		}
		messagesToSend = append(messagesToSend, Message{From: senderID, To: userID, Payload: payload, IsPending: true})
	}

	if err := rows.Err(); err != nil {
        log.Printf("[ERROR] Error during pending message rows iteration for user %s: %v", userID, err)
        return
    }

	if len(messagesToSend) == 0 {
		return // No pending messages.
	}

	log.Printf("[INFO] Found %d pending messages in DB for user %s. Attempting to send.", len(messagesToSend), userID)

	for _, msg := range messagesToSend {
		if err := conn.WriteJSON(msg); err != nil {
			log.Printf("[ERROR] Failed to send pending message from %s to %s: %v. Will retry on next connection.", msg.From, userID, err)
			return
		}
	}

	log.Printf("[INFO] All pending messages for %s sent. Clearing from DB.", userID)
	go dbDeletePendingMessagesForUser(userID)
}

// --- Utility ---

// connection is an interface to allow testing with mock connections.
type connection interface {
	WriteJSON(v interface{}) error
}
