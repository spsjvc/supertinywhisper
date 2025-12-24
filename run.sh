#!/bin/bash

FILE_LOCK="/tmp/supertinywhisper-lock.json"
FILE_OPENAI_API_KEY="$HOME/.config/supertinywhisper/openai_api_key"

notify() {
    # Send a notification via notify-send if available
    if command -v notify-send &> /dev/null; then
        notify-send --replace-id="69420" "supertinywhisper" "$1"
    fi
}

text_type() {
    xdotool type --delay 1 "$1"
}

stop_recording() {
    ffmpeg_pid=$(cat "$FILE_LOCK" | jq -r ".ffmpeg_pid")

    # Kill ffmpeg and wait for it to finish
    if kill -TERM $ffmpeg_pid 2>/dev/null; then
        wait $ffmpeg_pid 2>/dev/null
    fi
}

transcribe_audio_file() {
    echo $(curl -s https://api.openai.com/v1/audio/transcriptions \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: multipart/form-data" \
        -F file="@$1" \
        -F model="gpt-4o-mini-transcribe"
    )
}

# Load OpenAI API key from config file
if [ ! -f "$FILE_OPENAI_API_KEY" ]; then
    notify "Error: Please create $FILE_OPENAI_API_KEY with your OpenAI API key."
    exit 1
fi

OPENAI_API_KEY=$(cat "$FILE_OPENAI_API_KEY")

# Handle cancellation
if [ "$1" = "--cancel" ]; then
    if [ -f "$FILE_LOCK" ]; then
        stop_recording

        recording_file=$(cat "$FILE_LOCK" | jq -r ".recording_file")

        rm -f "$FILE_LOCK"
        rm -f "$recording_file"

        notify "Recording... Cancelled."
    fi

    exit 0
fi

# Check for a lockfile (recording in progress)
if [ ! -f "$FILE_LOCK" ]; then
    recording_started_at=$(date +%s%3N)
    recording_file="/tmp/supertinywhisper_recording_${recording_started_at}.ogg"

    # Start recording with options optimized for speech:
    #   -f pulse                        PulseAudio input format
    #   -i default                      System default audio input device
    #   -c:a libopus -application voip  Opus codec optimized for voice applications
    #   -ac 1                           Single channel
    #   -ar 16000                       16kHz sample rate
    #   -b:a 32k -vbr on                32 kbps target bitrate with variable bitrate enabled
    ffmpeg \
        -f pulse \
        -i default \
        -c:a libopus -application voip \
        -ac 1 \
        -ar 16000 \
        -b:a 32k -vbr on \
        "$recording_file" &
    ffmpeg_pid=$!

    # Create the json lockfile
    echo "{ \"ffmpeg_pid\": $ffmpeg_pid, \"recording_file\": \"$recording_file\", \"recording_started_at\": $recording_started_at }" > "$FILE_LOCK"

    notify "Recording... Press once again to stop."
    exit 0
fi

stop_recording

recording_file=$(cat "$FILE_LOCK" | jq -r ".recording_file")
recording_started_at=$(cat "$FILE_LOCK" | jq -r ".recording_started_at")
recording_duration_ms=$(($(date +%s%3N) - recording_started_at))

# Remove the lockfile
rm -f "$FILE_LOCK"

# Wait for ffmpeg to finish writing the file
while [ ! -s "$recording_file" ]; do
    sleep 0.05
done

notify "Recording... Transcribing..."
api_response=$(transcribe_audio_file "$recording_file")
notify "Recording... Transcribing... Done."

rm -f "$recording_file"

transcription=$(echo "$api_response" | jq -r ".text")
transcription_error=$(echo "$api_response" | jq -r ".error.message")

if [ -n "$transcription" ]; then
    text_type "$transcription"
    exit 0
elif [ -n "$transcription_error" ]; then
    notify "Error: $transcription_error."
    exit 1
else
    notify "Error: Unknown error."
    exit 1
fi
