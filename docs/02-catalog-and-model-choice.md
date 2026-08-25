# 2. Catalog and model choice

<p align="center">
<a href="/docs/01-overview.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/03-building-the-modelcar.md">Next</a>
</p>

### Objectives (~15 min)

- Find audio / speech-to-text models in the OpenShift AI 3.4 model catalog.
- Contrast catalog **turbo** Whisper (fast STT) with **`openai/whisper-large-v3`** (native translation).
- Leave with a deliberate choice: build a large-v3 modelcar for this workshop.

### Rationale

- The catalog is the product discovery story. Shipping turbo because it is “the Whisper on the shelf” silently drops `/v1/audio/translations`. vLLM documents that **`whisper-large-v3-turbo` does not support translating**.

### Takeaways

- Catalog is for **discovery and validated STT**, not automatically the right weights for translation.
- Native Whisper translation is **speech → English**, and it requires a non-turbo checkpoint (this lab: `openai/whisper-large-v3`).
- You will still deploy through the same vLLM NVIDIA GPU runtime as other generative models.

Official UI: [Discover, evaluate, register, and deploy models from the model catalog](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/working_with_the_model_catalog/index). Upstream constraint: [vLLM translations API](https://docs.vllm.ai/en/latest/serving/online_serving/speech_to_text/#translations-api).

## Open the catalog

1. Log in to the OpenShift AI dashboard.
2. Go to **AI hub → Models → Catalog** (wording may be **AI Hub → Catalog** depending on the build).
3. Filter or search: **audio**, **speech**, **whisper**, or task **audio-to-text**.
4. Open a Whisper card (often a **turbo** or FP8/w4a16 validated variant from Red Hat AI).

- [ ] You can see at least one Whisper / ASR model in the catalog.
- [ ] Note the **model type** (generative) and the suggested serving runtime (vLLM NVIDIA GPU).

Do **not** deploy from the catalog for the rest of this workshop unless you are only demonstrating STT. If the card is turbo / large-v3-turbo, skip Deploy.

## Why not turbo for this briefing

| | Catalog turbo (typical) | `openai/whisper-large-v3` (this workshop) |
|--|-------------------------|-------------------------------------------|
| Task | Transcription | Transcription **and** translation-to-English |
| `/v1/audio/translations` | Not supported | Supported |
| Size / VRAM | Smaller, faster | Larger; plan **16 GB+** GPU |
| Story | “Validated STT from the catalog” | “We own the weights as a modelcar” |

Red Hat publishes optimized turbo modelcars (for example FP8-dynamic) that are excellent for **private transcription**. They are the wrong default when the customer title is **translation**.

## Decision for Topics 3–6

Serve **`openai/whisper-large-v3`** from an OCI modelcar you build (or that the facilitator pre-pushed). Same dashboard and YAML path as Granite; different `storageUri` and vLLM args (`--max-model-len=448`, modest `--max-num-seqs`).

Optional later: deploy catalog turbo **in addition** if you have a second GPU and want a latency contrast — not required.

## Hands-on (~10 min)

- [ ] Walk the catalog filters with the customer: task, accelerator, license.
- [ ] Open a turbo Whisper card and read the description. Ask: “Does this mention translation?”
- [ ] Write down the runtime the catalog would pick (vLLM NVIDIA GPU). You will reuse that class of runtime, not that image of weights.

## Demo talking points

- “Catalog is how a data scientist finds a **supported** ASR model in 3.4 — that is the AI hub story.”
- “Turbo is the latency SKU. Large-v3 is the SKU that still speaks the OpenAI **translations** API.”
- “We are not fighting the catalog. We are choosing weights that match the customer outcome.”

<p align="center">
<a href="/docs/01-overview.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/03-building-the-modelcar.md">Next</a>
</p>
