/**
 * @file API REST pour l'application, utilisant Cloud Functions (v2).
 * @description Chaque fonction est un endpoint HTTP sécurisé.
 */

const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2/options");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ region: "europe-west1" });

// --- Middleware d'Authentification ---
// Une fonction réutilisable pour valider le jeton et gérer CORS.
const authenticateAndHandleCors = async (req, res, handler) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  const idToken = req.headers.authorization?.split("Bearer ")[1];
  if (!idToken) {
    logger.warn("Requête non authentifiée (jeton manquant).");
    res.status(401).json({ error: "Unauthorized" });
    return;
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken; // Ajoute les infos de l'utilisateur à la requête
    await handler(req, res);
  } catch (error) {
    logger.error("Échec de la vérification du jeton", error);
    res.status(401).json({ error: "Unauthorized", details: error.message });
  }
};


// --- Endpoints de l'API ---

exports.loginWithSecretKey = onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*'); // Endpoint public, CORS ouvert
    if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Methods', 'POST');
        res.set('Access-Control-Allow-Headers', 'Content-Type');
        res.status(204).send('');
        return;
    }
    const { secretKey } = req.body;
    if (!secretKey) return res.status(400).json({ error: 'secretKey manquant.' });

    const uid = secretKey;
    const customToken = await admin.auth().createCustomToken(uid);
    res.status(200).json({ token: customToken });
});


/**
 * Crée un code d'invitation unique et temporaire.
 */
exports.createInvite = onRequest((req, res) => authenticateAndHandleCors(req, res, async (req, res) => {
    const { uid: creatorUid } = req.user;
    const creatorDoc = await db.collection("users").doc(creatorUid).get();
    if (!creatorDoc.exists) return res.status(404).json({error: "Profil créateur non trouvé."});

    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    let inviteCode;
    let codeExists = true;
    while(codeExists) {
        inviteCode = Array(6).fill(0).map(() => chars.charAt(Math.floor(Math.random() * chars.length))).join('');
        const existingInvite = await db.collection('invites').doc(inviteCode).get();
        if (!existingInvite.exists) codeExists = false;
    }

    const now = admin.firestore.Timestamp.now();
    const expiresAt = admin.firestore.Timestamp.fromMillis(now.toMillis() + 24 * 60 * 60 * 1000); // 24h

    const inviteData = { creatorUid, creatorUsername: creatorDoc.data().username, createdAt: now, expiresAt, status: 'active' };
    await db.collection('invites').doc(inviteCode).set(inviteData);

    logger.info(`Invitation ${inviteCode} créée par ${creatorUid}`);
    res.status(200).json({ inviteCode });
}));

/**
 * Accepte une invitation, créant une amitié mutuelle.
 */
exports.acceptInvite = onRequest((req, res) => authenticateAndHandleCors(req, res, async (req, res) => {
    const { inviteCode } = req.body;
    const { uid: accepterUid } = req.user;

    if (!inviteCode) return res.status(400).json({ error: 'inviteCode manquant.' });

    const inviteRef = db.collection('invites').doc(inviteCode.toUpperCase());
    const inviteDoc = await inviteRef.get();

    if (!inviteDoc.exists) return res.status(404).json({ error: "Ce code d'invitation est invalide." });

    const inviteData = inviteDoc.data();
    if (inviteData.creatorUid === accepterUid) return res.status(400).json({ error: "Vous ne pouvez pas accepter votre propre invitation." });
    if (inviteData.status !== 'active') return res.status(400).json({ error: "Ce code a déjà été utilisé ou révoqué." });
    if (inviteData.expiresAt.toMillis() < Date.now()) {
        await inviteRef.update({ status: 'expired' });
        return res.status(400).json({ error: "Ce code a expiré." });
    }

    const { creatorUid, creatorUsername } = inviteData;
    await db.runTransaction(async (t) => {
        const accepterRef = db.collection('users').doc(accepterUid);
        const creatorRef = db.collection('users').doc(creatorUid);
        t.update(accepterRef, { friends: admin.firestore.FieldValue.arrayUnion({ uid: creatorUid, sound: 'default' }) });
        t.update(creatorRef, { friends: admin.firestore.FieldValue.arrayUnion({ uid: accepterUid, sound: 'default' }) });
        t.update(inviteRef, { status: 'used', acceptedBy: accepterUid, acceptedAt: admin.firestore.FieldValue.serverTimestamp() });
    });

    logger.info(`Amitié créée entre ${creatorUid} et ${accepterUid}`);
    res.status(200).json({ success: true, message: `Vous êtes maintenant ami avec ${creatorUsername}!` });
}));


