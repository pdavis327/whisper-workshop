#!/usr/bin/env bash
# Shared secret literals for live-caption deploy scripts.

secret_args_for_live_caption() {
  local -n out=$1
  out=(
    --from-literal=WHISPER_BASE_URL="${WHISPER_BASE_URL}"
    --from-literal=WHISPER_BEARER_TOKEN="${WHISPER_BEARER_TOKEN}"
    --from-literal=WHISPER_MODEL="${WHISPER_MODEL:-whisper-large-v3}"
  )

  if [[ -n "${MLFLOW_TRACKING_URI:-}" ]]; then
    out+=(--from-literal=MLFLOW_ENABLED=true)
    out+=(--from-literal=MLFLOW_TRACKING_URI="${MLFLOW_TRACKING_URI}")
    out+=(
      --from-literal=MLFLOW_EXPERIMENT_NAME="${MLFLOW_EXPERIMENT_NAME:-whisper-live-caption}"
    )
    out+=(
      --from-literal=MLFLOW_TRACKING_AUTH="${MLFLOW_TRACKING_AUTH:-kubernetes-namespaced}"
    )
    out+=(
      --from-literal=MLFLOW_K8S_INTEGRATION="${MLFLOW_K8S_INTEGRATION:-true}"
    )
    if [[ -n "${MLFLOW_TRACKING_TOKEN:-}" ]]; then
      out+=(--from-literal=MLFLOW_TRACKING_TOKEN="${MLFLOW_TRACKING_TOKEN}")
    fi
  fi
}
