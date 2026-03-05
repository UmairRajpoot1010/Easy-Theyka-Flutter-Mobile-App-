@echo off
echo Getting SHA-1 and SHA-256 keys...
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
pause 