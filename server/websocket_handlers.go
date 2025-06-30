package main

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

const messageCooldown = 1 * time.Second

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

// handleWebSocket upgrades an HTTP connection to a WebSocket connection.
func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	userId := r.URL.Query().Get("userId")
	pseudo := r.URL.Query().Get("pseudo")
	log.Printf("[WS] Connection attempt from userId=%s, pseudo=%s, remoteAddr=%s", userId, pseudo, r.RemoteAddr)
	if userId == "" {
		log.Printf("[WS_ERROR] Connection failed: userId is missing from query. RemoteAddr=%s", r.RemoteAddr)
		http.Error(w, "userId is missing", http.StatusBadRequest)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("[ERROR] WebSocket upgrade failed for userId=%s, pseudo=%s: %v", userId, pseudo, err)
		return
	}
	defer func() {
		log.Printf("[WS] Closing WebSocket connection for userId=%s, pseudo=%s", userId, pseudo)
		conn.Close()
	}()

	clientsMutex.Lock()
	if clients[userId] == nil {
		clients[userId] = make(map[*websocket.Conn]bool)
	}
	hasOtherDevices := len(clients[userId]) > 0
	clients[userId][conn] = true
	log.Printf("[WS] Client %s (%s) connected. Total connections for user: %d. HasOtherDevices: %t", userId, pseudo, len(clients[userId]), hasOtherDevices)
	clientsMutex.Unlock()

	if pseudo != "" {
		log.Printf("[WS] Updating pseudo for userId=%s to '%s'", userId, pseudo)
		go dbSaveUserPseudo(userId, pseudo)
	}

	log.Printf("[WS] Delivering pending messages for userId=%s, if any.", userId)
	go dbSendPendingMessages(userId, conn) // Ensure conn is a type that dbSendPendingMessages expects, or adapt

	if hasOtherDevices {
		log.Printf("[WS] New device for userId=%s. Requesting sync from other devices.", userId)
		broadcastMessageToUser(userId, Message{Type: "sync_request", From: "server"}, conn) // Added 'From' for clarity
	}

	listenForMessages(conn, userId, pseudo)

	clientsMutex.Lock()
	delete(clients[userId], conn)
	remainingConnections := len(clients[userId])
	if remainingConnections == 0 {
		delete(clients, userId)
		log.Printf("[WS] Last client for user %s (%s) disconnected. Removing user from active list.", userId, pseudo)
	} else {
		log.Printf("[WS] Client for user %s (%s) disconnected. %d connections remaining for this user.", userId, pseudo, remainingConnections)
	}
	clientsMutex.Unlock()
	log.Printf("[WS] Exiting handleWebSocket for userId=%s, pseudo=%s after client disconnection", userId, pseudo)
}

