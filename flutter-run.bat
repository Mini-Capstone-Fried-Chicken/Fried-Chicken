@echo off
REM Helper script to run Flutter commands with API keys loaded from .env
REM Usage: flutter-run.bat run
REM        flutter-run.bat build apk

setlocal enabledelayedexpansion

REM Resolve the real Flutter executable from PATH and avoid local wrapper recursion
set "THIS_SCRIPT=%~f0"
set "PROJECT_FLUTTER_WRAPPER=%~dp0flutter.bat"
set "FLUTTER_SDK="
for /f "delims=" %%F in ('where flutter 2^>nul') do (
    if /I not "%%~fF"=="%THIS_SCRIPT%" if /I not "%%~fF"=="%PROJECT_FLUTTER_WRAPPER%" (
        set "FLUTTER_SDK=%%~fF"
        goto flutter_found
    )
)

:flutter_found
if "%FLUTTER_SDK%"=="" (
    echo [ERROR] Could not find a Flutter SDK executable in PATH.
    echo Ensure Flutter is installed and added to PATH.
    exit /b 1
)

REM Only apply dart-defines to commands that support build/run options
if "%1"=="run" goto load_env
if "%1"=="build" goto load_env
if "%1"=="drive" goto load_env
goto run_flutter

 :load_env
REM Check if .env file exists
if not exist .env (
    echo [WARNING] .env file not found in %CD%
    echo [WARNING] Running without API key dart-defines.
    goto run_flutter
)

REM Load environment variables from .env
set "GOOGLE_DIRECTIONS_API_KEY="
set "GOOGLE_PLACES_API_KEY="
set "CLARITY_PROJECT_ID="

echo Loading API keys from .env file...
for /f "usebackq delims=" %%x in (.env) do (
    set "line=%%x"
    
    REM Skip empty lines and comments
    if not "!line!"=="" if not "!line:~0,1!"=="REM" if not "!line:~0,1!"=="#" (
        REM Parse the line as KEY=VALUE
        for /f "tokens=1,2 delims==" %%a in ("!line!") do (
            set "temp_key=%%a"
            set "temp_value=%%b"
            
            REM Trim spaces from key
            for /f "tokens=* delims= " %%i in ("!temp_key!") do set "temp_key=%%i"
            
            REM Trim spaces from value
            for /f "tokens=* delims= " %%i in ("!temp_value!") do set "temp_value=%%i"
            
            REM Set the variable in current scope
            set "!temp_key!=!temp_value!"
            
            REM Debug output
            if "!temp_key:~0,6!"=="GOOGLE" echo   ✓ !temp_key! loaded
            if "!temp_key!"=="CLARITY_PROJECT_ID" echo   ✓ !temp_key! loaded
        )
    )
)

REM Verify API keys are loaded
echo.
echo Verifying API keys:
if "!GOOGLE_DIRECTIONS_API_KEY!"=="" (
    echo   ✗ GOOGLE_DIRECTIONS_API_KEY is EMPTY - Route directions won't work
) else (
    echo   ✓ GOOGLE_DIRECTIONS_API_KEY loaded
)

if "!GOOGLE_PLACES_API_KEY!"=="" (
    echo   ✗ GOOGLE_PLACES_API_KEY is EMPTY - Place search won't work
) else (
    echo   ✓ GOOGLE_PLACES_API_KEY loaded
)

if "!CLARITY_PROJECT_ID!"=="" (
    echo   i CLARITY_PROJECT_ID is EMPTY - Clarity is disabled
) else (
    echo   ✓ CLARITY_PROJECT_ID loaded
)

echo.
echo Running: flutter %*
echo   With GOOGLE_DIRECTIONS_API_KEY=!GOOGLE_DIRECTIONS_API_KEY!
echo   With GOOGLE_PLACES_API_KEY=!GOOGLE_PLACES_API_KEY!
echo   With CLARITY_PROJECT_ID=!CLARITY_PROJECT_ID!
echo.

REM Build optional dart-define arguments only when keys exist
set "EXTRA_ARGS="
if not "!GOOGLE_DIRECTIONS_API_KEY!"=="" set "EXTRA_ARGS=!EXTRA_ARGS! --dart-define=GOOGLE_DIRECTIONS_API_KEY=!GOOGLE_DIRECTIONS_API_KEY!"
if not "!GOOGLE_PLACES_API_KEY!"=="" set "EXTRA_ARGS=!EXTRA_ARGS! --dart-define=GOOGLE_PLACES_API_KEY=!GOOGLE_PLACES_API_KEY!"
if not "!CLARITY_PROJECT_ID!"=="" set "EXTRA_ARGS=!EXTRA_ARGS! --dart-define=CLARITY_PROJECT_ID=!CLARITY_PROJECT_ID!"

goto execute_flutter

:run_flutter
echo.
echo Running: flutter %*
echo.
set "EXTRA_ARGS="

:execute_flutter
REM Run Flutter with API keys as dart-define parameters
call "%FLUTTER_SDK%" %* !EXTRA_ARGS!
exit /b !errorlevel!

endlocal
