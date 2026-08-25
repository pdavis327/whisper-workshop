#!/bin/bash

# Sanity check script for Whisper Workshop

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "--- Whisper Workshop Sanity Check ---"

if command -v oc &> /dev/null; then
    echo -e "[${GREEN}OK${NC}] oc CLI is installed."
else
    echo -e "[${RED}FAIL${NC}] oc CLI is NOT installed. Please install OpenShift CLI."
fi

if oc whoami &> /dev/null; then
    echo -e "[${GREEN}OK${NC}] Logged into cluster as: $(oc whoami)"
else
    echo -e "[${RED}FAIL${NC}] Not logged into any OpenShift cluster. Run 'oc login'."
fi

if oc get inferenceservices &> /dev/null; then
    echo -e "[${GREEN}OK${NC}] KServe CRDs (InferenceService) are available."
else
    echo -e "[${RED}FAIL${NC}] KServe CRDs not found. Is KServe enabled on the DataScienceCluster?"
fi

if oc get servingruntimes &> /dev/null; then
    echo -e "[${GREEN}OK${NC}] ServingRuntime API is available."
else
    echo -e "[${RED}FAIL${NC}] ServingRuntime API not found."
fi

if oc get project whisper-workshop &> /dev/null; then
    echo -e "[${GREEN}OK${NC}] Project whisper-workshop exists."
else
    echo -e "[${YELLOW}WARN${NC}] Project whisper-workshop not found. Run: bash scripts/setup.sh -s 1"
fi

gpu_nodes="$(oc get nodes -o json 2>/dev/null | jq -r '[.items[] | select(.status.allocatable["nvidia.com/gpu"] != null and .status.allocatable["nvidia.com/gpu"] != "0")] | length')"
if [ "${gpu_nodes}" != "null" ] && [ "${gpu_nodes}" -gt 0 ] 2>/dev/null; then
    echo -e "[${GREEN}OK${NC}] Found ${gpu_nodes} node(s) with nvidia.com/gpu capacity."
else
    echo -e "[${YELLOW}WARN${NC}] No nodes reporting nvidia.com/gpu. Whisper large-v3 needs 1 GPU with 16GB+ VRAM."
fi

echo "--- Sanity Check Complete ---"