// listenForMessages reads messages from a WebSocket connection and routes them.
func listenForMessages(conn *websocket.Conn, fromUserId string, fromPseudo string) {
	log.Printf("[WS_READ_LOOP] Listening for messages from userId=%s (%s)", fromUserId, fromPseudo)
	defer log.Printf("[WS_READ_LOOP] Exiting message read loop for userId=%s (%s)", fromUserId, fromPseudo)

	for {
		messageType, p, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure, websocket.CloseNormalClosure) {
				log.Printf("[WS_READ_ERROR] Unexpected close error reading message from userId=%s (%s): %v. Closing connection.", fromUserId, fromPseudo, err)
			} else if websocket.IsCloseError(err, websocket.CloseNormalClosure, websocket.CloseGoingAway) {
				log.Printf("[WS_READ_INFO] Normal WebSocket close from userId=%s (%s): %v.", fromUserId, fromPseudo, err)
			} else {
				log.Printf("[WS_READ_ERROR] Error reading message from userId=%s (%s): %v. Closing connection.", fromUserId, fromPseudo, err)
			}
			break
		}
		log.Printf("[WS_RAW_MSG_RECV] Received raw message from userId=%s (%s). Type: %d, Size: %d bytes", fromUserId, fromPseudo, messageType, len(p))

		var msg Message
		if err := json.Unmarshal(p, &msg); err != nil {
			log.Printf("[WARN_UNMARSHAL] Failed to unmarshal message from userId=%s (%s): %v. Raw: %s", fromUserId, fromPseudo, err, string(p))
			continue
		}
		msg.From = fromUserId // Ensure 'From' is set correctly for subsequent logic
		log.Printf("[WS_MSG_RECV] Received structured message of type '%s' from userId=%s (%s) to userId=%s", msg.Type, msg.From, fromPseudo, msg.To)

		switch msg.Type {
		case "plop":
			handlePlopMessage(conn, msg, fromPseudo)
		case "sync_data_broadcast":
			log.Printf("[SYNC_RELAY] Relaying 'sync_data_broadcast' from userId=%s (%s) to their other devices.", msg.From, fromPseudo)
			broadcastMessageToUser(msg.From, msg, conn)
		case "ping":
			log.Printf("[WS_PING] Received 'ping' from userId=%s (%s).", msg.From, fromPseudo)
			// Optional: send a pong message if not handled by SetPongHandler
			// if err := conn.WriteMessage(websocket.PongMessage, nil); err != nil {
			// 	log.Printf("[ERROR] Failed to send pong to %s (%s): %v", msg.From, fromPseudo, err)
			// }
		default:
			log.Printf("[WARN_UNKNOWN_MSG] Unknown message type '%s' from userId=%s (%s)", msg.Type, msg.From, fromPseudo)
		}
	}
}

// handlePlopMessage processes a "plop" message, checking the cooldown and forwarding it.
func handlePlopMessage(conn *websocket.Conn, msg Message, fromPseudo string) {
	log.Printf("[PLOP_HANDLER] Processing 'plop' from userId=%s (%s) to userId=%s. Cooldown check...", msg.From, fromPseudo, msg.To)

	userLastMessageMutex.Lock()
	lastTime, found := userLastMessageTime[msg.From]
	canSendMessage := !found || time.Since(lastTime) > messageCooldown
	if canSendMessage {
		userLastMessageTime[msg.From] = time.Now()
	}
	userLastMessageMutex.Unlock()

	if canSendMessage {
		log.Printf("[PLOP_HANDLER] Cooldown PASSED for userId=%s (%s). Forwarding and sending ack.", msg.From, fromPseudo)
		ackPayload := MessagePayload{
			RecipientID: msg.To, // This field should exist in MessagePayload
			Text:        "plop_ack", // Optional: add some text to ack payload for clarity
		}
		ackMessage := Message{
			Type:    "message_ack",
			From:    "server", // Indicate ack is from server
			To:      msg.From, // Send ack back to the original sender of the plop
			Payload: ackPayload,
		}

		if err := conn.WriteJSON(ackMessage); err != nil {
			log.Printf("[ERROR_ACK] Could not send 'message_ack' to userId=%s (%s) for plop to %s: %v", msg.From, fromPseudo, msg.To, err)
		} else {
			log.Printf("[PLOP_ACK_SENT] Sent 'message_ack' for 'plop' to userId=%s (%s) regarding recipient %s", msg.From, fromPseudo, msg.To)
		}
		sendDirectMessage(msg) // Forward the original plop message
	} else {
		log.Printf("[WARN_COOLDOWN] Cooldown ACTIVE for userId=%s (%s). 'plop' message to %s ignored.", msg.From, fromPseudo, msg.To)
		// Optionally, inform the sender about the cooldown
		// cooldownInfoPayload := MessagePayload{Text: "Message cooldown active. Please wait."}
		// cooldownInfoMsg := Message{Type: "cooldown_notice", From: "server", To: msg.From, Payload: cooldownInfoPayload}
		// if err := conn.WriteJSON(cooldownInfoMsg); err != nil {
		// 	log.Printf("[ERROR_COOLDOWN_NOTICE] Failed to send 'cooldown_notice' to %s (%s): %v", msg.From, fromPseudo, err)
		// }
	}
}

