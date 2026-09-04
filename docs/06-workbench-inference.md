# 6. Transcribe and translate from a workbench

<p align="center">
<a href="/docs/05-yaml-and-cli.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/07-troubleshooting-best-practices.md">Next</a>
</p>

### Objectives (~20 min)

- Call vLLM’s OpenAI-compatible **audio** APIs from a CPU workbench.
- Transcribe English audio and translate non-English audio **to English**.
- Use the same route and Bearer token that a production client would use.

### Rationale

- Data scientists validate serving from Jupyter, not only from `curl` on a laptop. The notebook is the proof that KServe + Whisper works before anyone builds a live-mic app.

### Takeaways

- The workbench **cannot** open the laptop microphone. Use bundled files or upload a recording.
- `stream=true` streams tokens for **one complete file**, not live ASR.
- `MODEL_NAME` must match an `id` from `GET /v1/models` (sample uses `whisper-large-v3`).

## Prerequisites

- [ ] `whisper-workshop` project with `InferenceService` `whisper-large-v3` Ready, external route, token auth (Topics 4 or 5).
- [ ] Secret `whisper-large-v3-sa` if you applied [`model-sa-token.yaml`](/configs/samples/model-deploy/model-sa-token.yaml). Dashboard-only deploys create a different token secret — copy that token instead.

## 1. Create a CPU workbench

This workbench is only an HTTP client. It does **not** need a GPU.

1. OpenShift AI → project `whisper-workshop` → **Workbenches** → **Create workbench**.
2. Name: e.g. `whisper-lab`.
3. Image: `Jupyter | Minimal | CPU | Python 3.12` (or Standard Data Science).
4. Hardware profile: **CPU / default** (not the GPU profile used by the model).
5. Cluster storage: default size.
6. Create and wait until **Running**. Open JupyterLab.

More detail: [Creating a project workbench](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/html/working_on_projects/using-project-workbenches_projects) (match the doc version to your cluster).

## 2. Copy the inference route

- [ ] Dashboard → Deployments → `whisper-large-v3` → copy the external endpoint.

Or:

```sh
oc get inferenceservice whisper-large-v3 -n whisper-workshop -o wide
```

Use `https://…` with **no** trailing slash in the notebook.

## 3. Copy the Bearer token

If you applied Topic 5 YAML:

```sh
oc extract secret/whisper-large-v3-sa -n whisper-workshop --keys=token --to=-
```

From the OpenShift console: Workloads → Secrets → project `whisper-workshop` → `whisper-large-v3-sa` → Data → `token`.

Dashboard-created tokens: open the deployment → authentication / token, or the secret named on the deployment.

## 4. Clone the repo in the workbench and open the notebook

In JupyterLab: File → New → Terminal:

```sh
cd /opt/app-root/src
git clone https://github.com/pdavis327/whisper-workshop.git
```

Open [`extras/notebooks/01-transcribe-translate.ipynb`](/extras/notebooks/01-transcribe-translate.ipynb).

Set `INFERENCE_BASE_URL`, `BEARER_TOKEN`, and `MODEL_NAME`. Run all cells:

1. `GET /v1/models`
2. Transcribe `extras/audio/en-sample.wav`
3. Translate `extras/audio/es-sample.wav` → English
4. Optional streaming
5. Optional file upload

## curl (if you skip Jupyter)

Replace `ROUTE`, `TOKEN`, and paths. Files are under `extras/audio/`.

```sh
ROUTE="https://whisper-large-v3-whisper-workshop.apps.example.com"
TOKEN="..."

curl -sk -H "Authorization: Bearer ${TOKEN}" "${ROUTE}/v1/models"

curl -sk -X POST "${ROUTE}/v1/audio/transcriptions" \
  -H "Authorization: Bearer ${TOKEN}" \
  -F "file=@extras/audio/en-sample.wav" \
  -F "model=whisper-large-v3"

curl -sk -X POST "${ROUTE}/v1/audio/translations" \
  -H "Authorization: Bearer ${TOKEN}" \
  -F "file=@extras/audio/es-sample.wav" \
  -F "model=whisper-large-v3"
```

Optional stream (tokens for the whole clip):

```sh
curl -sk -N -X POST "${ROUTE}/v1/audio/transcriptions" \
  -H "Authorization: Bearer ${TOKEN}" \
  -F "file=@extras/audio/en-sample.wav" \
  -F "model=whisper-large-v3" \
  -F "stream=true"
```

## Demo talking points

- “Nothing left the cluster except HTTPS to our own route.”
- “Spanish file in, English text out — that is Whisper `translations`, not a second LLM.”
- “Next increment is [extras/live-caption](/extras/live-caption/README.md) — a Route + `getUserMedia`. We did not fake a mic in Jupyter.”

## Hands-on exercise (~15–25 min)

- [ ] Workbench running; repo cloned.
- [ ] `/v1/models` returns 200 and lists `whisper-large-v3` (or the `id` you copy into `MODEL_NAME`).
- [ ] Transcription cell prints English text for `en-sample.wav`.
- [ ] Translation cell prints English text for `es-sample.wav`.

<p align="center">
<a href="/docs/05-yaml-and-cli.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/07-troubleshooting-best-practices.md">Next</a>
</p>
