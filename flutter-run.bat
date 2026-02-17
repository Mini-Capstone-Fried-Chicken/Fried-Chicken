@echo off
REM Helper script to run Flutter commands with API keys loaded from .env
REM Usage: flutter-run.bat run
REM        flutter-run.bat build apk

setlocal enabledelayedexpansion

REM Check if .env file exists
if not exist .env (
    echo Error: .env file not found!
    echo Please create .env file by copying from .env.example
    echo.
    echo Example:
    echo   copy .env.example .env
    echo   (edit .env and add your actual API keys)
    exit /b 1
)

REM Load environment variables from .env
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
            if not "!temp_key:~0,6!"=="GOOGLE" goto skip_debug
            echo   ✓ !temp_key! loaded
            :skip_debug
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

echo.
echo Running: flutter %*
echo   With GOOGLE_DIRECTIONS_API_KEY=!GOOGLE_DIRECTIONS_API_KEY!
echo   With GOOGLE_PLACES_API_KEY=!GOOGLE_PLACES_API_KEY!
echo.

REM Run Flutter with API keys as dart-define parameters
flutter %* ^
    --dart-define=GOOGLE_DIRECTIONS_API_KEY=!GOOGLE_DIRECTIONS_API_KEY! ^
    --dart-define=GOOGLE_PLACES_API_KEY=!GOOGLE_PLACES_API_KEY!

endlocal