// sendDirectMessage forwards a message to a recipient if they are online,
// otherwise it stores it as a pending message in the database.
func sendDirectMessage(msg Message) {
	if msg.To == "" {
		log.Printf("[WARN_SEND_DIRECT] Dropping direct message from userId=%s: recipient 'to' field is empty. MsgType: %s", msg.From, msg.Type)
		return
	}
	log.Printf("[SEND_DIRECT] Attempting to send message type '%s' from userId=%s to userId=%s. PayloadText: '%s'", msg.Type, msg.From, msg.To, msg.Payload.Text)
	if msg.Payload.Latitude != 0 || msg.Payload.Longitude != 0 { // Check if coordinates are present
		log.Printf("[SEND_DIRECT_LOCATION] Message from userId=%s to userId=%s includes location: Lat: %f, Lon: %f", msg.From, msg.To, msg.Payload.Latitude, msg.Payload.Longitude)
	}

	clientsMutex.Lock()
	recipientConnsMap, isOnline := clients[msg.To]
	connsToSend := make([]*websocket.Conn, 0, len(recipientConnsMap)) // Buffer with expected size
	if isOnline {
		for conn := range recipientConnsMap {
			connsToSend = append(connsToSend, conn)
		}
	}
	clientsMutex.Unlock()

	if isOnline && len(connsToSend) > 0 {
		log.Printf("[MSG_DELIVERY] Recipient %s is ONLINE with %d connections. Sending direct message type '%s' from %s.", msg.To, len(connsToSend), msg.Type, msg.From)
		successCount := 0
		for i, conn := range connsToSend { // Log which connection if multiple
			if err := conn.WriteJSON(msg); err != nil {
				log.Printf("[ERROR_SEND_DIRECT] Failed to send direct message from userId=%s to userId=%s (device %d/%d): %v", msg.From, msg.To, i+1, len(connsToSend), err)
			} else {
				successCount++
			}
		}
		log.Printf("[MSG_DELIVERY_STATUS] Successfully sent to %d/%d devices for recipient %s from %s for message type '%s'.", successCount, len(connsToSend), msg.To, msg.From, msg.Type)
	} else {
		log.Printf("[MSG_DELIVERY] Recipient %s is OFFLINE for message type '%s' from %s. Storing pending message.", msg.To, msg.Type, msg.From)
		go dbSavePendingMessage(msg)
		go sendDirectMessageThroughFirebase(msg) // Ensure this function also has adequate logging
	}
}

// broadcastMessageToUser sends a message to all active connections of a specific user.
// The excludeConn parameter is used to prevent echoing a message back to its source.
func broadcastMessageToUser(userID string, msg Message, excludeConn *websocket.Conn) {
	clientsMutex.Lock()
	userConnsMap, found := clients[userID]
	connsToBroadcast := make([]*websocket.Conn, 0, len(userConnsMap))
	if found {
		for conn := range userConnsMap {
			if conn != excludeConn {
				connsToBroadcast = append(connsToBroadcast, conn)
			}
		}
	}
	clientsMutex.Unlock()

	sourceInfo := "from other device"
	if excludeConn == nil {
		sourceInfo = "server initiated"
	}

	if len(connsToBroadcast) > 0 {
		log.Printf("[BROADCAST] Broadcasting message type '%s' (%s) to %d connections for userId=%s.", msg.Type, sourceInfo, len(connsToBroadcast), userID)
		successCount := 0
		for i, conn := range connsToBroadcast {
			if err := conn.WriteJSON(msg); err != nil {
				log.Printf("[ERROR_BROADCAST] Broadcast failed for one connection (device %d/%d) of userId=%s: %v", i+1, len(connsToBroadcast), userID, err)
			} else {
				successCount++
			}
		}
		log.Printf("[BROADCAST_STATUS] Successfully broadcast message type '%s' to %d/%d connections for userId=%s.", msg.Type, successCount, len(connsToBroadcast), userID)
	} else {
		log.Printf("[BROADCAST] No connections found (or all excluded) to broadcast message type '%s' for userId=%s (%s).", msg.Type, userID, sourceInfo)
	}
}
