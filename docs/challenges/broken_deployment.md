# Challenge: the broken Whisper deployment

Use this after [Topic 7](/docs/07-troubleshooting-best-practices.md). The manifest below is **intentionally wrong**.

## Scenario

A colleague “adapted” the Granite `InferenceService` for Whisper. The predictor never becomes Ready.

```yaml
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: whisper-broken
  namespace: whisper-workshop
  annotations:
    opendatahub.io/hardware-profile-name: cpu-only-does-not-exist
    serving.kserve.io/deploymentMode: RawDeployment
spec:
  predictor:
    model:
      modelFormat:
        name: vLLM
      runtime: whisper-large-v3
      storageUri: oci://quay.io/example/whisper-large-v3-turbo:latest
      resources:
        limits:
          cpu: "100m"
          memory: "128Mi"
```

Problems to find:

1. Hardware profile name does not exist (and is not a GPU profile).
2. `storageUri` points at **turbo** (wrong for translation) and a fake registry.
3. CPU/memory limits are far too small for vLLM; **no GPU** request.

## Your task

1. Save the YAML and `oc apply -f` it (or apply from a gist).
2. `oc describe inferenceservice whisper-broken -n whisper-workshop` and inspect the predictor pod.
3. Compare with [`configs/samples/model-deploy/inferenceservice.yaml`](/configs/samples/model-deploy/inferenceservice.yaml).
4. Delete `whisper-broken` when finished: `oc delete inferenceservice whisper-broken -n whisper-workshop`.

## Hint

Ready Whisper needs: a **real GPU HardwareProfile**, the **large-v3 modelcar** URI, the **whisper-large-v3** `ServingRuntime`, and GPU limits — not 128Mi RAM on CPU.