/**
 * Envoie une notification à un autre utilisateur.
 */
exports.sendYo = onRequest((req, res) => authenticateAndHandleCors(req, res, async (req, res) => {
    const { recipientUid, message } = req.body;
    const { uid: senderUid, name: senderName } = req.user;

    const recipientDoc = await db.collection("users").doc(recipientUid).get();
    if (!recipientDoc.exists) return res.status(404).json({ error: "Destinataire non trouvé." });

    const mutedUsers = recipientDoc.data().mutedUsers || [];
    if (mutedUsers.includes(senderUid)) {
      return res.status(200).json({ success: true, status: "muted" });
    }

    const notificationData = {
      senderName: senderName || "Quelqu'un",
      senderUid,
      message: message || "Yo!",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
    };
    await db.collection("users").doc(recipientUid).collection("notifications").add(notificationData);

    const deviceToken = recipientDoc.data().deviceToken;
    if (deviceToken) {
      await admin.messaging().send({
        notification: { title: notificationData.senderName, body: notificationData.message },
        token: deviceToken,
      }).catch(e => logger.error("FCM Send Error:", e));
    }

    res.status(200).json({ success: true, status: "sent" });
}));

/**
 * Endpoint pour les webhooks externes. Ne nécessite pas d'authentification utilisateur.
 */
exports.triggerNotification = onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') { /* ... CORS ... */ return res.status(204).send(''); }

    const apiKey = req.headers.authorization?.split("Bearer ")[1];
    if (!apiKey) return res.status(401).send("Unauthorized: Missing API Key.");

    const apiKeyDoc = await db.collection("apiKeys").doc(apiKey).get();
    if (!apiKeyDoc.exists || !apiKeyDoc.data().isEnabled) return res.status(403).send("Forbidden: Invalid API Key.");

    const { ownerUid, contactName } = apiKeyDoc.data();
    let messageToSend = "Yo!";
    if (req.method === "POST" && req.body && req.body.message) {
      messageToSend = req.body.message;
    }

    const userDoc = await db.collection("users").doc(ownerUid).get();
    if (!userDoc.exists) return res.status(404).send("User not found.");

    const deviceToken = userDoc.data().deviceToken;
    if (deviceToken) {
      await admin.messaging().send({
        notification: { title: contactName, body: messageToSend },
        token: deviceToken,
      });
    }

    res.status(200).send("Notification sent successfully.");
});
/**
 * Met à jour le token de l'appareil (deviceToken) pour l'utilisateur authentifié.
 * Ce token est utilisé pour envoyer des notifications push.
 */
exports.updateDeviceToken = onRequest((req, res) => authenticateAndHandleCors(req, res, async (req, res) => {
    const uid = req.user.uid;
    const { token, platform } = req.body;

    if (!token) {
        logger.warn(`Tentative de mise à jour avec un token vide pour l'UID: ${uid}`);
        return res.status(400).json({ error: 'Le token est manquant.' });
    }

    logger.info(`Mise à jour du deviceToken pour l'UID: ${uid} sur la plateforme: ${platform || 'inconnue'}`);

    const userRef = db.collection('users').doc(uid);

    await userRef.update({
        deviceToken: token,
        platform: platform || 'inconnue',
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });

    res.status(200).json({ success: true, message: 'Token mis à jour.' });
}));


/**
 * Crée le profil utilisateur après l'onboarding.
 * Reçoit un nom d'utilisateur et l'associe à l'UID de l'utilisateur authentifié.
 */
