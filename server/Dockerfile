# --- Étape 1: Le "Builder" ---
# On utilise une image officielle de Go pour compiler notre application.
# 'alpine' est une version légère, ce qui accélère le téléchargement.
FROM golang:1.24-alpine AS builder

# Définit le répertoire de travail à l'intérieur du conteneur
WORKDIR /app

# Copie TOUS les fichiers du projet (go.mod, main.go, etc.)
# C'est la correction clé : on copie tout avant de gérer les dépendances.
COPY . .

# Utilise `go mod tidy` pour télécharger les dépendances et créer/synchroniser le fichier go.sum.
# Maintenant, cette commande peut voir les 'import' dans main.go et fonctionnera correctement.
RUN go mod tidy
ARG PROJECT_ID
ARG PRIVATE_KEY_ID
ARG PRIVATE_KEY
ARG CLIENT_EMAIL
ARG CLIENT_ID
ARG CLIENT_X509_CERT_URL
# Compile l'application Go.
# CGO_ENABLED=0 crée un binaire statique, sans dépendre des librairies C du système.
# -o /server_binary spécifie le nom et l'emplacement du fichier de sortie.
RUN CGO_ENABLED=0 go build -o /server_binary


COPY serviceAccountKeyTemplate.json serviceAccountKey.json

#RUN sed "s/___PROJECT_ID___/$PROJECT_ID/g" serviceAccountKey.json
#RUN sed "s/___PRIVATE_KEY_ID___/$PRIVATE_KEY_ID/g" serviceAccountKey.json
#RUN sed "s/___PRIVATE_KEY___/$PRIVATE_KEY/g" serviceAccountKey.json
#RUN sed "s/___CLIENT_EMAIL___/$CLIENT_EMAIL/g" serviceAccountKey.json
#RUN sed "s/___CLIENT_ID___/$CLIENT_ID/g" serviceAccountKey.json
#RUN sed "s/___CLIENT_X509_CERT_URL___/$CLIENT_X509_CERT_URL/g" serviceAccountKey.json




# --- Étape 2: L'image Finale ---
# On part d'une image "scratch", qui est une image complètement vide.
# C'est l'image la plus légère et la plus sécurisée possible, car elle ne contient rien d'autre que notre application.
FROM alpine

WORKDIR root
# Copie uniquement le binaire compilé depuis l'étape "builder"
COPY --from=builder /server_binary /root/server_binary

COPY serviceAccountKeyTemplate.json /root/serviceAccountKeyTemplate.json

COPY start.sh /root/start.sh

RUN chmod +x /root/start.sh

# Expose le port 8080 pour que l'on puisse s'y connecter depuis l'extérieur du conteneur
EXPOSE 8080

# La commande à exécuter lorsque le conteneur démarre.
# On lance simplement notre binaire.
ENTRYPOINT ["/root/start.sh"]
