@echo off

setlocal

set "REPO_DIR=%~dp0"
set "DEFAULT_OLDER_JAVA_HOME=%REPO_DIR%.java8"
set "OLDER_JAVA_HOME=%DEFAULT_OLDER_JAVA_HOME%"

if defined OLDER_JAVA_HOME_OVERRIDE (
    set "OLDER_JAVA_HOME=%OLDER_JAVA_HOME_OVERRIDE%"
)

if exist "%OLDER_JAVA_HOME%\bin\java.exe" goto found_java

echo Older Java runtime not found at "%OLDER_JAVA_HOME%".
if exist "%DEFAULT_OLDER_JAVA_HOME%\bin\java.exe" (
    set "OLDER_JAVA_HOME=%DEFAULT_OLDER_JAVA_HOME%"
    goto found_java
)

echo Downloading OpenJDK 8 into "%DEFAULT_OLDER_JAVA_HOME%"...
set "OLDER_JAVA_DOWNLOAD_URL=https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u492-b09/OpenJDK8U-jdk_x64_windows_hotspot_8u492b09.zip"
if defined OLDER_JAVA_DOWNLOAD_URL_OVERRIDE (
    set "OLDER_JAVA_DOWNLOAD_URL=%OLDER_JAVA_DOWNLOAD_URL_OVERRIDE%"
)
set "JDK_ZIP=%TEMP%\openjdk8.zip"
set "JDK_TMP=%TEMP%\openjdk8tmp"

if exist "%JDK_ZIP%" del /q "%JDK_ZIP%"
if exist "%JDK_TMP%" rd /s /q "%JDK_TMP%"
mkdir "%JDK_TMP%" >nul 2>&1

powershell.exe -NoLogo -NoProfile -Command "Write-Host 'Downloading %OLDER_JAVA_DOWNLOAD_URL%'; Invoke-WebRequest -Uri '%OLDER_JAVA_DOWNLOAD_URL%' -OutFile '%JDK_ZIP%' -UseBasicParsing; Write-Host 'Extracting %JDK_ZIP%'; Expand-Archive -Path '%JDK_ZIP%' -DestinationPath '%JDK_TMP%' -Force; exit $LASTEXITCODE"
if errorlevel 1 (
    echo.
    echo ERROR: Failed to download or extract OpenJDK 8.
    exit /b 1
)

set "EXTRACTED_JDK="
for /d %%A in ("%JDK_TMP%\*") do set "EXTRACTED_JDK=%%~A"
if not defined EXTRACTED_JDK (
    echo ERROR: Could not find JDK folder after extraction.
    exit /b 1
)

if exist "%DEFAULT_OLDER_JAVA_HOME%" rd /s /q "%DEFAULT_OLDER_JAVA_HOME%"
move "%EXTRACTED_JDK%" "%DEFAULT_OLDER_JAVA_HOME%" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Failed to move downloaded JDK into "%DEFAULT_OLDER_JAVA_HOME%".
    exit /b 1
)

del /q "%JDK_ZIP%" >nul 2>&1
rd /s /q "%JDK_TMP%" >nul 2>&1
set "OLDER_JAVA_HOME=%DEFAULT_OLDER_JAVA_HOME%"

:found_java
if not exist "%OLDER_JAVA_HOME%\bin\java.exe" (
    echo ERROR: Older Java runtime still not found at "%OLDER_JAVA_HOME%".
    exit /b 1
)

set "JAVA_HOME=%OLDER_JAVA_HOME%"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo Using older Java from %JAVA_HOME%
if "%*" == "" (
    echo No Gradle task provided; defaulting to "build".
    set "ARGS=build"
) else (
    set "ARGS=%*"
)
set "PLAYERGLOBAL_FILE=%REPO_DIR%libs\playerglobal11_6.swc"
if not exist "%PLAYERGLOBAL_FILE%" (
    set "PLAYERGLOBAL_FILE=%REPO_DIR%libs\playerglobal.swc"
)
if exist "%PLAYERGLOBAL_FILE%" (
    echo Found local playerglobal file: %PLAYERGLOBAL_FILE%
    set "ARGS=%ARGS% -PplayerglobalFile=%PLAYERGLOBAL_FILE%"
)
call "%REPO_DIR%gradlew.bat" %ARGS%
endlocal
