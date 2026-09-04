# 3. Build the Whisper modelcar

<p align="center">
<a href="/docs/02-catalog-and-model-choice.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/04-dashboard-deploy.md">Next</a>
</p>

### Objectives (~20 min; longer on first download)

- Download `openai/whisper-large-v3` from Hugging Face into a `models/` layout.
- Build an OCI **modelcar** (weights only, no runtime) with Podman.
- Push to a registry the cluster can pull; record `oci://quay.io/<org>/whisper-large-v3:1`.

### Rationale

- KServe modelcars are OCI images whose payload is `/models`. That is how OpenShift AI pulls generative weights without a separate S3 copy step. You own this image: air-gap, pin, and scan it like any other artifact.

### Takeaways

- Layout is `models/` at the image root (not `models/1/` — that versioned path is for some predictive runtimes, not vLLM).
- Weights are **not** in Git. They live under `scratch/model-build/` (ignored).
- For a live customer briefing, the facilitator should **pre-push** the image so the room does not wait on ~3 GB.

Official pattern: [Build and deploy a ModelCar container in OpenShift AI](https://developers.redhat.com/articles/2025/01/30/build-and-deploy-modelcar-container-openshift-ai). Platform storage: [Deploying models](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/html-single/deploying_models/index) (OCI / modelcar).

## Facilitator skip

If `oci://quay.io/<org>/whisper-large-v3:1` already exists and the cluster can pull it, record that URI and continue to [Topic 4](/docs/04-dashboard-deploy.md). Still walk the Containerfile so the customer sees what they would own.

## Prerequisites for this topic

- [ ] Podman (or Docker) on a machine that can reach Hugging Face and your registry
- [ ] Hugging Face access to [`openai/whisper-large-v3`](https://huggingface.co/openai/whisper-large-v3) (Apache 2.0)
- [ ] `huggingface-cli` or `huggingface_hub` (`pip install huggingface_hub`)
- [ ] Login to Quay (or your internal registry): `podman login quay.io`

## 1. Download weights into scratch

From the repository root:

```sh
mkdir -p scratch/model-build/models

huggingface-cli download openai/whisper-large-v3 \
  --local-dir scratch/model-build/models
```

Expect `config.json`, `model*.safetensors` (or shards), tokenizer / preprocessor files under `scratch/model-build/models/`.

- [ ] `ls scratch/model-build/models | head` shows Hugging Face layout, not an empty directory.

## 2. Build the modelcar

Containerfile: [`configs/samples/modelcar/Containerfile`](/configs/samples/modelcar/Containerfile). It copies `models/` to `/models` on UBI Micro and runs as UID `65534`.

```sh
podman build -f configs/samples/modelcar/Containerfile \
  -t whisper-large-v3:1 \
  scratch/model-build
```

- [ ] Build completes without errors.

## 3. Push and record the URI

```sh
podman tag whisper-large-v3:1 quay.io/<org>/whisper-large-v3:1
podman push quay.io/<org>/whisper-large-v3:1
```

Record:

```text
oci://quay.io/<org>/whisper-large-v3:1
```

OpenShift AI deploy forms and `InferenceService.spec.predictor.model.storageUri` use the `oci://` scheme (not `docker://`).

If the repository is **private**, create a dashboard **connection** (or pull secret) in Topic 4 so the predictor can pull.

## 4. Cluster pull (spot-check)

From a logged-in `oc` session, confirm nodes can resolve the registry. You will see ImagePullBackOff in Topic 4 if this URI is wrong, the tag was never pushed, or auth is missing.

## Exercise

- [ ] Weights are only under `scratch/` (not committed).
- [ ] Image pushed; `oci://…` written down for Topics 4–5.
- [ ] (Facilitator) Repository is public **or** a connection/pull secret is ready.

<p align="center">
<a href="/docs/02-catalog-and-model-choice.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/04-dashboard-deploy.md">Next</a>
</p>
