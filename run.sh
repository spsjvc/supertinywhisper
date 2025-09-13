#!/bin/bash

FILE_LOCK="/tmp/supertinywhisper-lock.json"
FILE_OPENAI_API_KEY="$HOME/.config/supertinywhisper/openai_api_key"

TEXT_TYPE_DELAY=1
TEXT_CLEAR_DELAY=2.5

MSG_RECORDING="Recording..."
MSG_RECORDING_WORDS=1
MSG_RECORDING_STOP="Press once again to stop."
MSG_RECORDING_STOP_WORDS=5
MSG_TRANSCRIBING="Transcribing..."
MSG_TRANSCRIBING_WORDS=1

text_type() {
    sleep 0.2 # Let window focus settle
    xdotool type --delay $TEXT_TYPE_DELAY "$1"
}

text_clear() {
    for ((i = 0; i < $1; i++)); do
        xdotool key --delay $TEXT_CLEAR_DELAY BackSpace
    done
}

should_use_alt_backspace() {
    window_class_using_alt_backspace=("com.mitchellh.ghostty" "kitty")
    window_class_active=$(xdotool getactivewindow getwindowclassname)

    for window_class in "${window_class_using_alt_backspace[@]}"; do
        if [[ "$window_class_active" == "$window_class" ]]; then
            return 0
        fi
    done

    return 1
}

text_clear_words() {
    if should_use_alt_backspace; then
        key_combo="alt+BackSpace"
    else
        key_combo="ctrl+BackSpace"
    fi

    for ((i = 0; i < $1; i++)); do
        xdotool key --delay $TEXT_CLEAR_DELAY "$key_combo"
    done
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
    text_type "Failed with error: \"Please create $FILE_OPENAI_API_KEY with your OpenAI API key\"."
    exit 1
fi

OPENAI_API_KEY=$(cat "$FILE_OPENAI_API_KEY")

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

    text_type "$MSG_RECORDING $MSG_RECORDING_STOP"
    exit 0
fi

# Stop recording (kill ffmpeg and wait for it to finish)
ffmpeg_pid=$(cat "$FILE_LOCK" | jq -r ".ffmpeg_pid")

if kill -TERM $ffmpeg_pid 2>/dev/null; then
    wait $ffmpeg_pid 2>/dev/null
fi

recording_file=$(cat "$FILE_LOCK" | jq -r ".recording_file")
recording_started_at=$(cat "$FILE_LOCK" | jq -r ".recording_started_at")
recording_duration_ms=$(($(date +%s%3N) - recording_started_at))

# Remove the lockfile
rm -f "$FILE_LOCK"

# Wait for ffmpeg to finish writing the file
while [ ! -s "$recording_file" ]; do
    sleep 0.05
done

text_clear_words $((MSG_RECORDING_WORDS + MSG_RECORDING_STOP_WORDS))
text_type $MSG_TRANSCRIBING

api_response=$(transcribe_audio_file "$recording_file")
rm -f "$recording_file"

transcription=$(echo "$api_response" | jq -r ".text")
transcription_error=$(echo "$api_response" | jq -r ".error.message")

if [ -n "$transcription" ]; then
    text_clear_words $MSG_TRANSCRIBING_WORDS
    text_type "$transcription"
    exit 0
elif [ -n "$transcription_error" ]; then
    text_type " Failed with error \"$transcription_error\"."
    exit 1
else
    text_type " Failed with an unknown error."
    exit 1
fi
