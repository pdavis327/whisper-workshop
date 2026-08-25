# 7. Troubleshooting and best practices

<p align="center">
<a href="/docs/06-workbench-inference.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/README.md">Next</a>
</p>

### Objectives

- Diagnose common failures when serving Whisper on the single-model platform.
- Leave with a short production checklist for speech workloads.

### Rationale

- Most incidents are image pull, GPU scheduling, vLLM OOM, or calling the **translations** API on a **turbo** checkpoint — not “Whisper quality.”

### Takeaways

- Start from `InferenceService` conditions, then predictor logs.
- Validate on the **route** with the same Bearer token production will use.
- Keep runtime image, `storageUri`, hardware profile, and `--max-num-seqs` aligned with a 16 GB+ GPU.

Longer symptom table: [troubleshooting](/docs/troubleshooting.md). Stretch: [broken deployment](/docs/challenges/broken_deployment.md).

## Typical pitfalls

| Symptom | Things to check |
|---------|-----------------|
| Predictor ImagePullBackOff | Modelcar URI, vLLM runtime image, pull secrets, Quay permissions |
| Pending / GPU | `nvidia.com/gpu` on the profile, taints, quota, 1 GPU free |
| CrashLoop / OOM | `--max-num-seqs`, `--gpu-memory-utilization`, `--max-model-len 448` |
| 4xx on `/v1/audio/translations` | Turbo weights; use `whisper-large-v3`. Confirm `GET /v1/models`. |
| 401 on curl/notebook | Token secret, extra newline on paste, route host |
| Empty / wrong transcript | Audio format (WAV/FLAC/MP3), `model=` ≠ served name |

```sh
oc describe inferenceservice whisper-large-v3 -n whisper-workshop
oc logs -n whisper-workshop -l serving.kserve.io/inferenceservice=whisper-large-v3 --tail=200 -c kserve-container
```

## Best practices

### When deploying

- Wire URI + runtime image + GPU profile before you tune latency.
- Pin a modelcar **tag** (or digest) you scanned; do not `latest` in a customer cluster.
- Exercise **transcription and translation** in the same change window so turbo does not ship by accident.

### When troubleshooting

- `PredictorReady` vs pod `Pending` vs `ImagePullBackOff` vs CrashLoop — treat them as different classes.
- Events expire; `describe` and logs are the record.
- A 200 on `/v1/models` with a 400 on `/v1/audio/translations` is almost always the **checkpoint**, not the Route.

## Optional exercise (~15–20 min)

- [ ] Apply the broken manifest in [challenges/broken_deployment.md](/docs/challenges/broken_deployment.md).
- [ ] Capture the condition; fix; confirm Ready.

<p align="center">
<a href="/docs/06-workbench-inference.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/README.md">Next</a>
</p>
