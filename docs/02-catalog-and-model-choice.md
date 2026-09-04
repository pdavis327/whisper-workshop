# 2. Catalog and model choice

<p align="center">
<a href="/docs/01-overview.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/03-building-the-modelcar.md">Next</a>
</p>

### Objectives (~15 min)

- Find audio / speech-to-text models in the OpenShift AI 3.5 model catalog.
- Contrast catalog **turbo** Whisper (fast **STT (speech-to-text)**) with **Whisper large** (native translation) and **Voxtral** (a different speech model family).
- Leave with a deliberate choice: build a large-v3 modelcar for this workshop.

### Rationale

- The catalog is the product discovery story. Shipping turbo because it is “the Whisper on the shelf” silently drops `/v1/audio/translations`. vLLM documents that **`whisper-large-v3-turbo` does not support translating**.

### Takeaways

- Catalog is for **discovery and validated STT**, not automatically the right weights for translation.
- Native Whisper translation is **speech → English**, and it requires a non-turbo checkpoint (this lab: `openai/whisper-large-v3`).
- You will still deploy through the same vLLM NVIDIA GPU runtime as other generative models.

Official UI: [Discover, evaluate, register, and deploy models from the model catalog](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/html-single/working_with_the_model_catalog/index). Upstream constraint: [vLLM translations API](https://docs.vllm.ai/en/latest/serving/online_serving/speech_to_text/#translations-api).

## Open the catalog

1. Log in to the OpenShift AI dashboard.
2. Go to **AI hub → Models → Catalog**.
3. Filter or search: **audio**, **speech**, **whisper**, **voxtral**, or task **audio-to-text**.
4. Open the audio cards you find. In 3.5 you should see **Whisper large**, **turbo** variants, and **Voxtral** — not a turbo-only shelf.

- [ ] You can see Whisper large, a turbo variant, and Voxtral in the catalog (names vary by quantization: FP8, w4a16, and similar).
- [ ] Note the **model type** (generative) and the suggested serving runtime (vLLM NVIDIA GPU).

Do **not** deploy **turbo** or **Voxtral** for the rest of this workshop. If a card is turbo / large-v3-turbo, skip Deploy — it will not serve `/v1/audio/translations`. Voxtral is a Mistral speech model (often chat or realtime APIs), not a drop-in for Whisper’s OpenAI audio endpoints. Catalog **Whisper large** (not turbo) is a valid translations path for a customer who wants validated weights; this lab still builds a modelcar so you own the image.

## Why not turbo for this briefing

| | Catalog turbo | Catalog Whisper large / `openai/whisper-large-v3` | Catalog Voxtral |
|--|---------------|-----------------------------------------------------|-----------------|
| Task | Transcription (STT) | Transcription **and** translation-to-English | Speech understanding / transcription; different API |
| `/v1/audio/translations` | Not supported | Supported | Not the Whisper translations API |
| Size / VRAM | Smaller, faster | Larger; plan **16 GB+** GPU | Check the card; not this lab’s runtime args |
| Story | “Validated STT from the catalog” | “Native OpenAI audio APIs, including translation” | “Voice-agent / understanding model on the same platform” |

Red Hat publishes optimized turbo modelcars (for example FP8-dynamic) that are excellent for **private transcription**. They are the wrong default when the customer title is **translation**.

Voxtral belongs in a different conversation (voice agents, audio understanding, sometimes streaming). Do not pick it because it sits next to Whisper in the catalog.

## Decision for Topics 3–6

Serve **`openai/whisper-large-v3`** from an OCI modelcar you build (or that the facilitator pre-pushed). Same dashboard and YAML path as Granite; different `storageUri` and vLLM args (`--max-model-len=448`, modest `--max-num-seqs`).

Optional later: deploy catalog turbo **in addition** if you have a second GPU and want a latency contrast — not required. Catalog Whisper large is the honest “we used the catalog” shortcut when translation matters.

## Hands-on (~10 min)

- [ ] Walk the catalog filters with the customer: task, accelerator, license.
- [ ] Open a turbo Whisper card and read the description. Ask: “Does this mention translation?”
- [ ] Open a Whisper **large** card (not turbo). Confirm it is the non-turbo checkpoint.
- [ ] Open a Voxtral card. Ask: “Does this expose `/v1/audio/transcriptions` and `/v1/audio/translations`, or a different API?”
- [ ] Write down the runtime the catalog would pick (vLLM NVIDIA GPU). You will reuse that class of runtime, not turbo or Voxtral weights.

## Demo talking points

- “Catalog is how a data scientist finds a **supported** ASR model in 3.5 — that is the AI hub story.”
- “3.5 put Whisper large and Voxtral on the shelf. Turbo is still the latency SKU. Large-v3 is the SKU that still speaks the OpenAI **translations** API.”
- “Voxtral is a speech model, not a Whisper clone. We are not fighting the catalog. We are choosing weights that match the customer outcome.”

<p align="center">
<a href="/docs/01-overview.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/03-building-the-modelcar.md">Next</a>
</p>
