## Post-processing in Go

### File tagging

- [ ] Create `tag-files` Go binary for detecting file references
  - [ ] Pass in a file index with `tag-files --index` or `tag-files --index-path`
- [ ] Create comprehensive tests for different cases
- [ ] Enable and use file tagging in `run.sh` with a hardcoded index
- [ ] Enable storing a directory index to a file and loading it via its path
- [ ] Enable auto-detecting which index file to use based on where supertinywhisper is being used
  - [ ] We can do `xdotool getwindowfocus getwindowname` and see if that includes any of the indexed directories
