# supertinywhisper

A super tiny speech-to-text tool written in a few lines of Bash that records your audio via ffmpeg, transcribes it via the OpenAI API, and types the resulting transcription directly into your active application. It's designed to be bound to a keyboard shortcut for seamless usage.

## Requirements

- [ffmpeg](https://ffmpeg.org) - audio recording
- [curl](https://curl.se) - openai api calling
- [jq](https://jqlang.github.io/jq) - json processing
- [xdotool](https://github.com/jordansissel/xdotool) - keyboard automation on X11
