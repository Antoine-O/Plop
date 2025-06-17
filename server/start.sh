#!/bin/sh
sed -e "s/___PROJECT_ID___/$PROJECT_ID/g" serviceAccountKeyTemplate.json > serviceAccountKey.json
sed -i -e "s/___PRIVATE_KEY_ID___/$PRIVATE_KEY_ID/g" serviceAccountKey.json
sed -i -e "s|___PRIVATE_KEY___|$PRIVATE_KEY|g" serviceAccountKey.json
sed -i -e "s/___CLIENT_EMAIL___/$CLIENT_EMAIL/g" serviceAccountKey.json
sed -i -e "s/___CLIENT_ID___/$CLIENT_ID/g" serviceAccountKey.json
sed -i -e "s|___CLIENT_X509_CERT_URL___|$CLIENT_X509_CERT_URL|g" serviceAccountKey.json


if [ "$DEBUG" = "true" ]; then cat serviceAccountKey.json; fi


/root/server_binary