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
	user := getEnv("POSTGRES_USER", "postgres_user")
	password := getEnv("POSTGRES_PASSWORD", "postgres_password")
	dbname := getEnv("POSTGRES_DB", "plop_database")
	host := getEnv("POSTGRES_HOST", "plop_server")
	port := getEnv("POSTGRES_PORT", "5432")

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	log.Printf("[DEBUG] Connecting to database with connection string: host=%s port=%s user=%s dbname=%s sslmode=disable (password omitted from log)", host, port, user, dbname)

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
	log.Printf("[DEBUG] Environment variable %s not set, using fallback: %s", key, fallback)
	return fallback
}

// createTables ensures all necessary tables exist in the database.
func createTables() {
	log.Println("[DEBUG] Attempting to create/verify database tables...")
	createPendingMessagesTable := `
    CREATE TABLE IF NOT EXISTS pending_messages (
        recipient_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        message_payload JSONB NOT NULL,
        PRIMARY KEY (recipient_id, sender_id)
    );`

	createUserDeviceTokensTable := `
    CREATE TABLE IF NOT EXISTS user_device_tokens (
        user_id TEXT PRIMARY KEY,
        tokens TEXT[] NOT NULL
    );`

	createUserPseudosTable := `
	CREATE TABLE IF NOT EXISTS user_pseudos (
		user_id TEXT PRIMARY KEY,
		pseudo TEXT NOT NULL
	);`

	createInvitationsTable := `
    CREATE TABLE IF NOT EXISTS invitations (
        code TEXT PRIMARY KEY,
        creator_user_id TEXT NOT NULL,
        creator_pseudo TEXT NOT NULL,
        expires_at TIMESTAMPTZ NOT NULL
    );`

	tables := map[string]string{
		"pending_messages":     createPendingMessagesTable,
		"user_device_tokens":   createUserDeviceTokensTable,
		"user_pseudos":         createUserPseudosTable,
		"invitations":          createInvitationsTable,
	}

	for name, query := range tables {
		log.Printf("[DEBUG] Executing CREATE TABLE IF NOT EXISTS for %s", name)
		if _, err := db.Exec(query); err != nil {
			log.Fatalf("[FATAL] Could not create table %s: %v", name, err)
		}
	}
	log.Println("[INFO] Database tables verified/created successfully.")
}

// --- Data Getters (On-Demand) ---

// dbGetUserDeviceTokens retrieves all FCM tokens for a specific user.
func dbGetUserDeviceTokens(userID string) ([]string, error) {
	log.Printf("[DEBUG] dbGetUserDeviceTokens called for userID: %s", userID)
	var tokens []string
	err := db.QueryRow("SELECT tokens FROM user_device_tokens WHERE user_id = $1", userID).Scan(pq.Array(&tokens))
	if err != nil {
		if err == sql.ErrNoRows {
			log.Printf("[INFO] No device tokens found for user %s. Returning empty slice.", userID)
			return []string{}, nil // Return empty slice, not nil, for consistency
		}
		log.Printf("[ERROR] Failed to query device tokens for user %s: %v", userID, err)
		return nil, err
	}
	log.Printf("[DEBUG] Successfully retrieved %d device token(s) for user %s: %v", len(tokens), userID, tokens)
	return tokens, nil
}

// dbGetUserPseudo retrieves the pseudo for a specific user.
func dbGetUserPseudo(userID string) (string, error) {
	log.Printf("[DEBUG] dbGetUserPseudo called for userID: %s", userID)
	var pseudo string
	err := db.QueryRow("SELECT pseudo FROM user_pseudos WHERE user_id = $1", userID).Scan(&pseudo)
	if err != nil {
		if err == sql.ErrNoRows {
			log.Printf("[INFO] No pseudo found for user %s. Returning empty string.", userID)
			return "", nil
		}
		log.Printf("[ERROR] Failed to query pseudo for user %s: %v", userID, err)
		return "", err
	}
	log.Printf("[DEBUG] Successfully retrieved pseudo for user %s: %s", userID, pseudo)
	return pseudo, nil
}

