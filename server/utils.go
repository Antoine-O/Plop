package main

import (
	"crypto/rand"
	"log"
	"os"
)

// --- Utility Functions ---

// debugLog prints a log message only if the DEBUG environment variable is set.
func debugLog(format string, v ...interface{}) {
	if os.Getenv("DEBUG") != "" {
		log.Printf("[DEBUG] "+format, v...)
	}
}

// generateRandomCode creates a random alphanumeric string of a given length.
func generateRandomCode(length int) string {
	const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789"
	b := make([]byte, length)
	if _, err := rand.Read(b); err != nil {
		log.Fatalf("[FATAL] Error generating random code: %v", err)
	}
	for i := 0; i < length; i++ {
		b[i] = chars[int(b[i])%len(chars)]
	}
	return string(b)
}

// intPtr returns a pointer to an integer value.
// Useful for optional fields in structs, like the APNS badge.
func intPtr(i int) *int {
	return &i
}

// extractPayloadText safely gets the text content from a message payload.
func extractPayloadText(payload interface{}) string {
	switch p := payload.(type) {
	case map[string]interface{}:
		if text, ok := p["text"].(string); ok {
			return text
		}
		return "You received a plop!" // Default if "text" key is missing
	case string:
		return p
	default:
		return "You received a notification."
	}
}
