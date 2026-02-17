@echo off
REM This script intercepts flutter commands and adds API keys from .env
REM It allows you to run: flutter run (instead of: flutter-run.bat run)

setlocal enabledelayedexpansion

REM Set a proper PATH with essential system directories
set PATH=C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Windows;C:\Program Files\Git\cmd;C:\Users\lihai\Documents\Flutter\flutter\bin;%PATH%

REM Expected location of the real Flutter SDK
set FLUTTER_SDK=C:\Users\lihai\Documents\Flutter\flutter\bin\flutter.bat

REM Only process 'run', 'build', and 'drive' commands - pass others through unchanged
if "%1"=="" goto run_flutter
if "%1"=="help" goto run_flutter
if "%1"=="--version" goto run_flutter
if "%1"=="-v" goto run_flutter
if "%1"=="doctor" goto run_flutter
if "%1"=="clean" goto run_flutter
if "%1"=="pub" goto run_flutter
if "%1"=="format" goto run_flutter
if "%1"=="analyze" goto run_flutter

REM Check if .env file exists for commands that need API keys
if "%1"=="run" goto load_env
if "%1"=="build" goto load_env
if "%1"=="drive" goto load_env

REM For any other command, just pass through to Flutter SDK
goto run_flutter

:run_flutter
if exist "%FLUTTER_SDK%" (
    call "%FLUTTER_SDK%" %*
    exit /b !errorlevel!
) else (
    echo [ERROR] Flutter SDK not found at %FLUTTER_SDK%
    exit /b 1
)

:load_env
REM Check if .env file exists
if not exist .env (
    echo.
    echo [ERROR] .env file not found in %CD%
    echo Please create .env file by copying from .env.example
    echo.
    echo Solution:
    echo   copy .env.example .env
    echo   [then edit .env and add your actual API keys]
    echo.
    exit /b 1
)

REM Load environment variables from .env
set "GOOGLE_DIRECTIONS_API_KEY="
set "GOOGLE_PLACES_API_KEY="

for /f "usebackq delims=" %%x in (.env) do (
    set "line=%%x"
    
    REM Skip empty lines and comments
    if not "!line!"=="" if not "!line:~0,1!"=="REM" if not "!line:~0,1!"=="#" (
        REM Parse the line as KEY=VALUE
        for /f "tokens=1,2 delims==" %%a in ("!line!") do (
            set "temp_key=%%a"
            set "temp_value=%%b"
            
            REM Trim spaces from key and value
            for /f "tokens=* delims= " %%i in ("!temp_key!") do set "temp_key=%%i"
            for /f "tokens=* delims= " %%i in ("!temp_value!") do set "temp_value=%%i"
            
            REM Set the API key variables
            if "!temp_key!"=="GOOGLE_DIRECTIONS_API_KEY" set "GOOGLE_DIRECTIONS_API_KEY=!temp_value!"
            if "!temp_key!"=="GOOGLE_PLACES_API_KEY" set "GOOGLE_PLACES_API_KEY=!temp_value!"
        )
    )
)

REM Verify API keys are loaded
echo [INFO] Loaded API keys from .env:
if "!GOOGLE_DIRECTIONS_API_KEY!"=="" (
    echo   [WARNING] GOOGLE_DIRECTIONS_API_KEY is empty
) else (
    echo   [OK] GOOGLE_DIRECTIONS_API_KEY loaded
)

if "!GOOGLE_PLACES_API_KEY!"=="" (
    echo   [WARNING] GOOGLE_PLACES_API_KEY is empty
) else (
    echo   [OK] GOOGLE_PLACES_API_KEY loaded
)

echo.
echo [INFO] Running: flutter %*
echo.

REM Call the real flutter with API keys
if exist "%FLUTTER_SDK%" (
    call "%FLUTTER_SDK%" %* ^
        --dart-define=GOOGLE_DIRECTIONS_API_KEY=!GOOGLE_DIRECTIONS_API_KEY! ^
        --dart-define=GOOGLE_PLACES_API_KEY=!GOOGLE_PLACES_API_KEY!
    exit /b !errorlevel!
) else (
    echo [ERROR] Could not find Flutter SDK at %FLUTTER_SDK%
    exit /b 1
)