// dbGetUsersPseudos retrieves pseudos for a list of user IDs.
func dbGetUsersPseudos(userIDs []string) (map[string]string, error) {
	log.Printf("[DEBUG] dbGetUsersPseudos called for %d userIDs: %v", len(userIDs), userIDs)
	pseudos := make(map[string]string)
	if len(userIDs) == 0 {
		log.Println("[DEBUG] dbGetUsersPseudos received empty userIDs list, returning empty map.")
		return pseudos, nil
	}

	rows, err := db.Query("SELECT user_id, pseudo FROM user_pseudos WHERE user_id = ANY($1)", pq.Array(userIDs))
	if err != nil {
		log.Printf("[ERROR] Failed to query pseudos for userIDs %v: %v", userIDs, err)
		return nil, err
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID, pseudo string
		if err := rows.Scan(&userID, &pseudo); err != nil {
			log.Printf("[ERROR] Failed to scan pseudo row during dbGetUsersPseudos: %v", err)
			continue // Skip this row and try the next
		}
		pseudos[userID] = pseudo
		count++
	}
	if err := rows.Err(); err != nil {
		log.Printf("[ERROR] Error during rows iteration in dbGetUsersPseudos: %v", err)
        // Depending on the error, you might want to return it or just the pseudos found so far.
        // For now, returning what we have.
	}
	log.Printf("[DEBUG] dbGetUsersPseudos retrieved %d pseudos.", count)
	return pseudos, nil
}

// dbGetInvitation retrieves an invitation by its code.
func dbGetInvitation(code string) (Invitation, bool, error) {
	log.Printf("[DEBUG] dbGetInvitation called for code: %s", code)
	var inv Invitation
	err := db.QueryRow("SELECT code, creator_user_id, creator_pseudo, expires_at FROM invitations WHERE code = $1", code).Scan(&inv.Code, &inv.CreatorUserID, &inv.CreatorPseudo, &inv.ExpiresAt)
	if err != nil {
		if err == sql.ErrNoRows {
			log.Printf("[INFO] No invitation found for code %s.", code)
			return Invitation{}, false, nil
		}
		log.Printf("[ERROR] Failed to query invitation %s: %v", code, err)
		return Invitation{}, false, err
	}
	log.Printf("[DEBUG] Successfully retrieved invitation for code %s: %+v", code, inv)
	return inv, true, nil
}

// --- Data Savers/Deleters ---

// dbSaveUserPseudo saves or updates a user's pseudo in the database.
func dbSaveUserPseudo(userID, pseudo string) {
	log.Printf("[DEBUG] dbSaveUserPseudo called for userID: %s, pseudo: %s", userID, pseudo)
	query := `
    INSERT INTO user_pseudos (user_id, pseudo)
    VALUES ($1, $2)
    ON CONFLICT (user_id) DO UPDATE SET pseudo = $2;`
	res, err := db.Exec(query, userID, pseudo)
	if err != nil {
		log.Printf("[ERROR] Failed to save pseudo for user %s: %v", userID, err)
		return
	}
	rowsAffected, _ := res.RowsAffected()
	log.Printf("[INFO] Successfully saved pseudo for user %s. Rows affected: %d", userID, rowsAffected)
}