exports.createUserProfile = onRequest((req, res) => authenticateAndHandleCors(req, res, async (req, res) => {
    const uid = req.user.uid;
    const { username } = req.body;

    if (!username || username.trim().length < 3) {
        logger.warn(`Tentative de création de profil avec un nom invalide pour l'UID: ${uid}`);
        return res.status(400).json({ error: 'Le nom d\'utilisateur doit contenir au moins 3 caractères.' });
    }

    logger.info(`Début de la création de profil pour l'UID: ${uid} avec le pseudo: ${username}`);

    const userRef = db.collection('users').doc(uid);
    const usernameRef = db.collection('usernames').doc(username.toLowerCase());

    // Utilise une transaction pour garantir que le pseudo n'est pas pris PENDANT la création.
    try {
        await db.runTransaction(async (t) => {
            const usernameDoc = await t.get(usernameRef);
            if (usernameDoc.exists) {
                // On lance une erreur pour être attrapée par le bloc catch.
                throw new Error('Username already taken.');
            }

            const newUser = {
                uid: uid,
                username: username,
                defaultMessage: 'Yo!',
                customMessages: ['J\'arrive !', 'En route', 'Appelle-moi'],
                friends: [],
                mutedUsers: [],
                deviceToken: null,
            };

            t.set(usernameRef, { uid: uid });
            t.set(userRef, newUser);
        });

        logger.log(`Profil créé avec succès pour ${uid}.`);
        res.status(201).json({ success: true, message: 'Profil créé.' });

    } catch (err) {
        logger.error(`Échec de la transaction de création de profil pour ${uid}:`, err);
        if (err.message === 'Username already taken.') {
            res.status(409).json({ error: 'Ce pseudo est déjà utilisé.' }); // 409 Conflict
        } else {
            res.status(500).json({ error: 'Une erreur interne est survenue.' });
        }
    }
}));


exports.updateDeviceToken = onRequest((req, res) => authenticateAndHandleCors(req, res, async (req, res) => {
    const uid = req.user.uid;
    const { token, platform } = req.body;

    if (!token) {
        logger.warn(`Tentative de mise à jour avec un token vide pour l'UID: ${uid}`);
        return res.status(400).json({ error: 'Le token est manquant.' });
    }

    logger.info(`Mise à jour du deviceToken pour l'UID: ${uid} sur la plateforme: ${platform || 'inconnue'}`);

    const userRef = db.collection('users').doc(uid);

    try {
        await userRef.update({
            deviceToken: token,
            platform: platform || 'inconnue',
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
        res.status(200).json({ success: true, message: 'Token mis à jour.' });
    } catch (error) {
        logger.error(`Échec de la mise à jour du token pour ${uid}:`, error);
        res.status(500).json({ error: 'Une erreur interne est survenue.' });
    }
}));


// ... (dans functions/index.js)
const crypto = require('crypto'); // On utilise le module crypto de Node.js

// Middleware pour valider notre propre jeton de session
const authenticateSession = async (req, res, handler) => {
    // ... (Logique CORS)
    const sessionToken = req.headers.authorization?.split("Bearer ")[1];
    if (!sessionToken) return res.status(401).json({ error: "Unauthorized" });

    // TODO: Implémenter une vraie validation de jeton (ex: via une collection 'sessions' dans Firestore ou JWT)
    // Pour ce test, nous allons supposer que le token est l'UID de l'utilisateur (Clé Secrète)
    const uid = sessionToken;
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) return res.status(401).json({ error: "Unauthorized" });

    req.user = { uid: uid }; // On attache l'UID à la requête
    await handler(req, res);
};

exports.loginWithSecretKey = onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    const { secretKey } = req.body;
    if (!secretKey) return res.status(400).json({ error: 'secretKey manquant.' });

    // Pour ce test, le "jeton de session" est simplement la clé secrète elle-même.
    // Dans une vraie application, on générerait un JWT (JSON Web Token) ici.
    const sessionToken = secretKey;
    const uid = secretKey;

    // On s'assure que le profil existe (ou on le crée)
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
        // On ne peut pas connaître le username ici, on crée un profil minimal
        await userRef.set({ uid: uid, username: 'Nouveau' });
    }

    res.status(200).json({ sessionToken: sessionToken, uid: uid });
});


