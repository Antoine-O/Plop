package main

import (
	"context"
	"log"
	"strconv"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

var firebaseApp *firebase.App

// initializeFirebase sets up the connection to the Firebase Admin SDK.
func initializeFirebase() {
	log.Println("[INFO] Initializing Firebase...")
	ctx := context.Background()
	opt := option.WithCredentialsFile("serviceAccountKey.json")
	var err error
	firebaseApp, err = firebase.NewApp(ctx, nil, opt)
	if err != nil {
		log.Fatalf("[FATAL] Error initializing Firebase app: %v\n", err)
	}
	log.Println("[INFO] Firebase initialized successfully.")
}

// sendDirectMessageThroughFirebase sends a push notification to an offline user's devices.
func sendDirectMessageThroughFirebase(msg Message) {
	log.Printf("[FCM] Attempting to send push notification from %s to %s.", msg.From, msg.To)

	deviceTokens, err := dbGetUserDeviceTokens(msg.To)
	if err != nil {
		log.Printf("[FCM] Error getting device tokens for user %s: %v", msg.To, err)
		return
	}

	if len(deviceTokens) == 0 {
		log.Printf("[FCM] No FCM tokens found for user %s. Aborting push notification.", msg.To)
		return
	}

	ctx := context.Background()
	client, err := firebaseApp.Messaging(ctx)
	if err != nil {
		log.Printf("[ERROR] Error getting FCM client: %v", err)
		return
	}

	senderPseudo, err := dbGetUserPseudo(msg.From)
	if err != nil {
		log.Printf("[FCM] Error getting pseudo for user %s: %v. Using fallback.", msg.From, err)
		senderPseudo = "Someone" // Fallback pseudo
	}
	if senderPseudo == "" {
		senderPseudo = "Someone"
	}

	notificationBody := extractPayloadText(msg.Payload)

	var tokensToRemove []string
	for _, token := range deviceTokens {
		fcmMessage := &messaging.Message{
			Notification: &messaging.Notification{Title: senderPseudo, Body: notificationBody},
			Data: map[string]string{
				"senderId":  msg.From,
				"payload":   notificationBody,
				"isDefault": strconv.FormatBool(msg.IsDefault),
			},
			Android: &messaging.AndroidConfig{
				Notification: &messaging.AndroidNotification{ChannelID: "plop_channel_id", Icon: "icon"},
			},
			APNS: &messaging.APNSConfig{
				Payload: &messaging.APNSPayload{
					Aps: &messaging.Aps{
						Alert: &messaging.ApsAlert{Title: senderPseudo, Body: notificationBody},
						Badge: intPtr(1),
						Sound: "plop.aiff",
					},
				},
			},
			Token: token,
		}

		_, err := client.Send(ctx, fcmMessage)
		if err != nil {
			log.Printf("[ERROR] FCM send failed for token %s: %v", token, err)
			if messaging.IsUnregistered(err) || messaging.IsInvalidArgument(err) {
				log.Printf("[INFO] Invalid FCM token %s detected. Scheduling for removal.", token)
				tokensToRemove = append(tokensToRemove, token)
			}
		} else {
			log.Printf("[FCM] Push notification sent successfully to token %s for user %s.", token, msg.To)
		}
	}

	if len(tokensToRemove) > 0 {
		removeInvalidTokens(msg.To, tokensToRemove)
	}
}

// removeInvalidTokens cleans up FCM tokens that are no longer valid from the database.
func removeInvalidTokens(userID string, tokensToRemove []string) {
	log.Printf("[INFO] Removing %d invalid tokens for user %s.", len(tokensToRemove), userID)

	currentTokens, err := dbGetUserDeviceTokens(userID)
	if err != nil {
		log.Printf("[ERROR] Could not get tokens for invalid token removal for user %s: %v", userID, err)
		return
	}

	if len(currentTokens) == 0 {
		return // Nothing to do
	}

	var validTokens []string
	for _, token := range currentTokens {
		isInvalid := false
		for _, tokenToRemove := range tokensToRemove {
			if token == tokenToRemove {
				isInvalid = true
				break
			}
		}
		if !isInvalid {
			validTokens = append(validTokens, token)
		}
	}

	go dbSaveUserDeviceTokens(userID, validTokens)
	log.Printf("[INFO] Finished removing invalid tokens for user %s. Remaining: %d.", userID, len(validTokens))
}
