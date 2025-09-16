package main

import (
	"testing"
)

func TestGenerateRandomCode(t *testing.T) {
	code := generateRandomCode(6)
	if len(code) != 6 {
		t.Errorf("generateRandomCode(6) returned a code with length %d, want 6", len(code))
	}
}

func TestIntPtr(t *testing.T) {
	val := 5
	ptr := intPtr(val)
	if *ptr != val {
		t.Errorf("intPtr(%d) returned a pointer to %d, want %d", val, *ptr, val)
	}
}

func TestExtractPayloadText(t *testing.T) {
	tests := []struct {
		name     string
		payload  interface{}
		expected string
	}{
		{"map with text", map[string]interface{}{"text": "hello"}, "hello"},
		{"map without text", map[string]interface{}{"foo": "bar"}, "Plop"},
		{"string payload", "world", "world"},
		{"other type", 123, "Plop"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := extractPayloadText(tt.payload)
			if result != tt.expected {
				t.Errorf("extractPayloadText(%v) returned %s, want %s", tt.payload, result, tt.expected)
			}
		})
	}
}
