# --- Étape 1: Le "Builder" ---
# On utilise une image officielle de Go pour compiler notre application.
# 'alpine' est une version légère, ce qui accélère le téléchargement.
FROM golang:1.22-alpine AS builder

# Définit le répertoire de travail à l'intérieur du conteneur
WORKDIR /app

# Copie TOUS les fichiers du projet (go.mod, main.go, etc.)
# C'est la correction clé : on copie tout avant de gérer les dépendances.
COPY . .

# Utilise `go mod tidy` pour télécharger les dépendances et créer/synchroniser le fichier go.sum.
# Maintenant, cette commande peut voir les 'import' dans main.go et fonctionnera correctement.
RUN go mod tidy

# Compile l'application Go.
# CGO_ENABLED=0 crée un binaire statique, sans dépendre des librairies C du système.
# -o /server_binary spécifie le nom et l'emplacement du fichier de sortie.
RUN CGO_ENABLED=0 go build -o /server_binary

# --- Étape 2: L'image Finale ---
# On part d'une image "scratch", qui est une image complètement vide.
# C'est l'image la plus légère et la plus sécurisée possible, car elle ne contient rien d'autre que notre application.
FROM scratch

# Copie uniquement le binaire compilé depuis l'étape "builder"
COPY --from=builder /server_binary /server_binary

# Expose le port 8080 pour que l'on puisse s'y connecter depuis l'extérieur du conteneur
EXPOSE 8080

# La commande à exécuter lorsque le conteneur démarre.
# On lance simplement notre binaire.
ENTRYPOINT ["/server_binary"]
