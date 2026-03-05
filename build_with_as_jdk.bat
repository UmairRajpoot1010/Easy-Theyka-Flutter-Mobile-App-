@echo off
setlocal

:: Set Java 17
set JAVA_HOME=C:\Program Files\Java\jdk-17
set PATH=%JAVA_HOME%\bin;%PATH%

:: Verify Java version
java -version

:: Clean and build
call flutter clean
call flutter pub get
call flutter build apk --release

endlocal 