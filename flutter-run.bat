@echo off
REM Helper script to run Flutter commands with API keys loaded from .env

REM Check if .env file exists
if not exist .env (
    echo Error: .env file not found!
    echo Please create .env file by copying from .env.example
    exit /b 1
)

REM Load environment variables from .env
for /f "delims=" %%x in (.env) do (
    if not "%%x"=="" (
        if "%%x:~0,1%%" neq "REM" (
            setlocal enabledelayedexpansion
            set "line=%%x"
            for /f "tokens=1,2 delims==" %%a in ("!line!") do (
                set "%%a=%%b"
            )
        )
    )
)

REM Run Flutter command with environment variables
flutter %* ^
    --dart-define=GOOGLE_DIRECTIONS_API_KEY=%GOOGLE_DIRECTIONS_API_KEY% ^
    --dart-define=GOOGLE_PLACES_API_KEY=%GOOGLE_PLACES_API_KEY%
