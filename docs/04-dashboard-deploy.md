# 4. Deploy Whisper from the dashboard

<p align="center">
<a href="/docs/03-building-the-modelcar.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/05-yaml-and-cli.md">Next</a>
</p>

### Objectives (~20 min plus model load time)

- Deploy `whisper-large-v3` from the OpenShift AI dashboard onto the single-model platform.
- Select **Generative**, vLLM NVIDIA GPU, a GPU hardware profile, `oci://` URI, external route, and token authentication.
- Wait until the deployment is Ready and copy the inference endpoint.

### Rationale

- The dashboard is the path most data scientists take. Every field maps to an `InferenceService` / `ServingRuntime` annotation you will apply in [Topic 5](/docs/05-yaml-and-cli.md).

### Takeaways

- Whisper is **generative** on this platform (vLLM), not a predictive OpenVINO model.
- Token auth means every later `curl` or notebook call needs `Authorization: Bearer`.
- First start includes pulling the modelcar and loading encoder–decoder weights — budget several minutes on a cold node.

Deploying models: [OpenShift AI 3.4 — Deploying models](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/deploying_models/index).

## Open the Deploy model flow

Deploy into `whisper-workshop` from [Topic 0](/docs/00-setup.md).

1. OpenShift AI dashboard → **Projects**.
2. Open **Whisper Workshop** (`whisper-workshop`). If it is missing, switch the filter from AI projects to **All projects**, or ask the facilitator to run `bash scripts/setup.sh -s 1`.
3. Open the **Deployments** tab.
4. Click **Deploy model**.

## Model details

Use the modelcar URI from [Topic 3](/docs/03-building-the-modelcar.md).

1. **Name** / display name: `whisper-large-v3`
2. **Model type:** **Generative AI model** (not Predictive)
3. **Model location:** URI
4. **URI:** `oci://quay.io/<org>/whisper-large-v3:1` (your tag)
5. **Connection:** create or select a connection if the registry is private; skip if the image is public and the cluster can pull
6. **Model deployment name:** `whisper-large-v3`

## Serving runtime and hardware

1. **Serving runtime:** vLLM NVIDIA GPU ServingRuntime for KServe (wording may include “vLLM CUDA”). Do not pick OpenVINO or a CPU-only runtime.
2. **Hardware profile:** the cluster’s **GPU** profile (for example `nvidia-gpu`). Do not use a CPU-only profile. If no GPU profile appears, the facilitator must attach one — see [prerequisites](/docs/prerequisites.md). The sample YAML is [`configs/samples/hardware-profile/hardware-profile.yaml`](/configs/samples/hardware-profile/hardware-profile.yaml); prefer the profile already on the cluster.
3. **Accelerators:** 1× NVIDIA GPU.

Whisper-specific vLLM flags (`--max-model-len 448`, modest `--max-num-seqs`) are easier to set in YAML (Topic 5). If the dashboard exposes **additional serving runtime arguments**, add:

```text
--max-model-len=448
--max-num-seqs=8
--served-model-name=whisper-large-v3
```

Do **not** add `--task transcription` (it can hide the translations endpoint).

## Advanced

- [ ] Enable **Make available via an external route**
- [ ] Enable **Require token authentication**
- [ ] Review and **Deploy**

## Wait until Ready

- [ ] Deployments list shows the model **Started** / Ready.
- [ ] Open the deployment and copy the **external inference endpoint** (HTTPS, no trailing slash required; Topic 6 strips it anyway).
- [ ] Optional CLI:

```sh
oc get inferenceservice whisper-large-v3 -n whisper-workshop
oc get pods -n whisper-workshop -l serving.kserve.io/inferenceservice=whisper-large-v3
```

If the pod is `Pending` or `ImagePullBackOff`, jump to [troubleshooting](/docs/troubleshooting.md) — do not wait silently.

## Demo talking points

- “This is the same Deploy model wizard as Granite. The customer already knows this screen.”
- “Generative + vLLM is what turns Whisper into `/v1/audio/*` instead of a custom Flask app.”
- “Token on the route is the default enterprise posture — notebooks in Topic 6 use the same Bearer header.”

## Hands-on exercise (~20–30 min)

- [ ] Deploy `whisper-large-v3` from the dashboard with the Topic 3 `oci://` URI.
- [ ] Confirm Ready and save the route URL for Topic 6.
- [ ] If dashboard args cannot be set, you will overlay them in Topic 5 YAML.

<p align="center">
<a href="/docs/03-building-the-modelcar.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/05-yaml-and-cli.md">Next</a>
</p>
