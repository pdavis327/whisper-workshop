#!/usr/bin/env bash
# Deploy live-caption using a local podman build (skip cluster BuildConfig).
#
# Use when: oc start-build times out or build pods stay Pending.
#
# Usage (from repo root):
#   export WHISPER_BASE_URL="https://your-whisper-route"
#   export WHISPER_BEARER_TOKEN="your-token"
#   export WHISPER_MODEL="whisper-large"
#   export NAMESPACE="whisper-demo"
#   bash extras/live-caption/deploy-podman.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NS="${NAMESPACE:-whisper-workshop}"
APP_DIR="${ROOT}/extras/live-caption"
BC="whisper-live-caption"
LOCAL_TAG="localhost/${BC}:latest"

if [[ -z "${WHISPER_BASE_URL:-}" || -z "${WHISPER_BEARER_TOKEN:-}" ]]; then
  echo "Set WHISPER_BASE_URL and WHISPER_BEARER_TOKEN before running." >&2
  exit 1
fi

if ! command -v podman &>/dev/null; then
  echo "podman is required for deploy-podman.sh" >&2
  exit 1
fi

if ! oc get namespace "$NS" &>/dev/null; then
  echo "Namespace $NS not found." >&2
  exit 1
fi

oc project "$NS" >/dev/null

echo "Building image locally ..."
podman build -f "${APP_DIR}/Dockerfile" -t "${LOCAL_TAG}" "${APP_DIR}"

REGISTRY="$(oc registry info)"
REMOTE="${REGISTRY}/${NS}/${BC}:latest"

echo "Pushing to ${REMOTE} ..."
podman tag "${LOCAL_TAG}" "${REMOTE}"
podman login "${REGISTRY}" -u "$(oc whoami)" -p "$(oc whoami -t)" --tls-verify=false
podman push "${REMOTE}" --tls-verify=false

echo "Creating/updating secret ..."
# shellcheck source=secret-args.sh
source "${APP_DIR}/secret-args.sh"
SECRET_ARGS=()
secret_args_for_live_caption SECRET_ARGS
oc create secret generic whisper-live-caption \
  "${SECRET_ARGS[@]}" \
  -n "$NS" --dry-run=client -o yaml | oc apply -f -

sed "s/namespace: whisper-workshop/namespace: ${NS}/g" \
  "${ROOT}/configs/samples/live-caption/openshift.yaml" \
  | oc apply -f -

CLUSTER_IMAGE="image-registry.openshift-image-registry.svc:5000/${NS}/${BC}:latest"
oc set image "deployment/${BC}" "live-caption=${CLUSTER_IMAGE}" -n "$NS"
oc rollout status "deployment/${BC}" -n "$NS" --timeout=300s

ROUTE="$(oc get route "$BC" -n "$NS" -o jsonpath='{.spec.host}')"
echo ""
echo "Live caption URL: https://${ROUTE}"
