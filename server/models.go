package main

import (
	"time"

	"github.com/gorilla/websocket"
)

// Message defines the structure for all real-time communications.
type Message struct {
	Type      string      `json:"type"`
	To        string      `json:"to,omitempty"`
	From      string      `json:"from,omitempty"`
	Payload   interface{} `json:"payload"`
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
