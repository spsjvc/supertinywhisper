# supertinywhisper

A super tiny speech-to-text tool written in a few lines of Bash that records your audio, transcribes it, and types the resulting transcription directly into the active application. It's designed to be bound to a keyboard shortcut for seamless usage, and is built with common tools you likely already have installed on your computer.

## Requirements

- [ffmpeg](https://ffmpeg.org) - audio recording
- [curl](https://curl.se) - openai api calling
- [jq](https://jqlang.github.io/jq) - json processing
- [xdotool](https://github.com/jordansissel/xdotool) - keyboard automation on X11
- [libnotify](https://gitlab.gnome.org/GNOME/libnotify) - desktop notifications (optional)