// dbSaveUserDeviceTokens saves or updates a user's FCM tokens in the database.
func dbSaveUserDeviceTokens(userID string, tokens []string) {
	log.Printf("[DEBUG] dbSaveUserDeviceTokens called for userID: %s. Input tokens: %#v (is nil: %t, length: %d)", userID, tokens, tokens == nil, len(tokens))

	// Defensive check: Ensure tokens is not nil, convert to empty slice if it is,
	// to prevent "violates not-null constraint" if the input `tokens` slice is nil.
	actualTokens := tokens
	if actualTokens == nil {
		log.Printf("[WARN] dbSaveUserDeviceTokens received nil tokens slice for userID: %s. Converting to empty slice before DB operation.", userID)
		actualTokens = []string{}
	}

	query := `
    INSERT INTO user_device_tokens (user_id, tokens)
    VALUES ($1, $2)
    ON CONFLICT (user_id) DO UPDATE SET tokens = $2;`
	res, err := db.Exec(query, userID, pq.Array(actualTokens))
	if err != nil {
		// The error message you provided is already logged here by default.
		// "Failed to save device tokens for user %s: %v"
		log.Printf("[ERROR] Failed to save device tokens for user %s with tokens %#v: %v", userID, actualTokens, err)
		return
	}
	rowsAffected, _ := res.RowsAffected()
	log.Printf("[INFO] Successfully saved/updated device tokens for user %s. Tokens: %#v. Rows affected: %d", userID, actualTokens, rowsAffected)
}

// dbSaveInvitation adds a new invitation to the database.
func dbSaveInvitation(inv Invitation) {
	log.Printf("[DEBUG] dbSaveInvitation called for invitation: %+v", inv)
	query := `
    INSERT INTO invitations (code, creator_user_id, creator_pseudo, expires_at)
    VALUES ($1, $2, $3, $4);`
	res, err := db.Exec(query, inv.Code, inv.CreatorUserID, inv.CreatorPseudo, inv.ExpiresAt)
	if err != nil {
		log.Printf("[ERROR] Failed to save invitation %s: %v", inv.Code, err)
		return
	}
	rowsAffected, _ := res.RowsAffected()
	log.Printf("[INFO] Successfully saved invitation %s. Rows affected: %d", inv.Code, rowsAffected)
}

// dbDeleteInvitation removes an invitation from the database.
func dbDeleteInvitation(code string) {
	log.Printf("[DEBUG] dbDeleteInvitation called for code: %s", code)
	res, err := db.Exec("DELETE FROM invitations WHERE code = $1", code)
	if err != nil {
		log.Printf("[ERROR] Failed to delete invitation %s: %v", code, err)
		return
	}
	rowsAffected, _ := res.RowsAffected()
	log.Printf("[INFO] Attempted to delete invitation %s. Rows affected: %d", code, rowsAffected)
}

// dbSavePendingMessage stores an offline message in the database.
func dbSavePendingMessage(msg Message) {
	log.Printf("[DEBUG] dbSavePendingMessage called for message to: %s, from: %s, payload type: %T", msg.To, msg.From, msg.Payload)
	payloadBytes, err := json.Marshal(msg.Payload)
	if err != nil {
		log.Printf("[ERROR] Failed to marshal payload for pending message to %s from %s: %v", msg.To, msg.From, err)
		return
	}
	// log.Printf("[DEBUG] Marshalled payload for pending message: %s", string(payloadBytes)) // Be cautious with logging full payloads

	query := `
    INSERT INTO pending_messages (recipient_id, sender_id, message_payload)
    VALUES ($1, $2, $3)
    ON CONFLICT (recipient_id, sender_id) DO UPDATE SET message_payload = $3;`
	res, err := db.Exec(query, msg.To, msg.From, payloadBytes)
	if err != nil {
		log.Printf("[ERROR] Failed to save pending message for %s from %s: %v", msg.To, msg.From, err)
		return
	}
	rowsAffected, _ := res.RowsAffected()
	log.Printf("[INFO] Successfully saved pending message for %s from %s. Rows affected: %d", msg.To, msg.From, rowsAffected)
}

