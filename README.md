# whisper-workshop

Hands-on workshop for real-time speech transcription and translation with [OpenAI Whisper](https://github.com/openai/whisper) on [Red Hat OpenShift AI Self-Managed 3.4](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4), using the single-model serving platform (KServe RawDeployment) and vLLM’s OpenAI-compatible audio APIs.

Audience: Data scientists, ML engineers, and platform admins. Prior experience with OpenShift projects and basic YAML is recommended. GPU literacy helps for the serving labs.

Duration: About 90 minutes for Topics 0–7.

Format: Short overview → live dashboard and CLI demonstrations → workbench inference → Q&A and troubleshooting.

If you are starting the workshop, open [the first set of instructions](/docs/00-setup.md). Architecture: [docs/architecture.md](/docs/architecture.md).

Namespace: All labs assume a single Data Science project / OpenShift namespace named `whisper-workshop`. Facilitators create it in Topic 0 with `bash scripts/setup.sh -s 1` (or `oc new-project whisper-workshop`).

## Learning outcomes

Participants should be able to:

- Explain why speech stays on-cluster (PII, regulated audio) and how vLLM exposes Whisper as OpenAI-compatible `/v1/audio/transcriptions` and `/v1/audio/translations`.
- Discover audio models in the OpenShift AI model catalog and know why catalog turbo variants are the wrong choice when you need native translation.
- Package `openai/whisper-large-v3` as an OCI modelcar and push it to a registry the cluster can pull.
- Deploy the model from the OpenShift AI dashboard (generative, vLLM NVIDIA GPU, token-authenticated route).
- Repeat the same deployment with `ServingRuntime` / `InferenceService` YAML for GitOps.
- Call transcription and speech-to-English translation from a CPU workbench notebook (and equivalent `curl`).
- Diagnose ImagePullBackOff, GPU Pending, vLLM OOM, and “translations on turbo” failures.

## Lab sequence

| Step | Topic |
|------|--------|
| [0 – Setup](/docs/00-setup.md) | Prerequisites, cluster access, project, optional automation |
| [1 – Overview](/docs/01-overview.md) | On-prem ASR, vLLM audio APIs, storage options |
| [2 – Catalog and model choice](/docs/02-catalog-and-model-choice.md) | Model catalog vs `whisper-large-v3` modelcar |
| [3 – Build the modelcar](/docs/03-building-the-modelcar.md) | Download weights, Containerfile, push to Quay |
| [4 – Dashboard deploy](/docs/04-dashboard-deploy.md) | Generative deploy, GPU profile, route + token |
| [5 – YAML and CLI](/docs/05-yaml-and-cli.md) | `ServingRuntime`, `InferenceService`, `oc apply` |
| [6 – Workbench inference](/docs/06-workbench-inference.md) | Notebook: transcribe, translate, optional stream |
| [7 – Troubleshooting](/docs/07-troubleshooting-best-practices.md) | Pitfalls, practices, optional failure exercise |

## What you will use

| Piece | Role in this workshop |
|-------|------------------------|
| OpenShift AI 3.4 | Data Science project, dashboard deploy, workbench |
| KServe (single-model) | `InferenceService` + `ServingRuntime` (RawDeployment) |
| vLLM NVIDIA GPU runtime | OpenAI-compatible audio server |
| Whisper large-v3 modelcar | Weights at `/models` in an OCI image you build |
| CPU workbench | Client notebook — no GPU on the notebook itself |

## What’s next (not in this repo yet)

After the notebook path is solid, the live-caption wow is a small OpenShift app: a Route, browser `getUserMedia`, and chunked POSTs to `/v1/audio/transcriptions` and `/v1/audio/translations`. A workbench pod cannot use the laptop microphone. vLLM `stream=true` streams **tokens for a complete clip**, not continuous mic ASR.

## Facilitator

Platform prep: [prerequisites](/docs/prerequisites.md). Optional stretch: [diagnose a broken deployment](/docs/challenges/broken_deployment.md).

```sh
bash scripts/setup.sh -s 0
bash scripts/setup.sh -s 1
bash scripts/sanity_check.sh
```

Requires KServe enabled on the DataScienceCluster and **1× NVIDIA GPU with 16 GB+ VRAM** for `whisper-large-v3` (heavier than turbo).

## Official references

1. [Deploying models (single-model / KServe RawDeployment)](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/deploying_models/index)
2. [Working with the model catalog](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/working_with_the_model_catalog/index)
3. [vLLM speech-to-text APIs](https://docs.vllm.ai/en/latest/serving/online_serving/speech_to_text/)
4. [Build and deploy a ModelCar container in OpenShift AI](https://developers.redhat.com/articles/2025/01/30/build-and-deploy-modelcar-container-openshift-ai)
5. [Private transcription with Whisper and Red Hat AI](https://developers.redhat.com/articles/2026/03/06/private-transcription-whisper-red-hat-ai)
