# 1. Overview: on-prem speech and vLLM audio APIs

<p align="center">
<a href="/docs/00-setup.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/02-catalog-and-model-choice.md">Next</a>
</p>

Facilitator: clone the repo and present [docs/slides/value-prop.html](/docs/slides/value-prop.html) in a local browser (`n` toggles speaker notes). GitHub shows the HTML source, not the slides. This page is the same story for participants who are reading.

### Objectives (~15 min)

- Explain why speech-to-text often must stay inside the OpenShift cluster.
- Map Whisper on vLLM to OpenAI-compatible **audio** endpoints (not chat).
- Compare catalog, OCI modelcar, and PVC as ways to store the weights.

### Rationale

- Customers hear “real-time translation” and picture a SaaS mic in the browser. The platform story is: same OpenAI client code, **private** inference on KServe. Storage and API shape decide whether that story survives contact with GPUs and compliance.

### Takeaways

- Audio never needs to leave the cluster once Whisper is served on the single-model platform.
- vLLM exposes `/v1/audio/transcriptions` (speech → same language) and `/v1/audio/translations` (speech → **English only**). Native Whisper translation is not an arbitrary language pair.
- `stream=true` streams **tokens for a complete clip**. It is not continuous microphone ASR. After Topic 6, the optional [live-caption POC](/extras/live-caption/README.md) is the browser-mic path.

## Why on-prem ASR

**ASR (automatic speech recognition)** turns spoken audio into text. Cloud ASR sends that voice off-site. That is a non-starter for many of the rooms this workshop is built for — and it adds a round-trip you do not need when the recordings already live next to the cluster.

| Setting | Why the audio stays here |
|---------|--------------------------|
| Contact centers | Every call is customer PII; recordings already sit on the operator network |
| Dispatch / public safety | Radio and incident audio is regulated and time-critical |
| Telecom | Voice traffic and call recordings must stay on the carrier network |
| Healthcare | Patient speech is PHI |
| Financial services | Recorded advice and KYC calls |
| Public sector / air-gapped | No outbound API by design |
| Legal / HR | Privilege and personnel data |

**Latency is part of the sale, not only privacy.** Skipping a public-cloud ASR hop means you do not upload bulky audio over the WAN and wait for a SaaS queue. Transcription and speech-to-English run on the GPU beside the recordings. That end-to-end path is faster than “ship the call to the cloud and wait.” It is **not** a claim that `whisper-large-v3` decodes faster than a hyperscaler’s Whisper API — on the GPU, turbo is still the latency SKU; large-v3 is the SKU that still speaks `/v1/audio/translations`.

Whisper on OpenShift AI is the same class of workload as Granite on KServe: one `InferenceService`, one GPU, an OpenAI-compatible route, token auth. The difference is the payload: **multipart audio**, not JSON chat.

Product docs: [Deploying models on the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/html-single/deploying_models/index). Background: [Private transcription with Whisper and Red Hat AI](https://developers.redhat.com/articles/2026/03/06/private-transcription-whisper-red-hat-ai).

## What vLLM actually serves

```text
Client (notebook, curl, later a browser app)
        |  HTTPS + Bearer token
OpenShift Route
        |
KServe InferenceService  (RawDeployment)
        |
vLLM NVIDIA GPU container
        |  weights from OCI modelcar → /mnt/models
POST /v1/audio/transcriptions     speech → text (source language)
POST /v1/audio/translations       speech → English text
GET  /v1/models                   served-model-name
```

| Endpoint | Use in this workshop |
|----------|----------------------|
| `POST /v1/audio/transcriptions` | English (or any language) → transcript |
| `POST /v1/audio/translations` | Non-English speech → **English** |
| `GET /v1/models` | Confirm `id` to send as `model=` |

These are **not** `/v1/chat/completions`. Pointing an LLM playground at Whisper will fail. vLLM’s audio API is documented upstream: [Speech to Text APIs](https://docs.vllm.ai/en/latest/serving/online_serving/speech_to_text/).

Full diagram: [architecture](/docs/architecture.md).

## Storage options

| Approach | Typical use |
|----------|-------------|
| Model catalog | Discover Red Hat–validated audio models (Whisper large, turbo, Voxtral). Turbo is still the wrong pick for native translation. |
| OCI modelcar | Pack Hugging Face weights in `/models`; versioned, pull-at-serve-time |
| PVC | Upload from a workbench; fine for small artifacts, awkward for multi-gigabyte Whisper |

This workshop uses a **modelcar of `openai/whisper-large-v3`** so `/v1/audio/translations` works. Topic 2 shows the catalog so you can tell that story honestly.

## Hands-on (~10 min)

- [ ] In OpenShift AI: Projects → `whisper-workshop` → Deployments → start **Deploy model** without submitting.
- [ ] Note **Generative** vs **Predictive**. Whisper on vLLM is **generative**.
- [ ] Note model location fields: URI (`oci://…`), connection, catalog. You will use URI after Topic 3.

## Demo talking points

- “Same KServe path you use for Granite — different HTTP API.”
- “Translation in Whisper means **into English**, not Spanish ↔ German. Arbitrary target languages need a second LLM.”
- “We will prove serving with files in a workbench. The mic demo is [extras/live-caption](/extras/live-caption/README.md); the workbench pod cannot hear your laptop.”

<p align="center">
<a href="/docs/00-setup.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/02-catalog-and-model-choice.md">Next</a>
</p>
