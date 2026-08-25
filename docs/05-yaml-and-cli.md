# 5. Deploy Whisper with YAML and `oc`

<p align="center">
<a href="/docs/04-dashboard-deploy.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/06-workbench-inference.md">Next</a>
</p>

### Objectives (~20–30 min)

- Apply a project-scoped `ServingRuntime` with Whisper-safe vLLM arguments.
- Apply an `InferenceService` that points at your modelcar (`storageUri: oci://…`).
- Create a service-account token secret for workbench calls.
- Treat this as the GitOps path; the dashboard in Topic 4 is the one-off path.

### Rationale

- Teams that present OpenShift AI to platform admins need YAML they can review and re-apply. Hardware profile name, runtime image, and `storageUri` are the three values that change per cluster.

### Takeaways

- Apply order: HardwareProfile (once, cluster) → `ServingRuntime` → token Secret → `InferenceService`.
- Copy the **vLLM container image** from the cluster template. Do not freeze an old SHA from another workshop.
- `--max-model-len=448` matches Whisper’s encoder–decoder window. High `--max-num-seqs` is a common OOM.

## Hardware profile

[`configs/samples/hardware-profile/hardware-profile.yaml`](/configs/samples/hardware-profile/hardware-profile.yaml) defines `HardwareProfile/nvidia-gpu` in `redhat-ods-applications`. **Prefer the GPU profile already installed.** Apply the sample only if `oc get hardwareprofile -n redhat-ods-applications nvidia-gpu` fails. Cluster-admin is usually required.

The `InferenceService` sets `opendatahub.io/hardware-profile-name: nvidia-gpu`. If that name does not exist, change the annotation to the profile you actually have.

## Copy the vLLM image from the cluster

```sh
oc -n redhat-ods-applications get servingruntime \
  -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image
```

Edit [`configs/samples/model-deploy/vllm-servingruntime.yaml`](/configs/samples/model-deploy/vllm-servingruntime.yaml) and replace `image:` with the NVIDIA GPU vLLM image from that list. The checked-in tag `quay.io/modh/vllm:rhoai-3.4-cuda` is a placeholder.

## Edit the modelcar URI

In [`configs/samples/model-deploy/inferenceservice.yaml`](/configs/samples/model-deploy/inferenceservice.yaml) set:

```yaml
storageUri: oci://quay.io/<org>/whisper-large-v3:1
```

to the URI from [Topic 3](/docs/03-building-the-modelcar.md).

## Apply order

If Topic 4 already created `whisper-large-v3`, either delete that deployment in the dashboard or change `metadata.name` in the samples to avoid a clash. For a clean GitOps demo, delete the dashboard instance first.

```sh
# Only if nvidia-gpu is missing:
oc apply -f configs/samples/hardware-profile/hardware-profile.yaml

oc apply -f configs/samples/model-deploy/vllm-servingruntime.yaml
oc apply -f configs/samples/model-deploy/model-sa-token.yaml
oc apply -f configs/samples/model-deploy/inferenceservice.yaml
```

```sh
oc get servingruntime -n whisper-workshop
oc get inferenceservice whisper-large-v3 -n whisper-workshop
oc get route -n whisper-workshop
```

- [ ] `InferenceService` becomes Ready.
- [ ] Secret `whisper-large-v3-sa` exists (token for Topic 6).

### Private OCI registry

If Quay is private, add a pull connection on the `InferenceService` (`opendatahub.io/connections`) or a pull secret on the predictor service account. See OpenShift AI docs for private OCI / connections.

## Whisper args already in the sample

| Arg | Why |
|-----|-----|
| `--model=/mnt/models` | KServe mount point for the modelcar |
| `--served-model-name=whisper-large-v3` | Must match notebook / curl `model=` |
| `--max-model-len=448` | Whisper encoder–decoder |
| `--max-num-seqs=8` | Keeps VRAM in check |
| `--gpu-memory-utilization=0.90` | Leave headroom |

Do **not** add `--task transcription`.

## Hands-on exercise (~20–30 min)

- [ ] Image field matches the cluster vLLM GPU runtime.
- [ ] `storageUri` is your modelcar.
- [ ] Ordered `oc apply` succeeds; capture the route URL.
- [ ] (Optional) Break `runtime:` to a wrong name, observe conditions, fix, re-apply. Or use [the challenge](/docs/challenges/broken_deployment.md).

<p align="center">
<a href="/docs/04-dashboard-deploy.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/06-workbench-inference.md">Next</a>
</p>
