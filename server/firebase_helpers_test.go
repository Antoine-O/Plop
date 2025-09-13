
package main

import (
	"testing"
)

func TestInitializeFirebase(t *testing.T) {
	// This is a basic test case.
	// A more comprehensive test would require mocking firebase services.
	initializeFirebase()
	if firebaseApp == nil {
		t.Errorf("Firebase app should not be nil after initialization")
	}
}