// dbDeletePendingMessagesForUser removes all pending messages for a user from the database.
func dbDeletePendingMessagesForUser(userID string) {
	log.Printf("[DEBUG] dbDeletePendingMessagesForUser called for userID: %s", userID)
	res, err := db.Exec("DELETE FROM pending_messages WHERE recipient_id = $1", userID)
	if err != nil {
		log.Printf("[ERROR] Failed to delete pending messages for user %s: %v", userID, err)
		return
	}
	rowsAffected, _ := res.RowsAffected()
	log.Printf("[INFO] Attempted to delete pending messages for user %s. Rows affected: %d", userID, rowsAffected)
}

// dbDeleteExpiredInvitations removes all expired invitations from the database.
func dbDeleteExpiredInvitations() {
	log.Println("[DEBUG] dbDeleteExpiredInvitations called.")
	res, err := db.Exec("DELETE FROM invitations WHERE expires_at < NOW()")
	if err != nil {
		log.Printf("[ERROR] Failed to delete expired invitations: %v", err)
		return
	}
	rowsAffected, _ := res.RowsAffected()
	if rowsAffected > 0 {
		log.Printf("[INFO][CLEANUP] Deleted %d expired invitations from database.", rowsAffected)
	} else {
		log.Println("[DEBUG] No expired invitations found to delete.")
	}
}

// --- Business Logic Wrappers ---

// dbSendPendingMessages queries and delivers stored offline messages from the database.
func dbSendPendingMessages(userID string, conn connection) {
	log.Printf("[DEBUG] dbSendPendingMessages called for userID: %s", userID)
	rows, err := db.Query("SELECT sender_id, message_payload FROM pending_messages WHERE recipient_id = $1", userID)
	if err != nil {
		log.Printf("[ERROR] Failed to query pending messages for user %s: %v", userID, err)
		return
	}
	defer rows.Close()

	var messagesToSend []Message
	log.Printf("[DEBUG] Iterating over pending message rows for user %s...", userID)
	for rows.Next() {
		var senderID string
		var payloadBytes []byte
		if err := rows.Scan(&senderID, &payloadBytes); err != nil {
			log.Printf("[ERROR] Failed to scan pending message row for user %s: %v", userID, err)
			continue
		}
		// log.Printf("[DEBUG] Scanned pending message from %s, payload bytes length: %d", senderID, len(payloadBytes))

		var payload interface{}
		if err := json.Unmarshal(payloadBytes, &payload); err != nil {
			log.Printf("[ERROR] Failed to unmarshal pending message payload for user %s from sender %s: %v", userID, senderID, err)
			continue
		}
		messagesToSend = append(messagesToSend, Message{From: senderID, To: userID, Payload: payload, IsPending: true})
	}

	if err := rows.Err(); err != nil {
        log.Printf("[ERROR] Error during pending message rows iteration for user %s: %v", userID, err)
        return
    }

	if len(messagesToSend) == 0 {
		log.Printf("[INFO] No pending messages found in DB for user %s.", userID)
		return
	}

	log.Printf("[INFO] Found %d pending messages in DB for user %s. Attempting to send.", len(messagesToSend), userID)

	for i, msg := range messagesToSend {
		log.Printf("[DEBUG] Attempting to send pending message %d/%d from %s to %s via connection.", i+1, len(messagesToSend), msg.From, userID)
		if err := conn.WriteJSON(msg); err != nil {
			log.Printf("[ERROR] Failed to send pending message from %s to %s: %v. Message will remain in DB for next attempt.", msg.From, userID, err)
			return // Stop trying to send further messages on this connection if one fails
		}
		log.Printf("[INFO] Successfully sent pending message %d/%d from %s to %s.", i+1, len(messagesToSend), msg.From, userID)
	}

	log.Printf("[INFO] All %d pending messages for %s sent successfully. Clearing them from DB.", len(messagesToSend), userID)
	go dbDeletePendingMessagesForUser(userID) // This is asynchronous
}

// --- Utility ---

// connection is an interface to allow testing with mock connections.
type connection interface {
	WriteJSON(v interface{}) error
}