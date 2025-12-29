# supertinywhisper

A super tiny speech-to-text tool.

It's written in a few lines of Bash, and built with common tools you likely already have installed.

## How it Works

**supertinywhisper** records your audio using [ffmpeg](https://ffmpeg.org) (with settings optimized for speech), transcribes it using the [OpenAI API](https://platform.openai.com/docs/api-reference/audio/createTranscription), and outputs the resulting transcription to standard output. You can then pipe that into other tools and compose it however you like!

## Dependencies

### Required

- [ffmpeg](https://ffmpeg.org) - audio recording
- [curl](https://curl.se) - api calling
- [jq](https://jqlang.github.io/jq) - json processing

### Optional

- [libnotify](https://gitlab.gnome.org/GNOME/libnotify) - desktop notifications

## Setup

1. Get your API key from [OpenAI Platform](https://platform.openai.com).

2. Create the config directory and add your API key:

```bash
mkdir -p ~/.config/supertinywhisper
echo "your-api-key-here" > ~/.config/supertinywhisper/openai_api_key
```

## Usage

For best experience, **supertinywhisper** should be bound to a keyboard shortcut and composed with other tools.

### Pipe to typing tools

```bash
# X11
supertinywhisper | xdotool type --clearmodifiers --file -

# Wayland
supertinywhisper | wtype -
```

### Pipe to clipboard

```bash
# X11
supertinywhisper | xclip -selection clipboard

# Wayland
supertinywhisper | wl-copy
```

### Cancel

```bash
supertinywhisper --cancel
```
