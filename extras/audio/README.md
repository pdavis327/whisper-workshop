# Sample audio

Short clips for [Topic 6](/docs/06-workbench-inference.md). They are **eSpeak NG** renderings (not studio voice), 16 kHz mono WAV, small enough to keep in Git.

| File | Language | Intended text |
|------|----------|----------------|
| `en-sample.wav` | English | “Welcome to OpenShift AI. This is a private speech transcription demonstration running on Red Hat OpenShift.” |
| `es-sample.wav` | Spanish | “Bienvenidos a OpenShift AI. Esta es una demostración de traducción de voz a inglés.” |

Use `en-sample.wav` with `/v1/audio/transcriptions` and `es-sample.wav` with `/v1/audio/translations` (expect **English** output).

## License

- Speech synthesis: [eSpeak NG](https://github.com/espeak-ng/espeak-ng) (GPLv3). These WAV files are workshop fixtures derived from that engine.
- You may replace them with your own recordings (WAV, FLAC, MP3, or OGG — whatever vLLM/librosa accepts).

## Regenerate

```sh
espeak-ng -v en-us -s 140 -w /tmp/whisper-en.wav "Welcome to OpenShift AI. This is a private speech transcription demonstration running on Red Hat OpenShift."
espeak-ng -v es -s 140 -w /tmp/whisper-es.wav "Bienvenidos a OpenShift AI. Esta es una demostración de traducción de voz a inglés."
ffmpeg -y -i /tmp/whisper-en.wav -ar 16000 -ac 1 -sample_fmt s16 extras/audio/en-sample.wav
ffmpeg -y -i /tmp/whisper-es.wav -ar 16000 -ac 1 -sample_fmt s16 extras/audio/es-sample.wav
```
