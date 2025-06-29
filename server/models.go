package main

import (
	"time"

	"github.com/gorilla/websocket"
)
type MessagePayload struct {
	Text      string  `json:"text"`
	Latitude  float64 `json:"latitude,omitempty"`  // Use omitempty if location is optional
	Longitude float64 `json:"longitude,omitempty"`
	RecipientID string      `json:"recipientId,omitempty"`
	UserID string      `json:"userId,omitempty"`
	Pseudo string      `json:"pseudo,omitempty"`
	// Add other fields from your payload as needed
}
// Message defines the structure for all real-time communications.
type Message struct {
	Type      string      `json:"type"`
	To        string      `json:"to,omitempty"`
	From      string      `json:"from,omitempty"`
	Payload   MessagePayload `json:"payload"` // Changed from interface{} or string
	IsDefault bool        `json:"isDefault,omitempty"`
	IsPending bool        `json:"isPending,omitempty"`
	// SourceConn is used internally to avoid echoing messages back to the sender.
	SourceConn *websocket.Conn `json:"-"`
}

// Invitation represents a time-limited code to connect two users.
type Invitation struct {
	Code          string
	CreatorUserID string
	CreatorPseudo string
	ExpiresAt     time.Time
}

// SyncCode represents a time-limited code for a user to sync a new device.
type SyncCode struct {
	Code      string
	UserID    string
	ExpiresAt time.Time
}