/**
 * Récupère toutes les invitations actives créées par l'utilisateur authentifié.
 */
exports.getActiveInvites = onRequest((req, res) => authenticateAndHandleCors(req, res, async (req, res) => {
    const creatorUid = req.user.uid;
    logger.info(`Récupération des invitations actives pour ${creatorUid}`);

    const invitesSnapshot = await db.collection('invites')
        .where('creatorUid', '==', creatorUid)
        .where('status', '==', 'active')
        .orderBy('createdAt', 'desc')
        .get();

    if (invitesSnapshot.empty) {
        return res.status(200).json({ invites: [] });
    }

    const invites = invitesSnapshot.docs.map(doc => {
        const data = doc.data();
        return {
            id: doc.id,
            ...data,
            // Conversion des Timestamps en chaînes ISO 8601 pour une transmission JSON standard
            createdAt: data.createdAt.toDate().toISOString(),
            expiresAt: data.expiresAt.toDate().toISOString(),
        };
    });

    res.status(200).json({ invites });
}));


/**
 * Révoque une invitation spécifique.
 */
exports.revokeInvite = onRequest((req, res) => authenticateAndHandleCors(req, res, async (req, res) => {
    const { inviteId } = req.body;
    const requesterUid = req.user.uid;

    if (!inviteId) {
        return res.status(400).json({ error: 'inviteId manquant.' });
    }

    logger.info(`Révocation de l'invitation ${inviteId} par ${requesterUid}`);
    const inviteRef = db.collection('invites').doc(inviteId);
    const inviteDoc = await inviteRef.get();

    if (!inviteDoc.exists) {
        return res.status(404).json({ error: 'Invitation non trouvée.' });
    }

    // Sécurité : Seul le créateur de l'invitation peut la révoquer.
    if (inviteDoc.data().creatorUid !== requesterUid) {
        logger.warn(`Tentative de révocation non autorisée de ${inviteId} par ${requesterUid}.`);
        return res.status(403).json({ error: 'Action non autorisée.' });
    }

    await inviteRef.update({ status: 'revoked' });

    res.status(200).json({ success: true, message: 'Invitation révoquée.' });
}));


/**
 * Récupère les profils complets des amis de l'utilisateur authentifié.
 */
exports.getFriends = onRequest((req, res) => authenticateAndHandleCors(req, res, async (req, res) => {
    const uid = req.user.uid;
    logger.info(`Récupération de la liste d'amis pour l'UID: ${uid}`);

    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
        logger.error(`Utilisateur non trouvé pour getFriends: ${uid}`);
        return res.status(404).json({ error: 'Utilisateur non trouvé.' });
    }

    const friendLinks = userDoc.data().friends || [];
    if (friendLinks.length === 0) {
        // C'est un cas normal, pas une erreur. On renvoie une liste vide.
        return res.status(200).json({ friends: [] });
    }

    // On extrait uniquement les UID de la liste d'amis
    const friendUids = friendLinks.map(link => link.uid);

    // Firestore permet de faire une requête 'in' pour récupérer plusieurs documents à la fois
    // Note: limité à 30 éléments par requête par défaut.
    const friendsSnapshot = await db.collection('users').where(admin.firestore.FieldPath.documentId(), 'in', friendUids).get();

    const friends = friendsSnapshot.docs.map(doc => {
        const data = doc.data();
        // On ne renvoie que les informations publiques, jamais les tokens ou autres données sensibles.
        return {
            uid: doc.id,
            username: data.username,
            defaultMessage: data.defaultMessage,
        };
    });

    res.status(200).json({ friends });
}));

/**
 * Récupère le profil complet de l'utilisateur actuellement authentifié.
 */
exports.getProfile = onRequest((req, res) => authenticateAndHandleCors(req, res, async (req, res) => {
    const { uid } = req.user;
    logger.info(`Récupération du profil pour l'UID: ${uid}`);

    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
        logger.error(`Utilisateur non trouvé pour getProfile: ${uid}`);
        return res.status(404).json({ error: 'Profil utilisateur non trouvé.' });
    }

    // On renvoie toutes les données du profil, car le client en a besoin
    res.status(200).json(userDoc.data());
}));
