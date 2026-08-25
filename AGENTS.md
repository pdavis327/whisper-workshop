# whisper-workshop

Workshop for real-time speech transcription and translation with Whisper on Red Hat OpenShift AI Self-Managed 3.4. This is a docs+configs repo — no build, test, lint, or CI pipeline.

## Commands

```sh
# Facilitator: Web Terminal, tooling, banner
bash scripts/setup.sh -s 0

# Facilitator: Data Science project
bash scripts/setup.sh -s 1

bash scripts/sanity_check.sh

# Participant / GitOps path — order matters
# Prefer the HardwareProfile already on the cluster. Apply the sample only if nvidia-gpu is missing.
oc apply -f configs/samples/hardware-profile/hardware-profile.yaml
oc apply -f configs/samples/model-deploy/vllm-servingruntime.yaml
oc apply -f configs/samples/model-deploy/model-sa-token.yaml
# Edit storageUri in inferenceservice.yaml to your modelcar, then:
oc apply -f configs/samples/model-deploy/inferenceservice.yaml
```

## Repo conventions

- **All commands run from repo root** (scripts enforce this via `check_git_root`).
- **Bash only** — scripts check for `BASH_VERSION` and warn otherwise.
- **Namespace:** always `whisper-workshop` (`oc new-project whisper-workshop` or `setup.sh -s 1`).
- **Model:** `openai/whisper-large-v3` packaged as an OCI modelcar (weights live in `scratch/`, never committed).
- **Scratch dir:** `scratch/` is git-ignored for temp/auth/weight files; `auth/**` also ignored at root.
- **Missing CLIs** (`oc`, `jq`, etc.) auto-download to `scratch/bin/` via `scripts/library/bin.sh`.
- **Workshops read online** — `docs/*.md` use GitHub-style `/docs/…` links (not relative).
- **No Makefile, no tests, no CI** — purely instructional material.
