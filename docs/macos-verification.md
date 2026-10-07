# Verifying a rebuilt macOS app

Run these checks on macOS before uploading a new DMG. Linux shell checks and
mocked packaging tests cannot verify TCC permissions, Metal rendering, signing,
or notarization. A rebuilt app must be released before download users receive
any signing fixes.

## Signing and microphone access (#8)

`assets/Ghostty.entitlements` matches upstream
[`macos/Ghostty.entitlements` at b699ea7](https://github.com/ghostty-org/ghostty/blob/b699ea79f4b881421b4b3055abc16a0957d76beb/macos/Ghostty.entitlements).
It includes microphone, camera, Apple events, contacts, calendars, location, and
photos permissions. Recheck this list when updating the upstream app. The build
re-signs the app with `--deep` and verifies the whole bundle with `--deep --strict`.

```bash
SKIP_DMG=1 ./build.sh /Applications/Ghostty.app
codesign --verify --deep --strict 'Cute Ghostty.app'
codesign -d --entitlements :- 'Cute Ghostty.app'
plutil -extract NSMicrophoneUsageDescription raw -o - 'Cute Ghostty.app/Contents/Info.plist'
```

Confirm `com.apple.security.device.audio-input` is true. Launch the rebuilt app,
then run the reporter's reproduction in a disposable Python environment inside
it (with a working input device selected):

```bash
python3 -m venv /tmp/cuteghostty-mic-test
/tmp/cuteghostty-mic-test/bin/pip install sounddevice numpy
/tmp/cuteghostty-mic-test/bin/python - <<'PY'
import numpy as np
import sounddevice as sd
audio = sd.rec(44100, samplerate=44100, channels=1, dtype='int16')
sd.wait()
print('Recorded nonzero samples:', bool(np.any(audio)))
PY
```

Speak during recording and allow the microphone prompt. Check System Settings →
Privacy & Security → Microphone if access was previously denied. Compare with
Terminal.app using the same input device. A true entitlement alone is not proof
that recording works. For a signed/notarized DMG, also verify it with
`xcrun stapler validate site/CuteGhostty.dmg` and assess the installed app with
`spctl --assess --type execute --verbose '/Applications/Cute Ghostty.app'`.

## CPU and memory (#5 and #6)

These reports are not resolved by the packaging changes alone. The repository
does not contain Ghostty's renderer source, and the recurring leak report does
not identify its installed release. First record the downloaded release, macOS
version, hardware, upstream version, and build number. Older Cute Ghostty builds
hard-coded `0.1 (1)` in Info.plist, so that label alone does not identify their
underlying Ghostty version. New builds retain the source app's metadata.

Compare stock Ghostty with Cute Ghostty built from that exact app. Use the same
config, font, theme, window dimensions, display refresh rate, and shell workload,
with shell integrations disabled for both. Test one app at a time, first at idle
and then under the same output workload. Repeat on the Intel Mac described in
#5; an Apple Silicon result does not settle an Intel/AMD rendering regression.

Confirm the rebuilt app contains neither `Contents/PlugIns/DockTilePlugin.plugin`
nor the `NSDockTilePlugIn` plist key. The previous removal addressed the original
leak report, but does not establish the cause of #6.

Record the exact PID from Activity Monitor for each run, then collect comparable
samples (replace `12345` with that PID):

```bash
PID=12345
for i in $(seq 1 60); do
  date -u
  ps -p "$PID" -o pid=,%cpu=,rss=,etime=,command=
  sleep 1
done
sample "$PID" 10 -file "$HOME/Desktop/ghostty-sample.txt"
vmmap -summary "$PID"
```

For a suspected leak, repeat the same sampling after an extended idle period and
after repeatedly opening/closing tabs; report duration and resident-memory
growth, not just one high-memory screenshot. Raw executable hashes can differ
because re-signing changes the embedded signature; a different hash alone does
not demonstrate a renderer change. Review logs for private information before
attaching them to an issue.
