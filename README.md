# supertinywhisper

A super tiny speech-to-text tool for Linux.

It's written in a few lines of Bash, and built with common tools you likely already have installed on your computer.

## How it Works

**supertinywhisper** records your audio using [ffmpeg](https://ffmpeg.org) (with settings optimized for speech), transcribes it using the [OpenAI API](https://platform.openai.com/docs/api-reference/audio/createTranscription), and types the resulting transcription directly into your active application. It works both on X11 ([xdotool](https://github.com/jordansissel/xdotool)) and Wayland ([wtype](https://github.com/atx/wtype)).

For best experience, bind it to a global keyboard shortcut.

## Requirements

- [ffmpeg](https://ffmpeg.org) - audio recording
- [curl](https://curl.se) - openai api calling
- [jq](https://jqlang.github.io/jq) - json processing
- [xdotool](https://github.com/jordansissel/xdotool) - keyboard automation on X11
- [wtype](https://github.com/atx/wtype) - keyboard automation on Wayland
- [libnotify](https://gitlab.gnome.org/GNOME/libnotify) - desktop notifications (optional)
