package main

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

const messageCooldown = 0 * time.Second

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

// handleWebSocket upgrades an HTTP connection to a WebSocket connection.
func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	userId := r.URL.Query().Get("userId")
	pseudo := r.URL.Query().Get("pseudo")
	log.Printf("[WS] Connection attempt from userId=%s, pseudo=%s", userId, pseudo)
	if userId == "" {
		http.Error(w, "userId is missing", http.StatusBadRequest)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("[ERROR] WebSocket upgrade failed for %s: %v", userId, err)
		return
	}
	defer conn.Close()

	// Register the new client connection
	clientsMutex.Lock()
	if clients[userId] == nil {
		clients[userId] = make(map[*websocket.Conn]bool)
	}
	hasOtherDevices := len(clients[userId]) > 0
	clients[userId][conn] = true
	log.Printf("[WS] Client %s connected. Total connections for user: %d", userId, len(clients[userId]))
	clientsMutex.Unlock()

	// Update pseudo if provided
	if pseudo != "" {
		go dbSaveUserPseudo(userId, pseudo)
	}

	// Deliver any messages that were sent while the user was offline
	go dbSendPendingMessages(userId, conn)

	// If this is a new device, request a data sync from other online devices
	if hasOtherDevices {
		broadcastMessageToUser(userId, Message{Type: "sync_request"}, conn)
	}

	// Main loop to listen for incoming messages from this client
	listenForMessages(conn, userId)

	// Cleanup when the connection is closed
	clientsMutex.Lock()
	delete(clients[userId], conn)
	if len(clients[userId]) == 0 {
		delete(clients, userId)
		log.Printf("[WS] Last client for user %s disconnected, removing from active list.", userId)
	}
	clientsMutex.Unlock()
}

// listenForMessages reads messages from a WebSocket connection and routes them.
func listenForMessages(conn *websocket.Conn, fromUserId string) {
	log.Printf("[WS] Listening for messages from %s", fromUserId)
	for {
		_, p, err := conn.ReadMessage()
		if err != nil {
			log.Printf("[WS] Error reading message from %s: %v. Closing connection.", fromUserId, err)
			break
		}

		var msg Message
		if err := json.Unmarshal(p, &msg); err != nil {
			log.Printf("[WARN] Failed to unmarshal message from %s: %v", fromUserId, err)
			continue
		}
		msg.From = fromUserId
		log.Printf("[WS] Received message of type '%s' from %s", msg.Type, fromUserId)

		switch msg.Type {
		case "plop":
			handlePlopMessage(conn, msg)
		case "sync_data_broadcast":
			log.Printf("[SYNC] Relaying sync_data_broadcast from %s to their other devices.", fromUserId)
			broadcastMessageToUser(fromUserId, msg, conn)
		case "ping":
			log.Printf("[WS] Received ping from %s", fromUserId)
		default:
			log.Printf("[WARN] Unknown message type '%s' from %s", msg.Type, fromUserId)
		}
	}
}

// handlePlopMessage processes a "plop" message, checking the cooldown and forwarding it.
func handlePlopMessage(conn *websocket.Conn, msg Message) {
	userLastMessageMutex.Lock()
	lastTime, found := userLastMessageTime[msg.From]
	if !found || time.Since(lastTime) > messageCooldown {
		userLastMessageTime[msg.From] = time.Now()
		userLastMessageMutex.Unlock()

		// Acknowledge the message was received and is being processed
		ackPayload := map[string]string{"recipientId": msg.To}
		if err := conn.WriteJSON(Message{Type: "message_ack", Payload: ackPayload}); err != nil {
			log.Printf("[ERROR] Could not send 'message_ack' to %s: %v", msg.From, err)
		}
		sendDirectMessage(msg)
	} else {
		userLastMessageMutex.Unlock()
		log.Printf("[WARN] Cooldown active for %s. 'plop' message ignored.", msg.From)
	}
}

// sendDirectMessage forwards a message to a recipient if they are online,
// otherwise it stores it as a pending message in the database.
func sendDirectMessage(msg Message) {
	if msg.To == "" {
		log.Printf("[WARN] Dropping direct message from %s: recipient 'to' field is empty.", msg.From)
		return
	}
    log.Printf("Received message type '%s' from %s to %s. Text: '%s'", msg.Type, msg.From, msg.To, msg.Payload.Text)
    if msg.Payload.Latitude != 0 && msg.Payload.Longitude != 0 { // Check if coordinates are present
        log.Printf("Location: Lat: %f, Lon: %f", msg.Payload.Latitude, msg.Payload.Longitude)
    }

	clientsMutex.Lock()
	recipientConns, isOnline := clients[msg.To]
	clientsMutex.Unlock()

	if isOnline && len(recipientConns) > 0 {
		log.Printf("[MSG] Recipient %s is online. Sending direct message from %s.", msg.To, msg.From)
		clientsMutex.Lock()
		for conn := range recipientConns {
			if err := conn.WriteJSON(msg); err != nil {
				log.Printf("[ERROR] Failed to send direct message from %s to %s: %v", msg.From, msg.To, err)
			}
		}
		clientsMutex.Unlock()
	} else {
		log.Printf("[MSG] Recipient %s is offline. Storing pending message from %s in DB.", msg.To, msg.From)
		go dbSavePendingMessage(msg)
		go sendDirectMessageThroughFirebase(msg)
	}
}

// broadcastMessageToUser sends a message to all active connections of a specific user.
// The excludeConn parameter is used to prevent echoing a message back to its source.
func broadcastMessageToUser(userID string, msg Message, excludeConn *websocket.Conn) {
	clientsMutex.Lock()
	defer clientsMutex.Unlock()

	if conns, found := clients[userID]; found {
		log.Printf("[BROADCAST] Broadcasting message type '%s' to %d connections for user %s", msg.Type, len(conns), userID)
		for conn := range conns {
			if conn != excludeConn {
				if err := conn.WriteJSON(msg); err != nil {
					log.Printf("[ERROR] Broadcast failed for user %s: %v", userID, err)
				}
			}
		}
	}
}
