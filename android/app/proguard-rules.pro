# Ce fichier est utilisé par R8/ProGuard pour les builds "release".

# Les règles de base de Flutter sont déjà incluses automatiquement.

# Règles pour les librairies réseau communes comme OkHttp, que le package:http
# de Flutter peut utiliser en arrière-plan sur Android.
-keep class com.squareup.okhttp3.** { *; }
-keep interface com.squareup.okhttp3.** { *; }
-dontwarn com.squareup.okhttp3.**
-dontwarn okio.**