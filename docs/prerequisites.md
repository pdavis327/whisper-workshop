# Workshop requirements and prerequisites

Verify this list before a customer briefing. Aligns with [OpenShift AI 3.4 deploying models](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/deploying_models/index).

## Cluster (facilitator)

| Component | Expectation |
|-----------|-------------|
| **Red Hat OpenShift** | 4.16+ typical for AI 3.4 |
| **Red Hat OpenShift AI** | Self-Managed **3.4** |
| **KServe** | Enabled / managed on the DataScienceCluster (single-model platform) |
| **GPU** | NVIDIA GPU Operator + Node Feature Discovery |
| **Capacity** | **1 GPU, 16 GB+ VRAM** for `whisper-large-v3` (not turbo) |
| **Registry** | Quay.io or internal registry for the modelcar; cluster can pull |
| **Storage class** | Any; modelcar does not need a model PVC |

```sh
oc get dsc,dscinitialization -n redhat-ods-applications
oc api-resources | grep -E 'inferenceservice|servingruntime'
oc get nodes -o json | jq -r '.items[] | select(.status.allocatable["nvidia.com/gpu"] != null) | [.metadata.name, .status.allocatable["nvidia.com/gpu"]] | @tsv'
```

## OpenShift AI dashboard

- [ ] You can open **AI hub → Models → Catalog**
- [ ] A **GPU** hardware profile is visible when deploying models into `whisper-workshop`
- [ ] Users can create a **CPU** workbench in that project

If GPU profiles are missing, install or copy a profile in `redhat-ods-applications`. Sample: `configs/samples/hardware-profile/hardware-profile.yaml` (cluster-admin). Prefer the profile already on the cluster.

## Participant tooling

| Tool | Purpose | Check |
|------|---------|--------|
| `oc` | CLI | `oc version` |
| Browser | Dashboard, workbench | OpenShift AI URL |
| Podman (Topic 3) | Build/push modelcar | `podman --version` |
| Hugging Face CLI (Topic 3) | Download weights | `huggingface-cli --help` |

## Facilitator setup

```sh
bash scripts/setup.sh -s 0    # optional: Web Terminal + banner
bash scripts/setup.sh -s 1    # project whisper-workshop
bash scripts/sanity_check.sh
```

For a live briefing, **pre-build and push** `oci://quay.io/<org>/whisper-large-v3:1` so Topic 3 is a walkthrough, not a 3 GB wait.

## Disconnect / air-gap

- Mirror the vLLM NVIDIA GPU runtime image and the Whisper modelcar into the disconnected registry.
- Catalog discovery (Topic 2) needs the cluster’s catalog source; skip or screenshot if the catalog is empty offline.
- Bundled `extras/audio/*.wav` avoids downloading speech samples during the lab.
