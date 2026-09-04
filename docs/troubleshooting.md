# Troubleshooting guide

Common failures in the Whisper workshop. Lab narrative: [Topic 7](/docs/07-troubleshooting-best-practices.md).

## Environment and setup

### `oc` command not found

**Symptom:** `command not found: oc`  
**Solution:** Install the OpenShift CLI, or use the Web Terminal. Workshop scripts can download `oc` into `scratch/bin/` when run from repo root (`bin_check oc`).

### Authentication failed

**Symptom:** `You must be logged in to the server`  
**Solution:** `oc login <api-url>` with the credentials for this cluster.

### Project `whisper-workshop` missing in AI projects

**Symptom:** Dashboard filter **AI projects** does not list the workshop.  
**Solution:** `bash scripts/setup.sh -s 1` or `oc label namespace whisper-workshop opendatahub.io/dashboard=true --overwrite`. Switch the filter to **All projects**.

## Serving

### ImagePullBackOff (predictor)

**Symptom:** Predictor pod cannot pull the **vLLM runtime** image or the **modelcar**.  
**Solution:**

1. `oc describe pod -n whisper-workshop -l serving.kserve.io/inferenceservice=whisper-large-v3`
2. Runtime image: copy from `oc -n redhat-ods-applications get servingruntime`.
3. Modelcar: confirm `storageUri` is `oci://quay.io/<org>/whisper-large-v3:1` and the tag exists.
4. Private Quay: connection or pull secret.

### Pending (insufficient GPU)

**Symptom:** Pod stays Pending.  
**Solution:** `oc describe pod …` Events. Check GPU taints, HardwareProfile name, and that one `nvidia.com/gpu` is free. Whisper large-v3 needs **16 GB+** VRAM.

### CrashLoop / OOM in vLLM

**Symptom:** Predictor restarts; logs mention CUDA OOM.  
**Solution:** Lower `--max-num-seqs` (sample uses `8`), keep `--max-model-len=448`, lower `--gpu-memory-utilization` to `0.85`. Do not copy LLM flags like `--max-model-len=8192`.

### Translations API 400 / not found

**Symptom:** `/v1/audio/transcriptions` works; `/v1/audio/translations` fails.  
**Solution:** You are likely on **turbo**. This workshop requires `openai/whisper-large-v3`. vLLM: turbo **does not support translating**.

### 401 Unauthorized

**Symptom:** curl/notebook 401.  
**Solution:** Bearer token from the correct secret; strip newlines; confirm the deployment still requires auth. `oc extract secret/whisper-large-v3-sa -n whisper-workshop --keys=token --to=-`

### `/v1/chat/completions` fails

**Symptom:** LLM playground or Granite notebook against the Whisper route.  
**Solution:** Use `/v1/audio/transcriptions` and `/v1/audio/translations` only.

## Workbench

### Cannot record from the mic in Jupyter

**Expected.** The kernel runs in the cluster. Record on the laptop and **upload**, or use `extras/audio/*.wav`. For a browser mic after Topic 6, see the [live-caption POC](/extras/live-caption/README.md) (deploys to `whisper-demo` by default, not `whisper-workshop`).

### Wrong `MODEL_NAME`

**Symptom:** 404 / unknown model.  
**Solution:** Run `GET /v1/models` and copy the `id` exactly (`whisper-large-v3` in the sample runtime).
