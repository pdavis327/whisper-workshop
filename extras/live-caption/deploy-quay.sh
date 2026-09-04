#!/usr/bin/env bash
# Build locally, push to Quay, deploy live-caption on OpenShift.
#
# Usage (from repo root):
#   export QUAY_IMAGE="quay.io/rh-ee-petdavis/whisper-live-caption:1"
#   export WHISPER_BASE_URL="https://your-whisper-route"
#   export WHISPER_BEARER_TOKEN="your-token"
#   export WHISPER_MODEL="whisper-large"
#   export NAMESPACE="whisper-demo"
#   export MLFLOW_TRACKING_URI="https://mlflow-server.example.com"  # optional
#   export MLFLOW_EXPERIMENT_NAME="whisper-live-caption"            # optional
#   export MLFLOW_TRACKING_TOKEN="..."                              # optional
#   bash extras/live-caption/deploy-quay.sh
#
# Private Quay repo: log in first with `podman login quay.io`, then either
#   export IMAGE_PULL_SECRET="quay-pull"   # docker-registry secret in the namespace
# or link a pull secret to the default service account.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NS="${NAMESPACE:-whisper-workshop}"
APP_DIR="${ROOT}/extras/live-caption"
BC="whisper-live-caption"
QUAY_IMAGE="${QUAY_IMAGE:-}"

if [[ -z "${QUAY_IMAGE}" ]]; then
  echo "Set QUAY_IMAGE, e.g. quay.io/<org>/whisper-live-caption:1" >&2
  exit 1
fi

if [[ -z "${WHISPER_BASE_URL:-}" || -z "${WHISPER_BEARER_TOKEN:-}" ]]; then
  echo "Set WHISPER_BASE_URL and WHISPER_BEARER_TOKEN before running." >&2
  exit 1
fi

if ! command -v podman &>/dev/null; then
  echo "podman is required" >&2
  exit 1
fi

if ! oc get namespace "$NS" &>/dev/null; then
  echo "Namespace $NS not found." >&2
  exit 1
fi

oc project "$NS" >/dev/null

echo "Building ${QUAY_IMAGE} ..."
podman build -f "${APP_DIR}/Dockerfile" -t "${QUAY_IMAGE}" "${APP_DIR}"

echo "Pushing ${QUAY_IMAGE} ..."
podman push "${QUAY_IMAGE}"

echo "Creating/updating app secret ..."
# shellcheck source=secret-args.sh
source "${APP_DIR}/secret-args.sh"
SECRET_ARGS=()
secret_args_for_live_caption SECRET_ARGS
oc create secret generic whisper-live-caption \
  "${SECRET_ARGS[@]}" \
  -n "$NS" --dry-run=client -o yaml | oc apply -f -

MANIFEST="$(mktemp)"
sed -e "s/namespace: whisper-workshop/namespace: ${NS}/" \
    -e "s|image: whisper-live-caption:latest|image: ${QUAY_IMAGE}|" \
    "${ROOT}/configs/samples/live-caption/openshift.yaml" > "${MANIFEST}"
oc apply -f "${MANIFEST}"
rm -f "${MANIFEST}"

if [[ -n "${IMAGE_PULL_SECRET:-}" ]]; then
  echo "Attaching imagePullSecret ${IMAGE_PULL_SECRET} ..."
  oc patch deployment "${BC}" -n "$NS" --type=json -p="[
    {\"op\":\"add\",\"path\":\"/spec/template/spec/imagePullSecrets\",\"value\":[{\"name\":\"${IMAGE_PULL_SECRET}\"}]}
  ]" 2>/dev/null || \
  oc patch deployment "${BC}" -n "$NS" --type=merge -p="{
    \"spec\": {\"template\": {\"spec\": {\"imagePullSecrets\": [{\"name\": \"${IMAGE_PULL_SECRET}\"}]}}}
  }"
fi

oc set image "deployment/${BC}" "live-caption=${QUAY_IMAGE}" -n "$NS"
oc rollout status "deployment/${BC}" -n "$NS" --timeout=300s

ROUTE="$(oc get route "$BC" -n "$NS" -o jsonpath='{.spec.host}')"
echo ""
echo "Image:  ${QUAY_IMAGE}"
echo "URL:    https://${ROUTE}"
