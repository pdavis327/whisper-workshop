#!/usr/bin/env bash
# Build and deploy the live-caption mic demo into an OpenShift project.
#
# Usage (from repo root):
#   export WHISPER_BASE_URL="https://your-whisper-route"
#   export WHISPER_BEARER_TOKEN="your-token"
#   export WHISPER_MODEL="whisper-large-v3"   # optional
#   export NAMESPACE="whisper-demo"             # optional
#   bash extras/live-caption/deploy.sh
#
# Requires: oc, logged in to the cluster. Uses OpenShift binary build (Dockerfile in extras/live-caption).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NS="${NAMESPACE:-whisper-workshop}"
APP_DIR="${ROOT}/extras/live-caption"
BC="whisper-live-caption"

if [[ -z "${WHISPER_BASE_URL:-}" || -z "${WHISPER_BEARER_TOKEN:-}" ]]; then
  echo "Set WHISPER_BASE_URL and WHISPER_BEARER_TOKEN before running." >&2
  exit 1
fi

if ! oc get namespace "$NS" &>/dev/null; then
  echo "Namespace $NS not found. Create it or set NAMESPACE." >&2
  exit 1
fi

oc project "$NS" >/dev/null

# shellcheck source=secret-args.sh
source "${APP_DIR}/secret-args.sh"
SECRET_ARGS=()
secret_args_for_live_caption SECRET_ARGS

echo "Creating/updating secret whisper-live-caption ..."
oc create secret generic whisper-live-caption \
  "${SECRET_ARGS[@]}" \
  -n "$NS" --dry-run=client -o yaml | oc apply -f -

if ! oc get buildconfig "$BC" -n "$NS" &>/dev/null; then
  echo "Creating BuildConfig ${BC} ..."
  oc new-build --name="$BC" --binary=true -n "$NS"
fi

echo "Starting image build from ${APP_DIR} ..."
echo "(If this times out, use: bash extras/live-caption/deploy-podman.sh)"
if ! oc start-build "$BC" --from-dir="$APP_DIR" --wait -n "$NS"; then
  echo "" >&2
  echo "Cluster build failed or timed out. Check:" >&2
  echo "  oc get builds -n ${NS}" >&2
  echo "  oc describe build -n ${NS}" >&2
  echo "  oc get pods -n ${NS} | grep build" >&2
  echo "" >&2
  echo "Fallback: bash extras/live-caption/deploy-podman.sh" >&2
  exit 1
fi

sed "s/namespace: whisper-workshop/namespace: ${NS}/g" \
  "${ROOT}/configs/samples/live-caption/openshift.yaml" \
  | oc apply -f -

oc set image "deployment/${BC}" "live-caption=${BC}:latest" -n "$NS"
oc rollout status "deployment/${BC}" -n "$NS" --timeout=300s

ROUTE="$(oc get route "$BC" -n "$NS" -o jsonpath='{.spec.host}')"
echo ""
echo "Live caption URL: https://${ROUTE}"
echo "Allow microphone permission when prompted."
