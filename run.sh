#!/bin/bash

FILE_LOCK="/tmp/supertinywhisper.lock"
FILE_PID="/tmp/supertinywhisper.pid"
FILE_OPENAI_API_KEY="$HOME/.config/supertinywhisper/openai_api_key"

TEXT_TYPE_DELAY=30
TEXT_CLEAR_DELAY=10

MSG_RECORDING="Recording..."
MSG_RECORDING_LENGTH=${#MSG_RECORDING}
MSG_RECORDING_STOP="Press once again to stop."
MSG_RECORDING_STOP_LENGTH=${#MSG_RECORDING_STOP}
MSG_TRANSCRIBING="Transcribing..."
MSG_TRANSCRIBING_LENGTH=${#MSG_TRANSCRIBING}

text_type() {
    sleep 0.1  # Let window focus settle
    xdotool type --delay $TEXT_TYPE_DELAY "$1"
}

text_clear() {
    for ((i = 0; i < $1; i++)); do
        xdotool key --delay $TEXT_CLEAR_DELAY BackSpace
    done
}

transcribe_audio_file() {
    echo $(curl -s https://api.openai.com/v1/audio/transcriptions \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: multipart/form-data" \
        -F file="@$1" \
        -F model="gpt-4o-transcribe"
    )
}
ecord
# Load OpenAI API key from config file
if [ ! -f "$FILE_OPENAI_API_KEY" ]; then
    text_type "Failed with error: \"Please create $FILE_OPENAI_API_KEY with your OpenAI API key\"."
    exit 1
fi

OPENAI_API_KEY=$(cat "$FILE_OPENAI_API_KEY")

# Check for a lockfile (recording in progress)
if [ ! -f "$FILE_LOCK" ]; then
    # Start recording
    timestamp=$(date +%s)
    audio_file="/tmp/supertinywhisper_recording_${timestamp}.wav"

    echo "$audio_file" > "$FILE_LOCK"
    ffmpeg -f pulse -i default -y "$audio_file" 2>/dev/null &
    echo $! > "$FILE_PID"

    text_type "$MSG_RECORDING $MSG_RECORDING_STOP"
    exit 0
fi

# Stop recording (kill ffmpeg and wait for it to finish)
if [ -f "$FILE_PID" ]; then
    ffmpeg_pid=$(cat "$FILE_PID")

    if kill -TERM $ffmpeg_pid 2>/dev/null; then
        wait $ffmpeg_pid 2>/dev/null
    fi

    rm -f "$FILE_PID"
fi

# Remove the lockfile
audio_file=$(cat "$FILE_LOCK")
rm -f "$FILE_LOCK"

# Give ffmpeg time to finish writing the file
sleep 0.5

if [ ! -f "$audio_file" ]; then
    text_clear $MSG_RECORDING_STOP_LENGTH
    text_type "Failed with error \"no audio file\"."
    exit 1
fi

text_clear $((MSG_RECORDING_LENGTH + 1 + MSG_RECORDING_STOP_LENGTH))
text_type $MSG_TRANSCRIBING

api_response=$(transcribe_audio_file "$audio_file")
rm -f "$audio_file"

transcription=$(echo "$api_response" | jq -r ".text")
transcription_error=$(echo "$api_response" | jq -r ".error.message")

if [ -n "$transcription" ]; then
    text_clear $MSG_TRANSCRIBING_LENGTH
    text_type "$transcription"
    exit 0
elif [ -n "$transcription_error" ]; then
    text_type " Failed with error \"$transcription_error\"."
    exit 1
else
    text_type " Failed with an unknown error."
    exit 1
fi
