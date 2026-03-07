#!/bin/bash
# Helper script to run Flutter commands with API keys loaded from .env

# Load environment variables from .env
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo "Error: .env file not found!"
    echo "Please create .env file by copying from .env.example"
    exit 1
fi

# Run Flutter command with environment variables
flutter "$@" \
    --dart-define=GOOGLE_DIRECTIONS_API_KEY=$GOOGLE_DIRECTIONS_API_KEY \
    --dart-define=GOOGLE_PLACES_API_KEY=$GOOGLE_PLACES_API_KEY \
    --dart-define=CLARITY_PROJECT_ID=$CLARITY_PROJECT_ID
