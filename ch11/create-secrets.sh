#!/bin/bash

# Creates the secrets and config maps MAKDO and k8s-ai need, from the values in .env
#   worker cluster:  secret k8s-ai-secrets (api-key)
#   control cluster: secret makdo-secrets (LLM settings, k8s-ai API key, optional Slack token)
#                    config map makdo-kubeconfig (kubeconfig MAKDO uses to register the worker cluster with k8s-ai)
#
# Usage: cp .env.example .env  # edit it
#        ./create-secrets.sh
#
# Override the cluster names with CONTROL_CLUSTER / WORKER_CLUSTER if you named them differently.

set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

if [[ ! -f .env ]]; then
    echo "No .env file found. Copy .env.example to .env and fill in your values first."
    exit 1
fi

# Optional values come from .env only, not from variables exported earlier in this shell
unset OPENAI_BASE_URL MAKDO_MODEL AI6_BOT_TOKEN
set -a
source .env
set +a

CONTROL_CLUSTER=${CONTROL_CLUSTER:-makdo-control}
WORKER_CLUSTER=${WORKER_CLUSTER:-makdo-worker}
CONTROL_CONTEXT="kind-${CONTROL_CLUSTER}"
WORKER_CONTEXT="kind-${WORKER_CLUSTER}"

: "${K8S_AI_API_KEY:?Set K8S_AI_API_KEY in .env}"
: "${OPENAI_API_KEY:?Set OPENAI_API_KEY in .env (use any value, e.g. ollama, for Ollama)}"

# Create or update a resource in cluster context $1 from a "kubectl create ..." command
apply() {
    local context=$1
    shift
    kubectl --context "$context" "$@" --dry-run=client -o yaml | kubectl --context "$context" apply -f -
}

echo "Worker cluster ($WORKER_CONTEXT): k8s-ai API key"
apply "$WORKER_CONTEXT" create secret generic k8s-ai-secrets \
    --from-literal=api-key="$K8S_AI_API_KEY"

echo "Control cluster ($CONTROL_CONTEXT): MAKDO secrets"
args=(--from-literal=openai-api-key="$OPENAI_API_KEY" --from-literal=k8s-ai-api-key="$K8S_AI_API_KEY")
# Optional values are only added when set (an empty value would override the defaults)
[[ -n "$OPENAI_BASE_URL" ]] && args+=(--from-literal=openai-base-url="$OPENAI_BASE_URL")
[[ -n "$MAKDO_MODEL" ]] && args+=(--from-literal=makdo-model="$MAKDO_MODEL")
[[ -n "$AI6_BOT_TOKEN" ]] && args+=(--from-literal=slack-bot-token="$AI6_BOT_TOKEN")
apply "$CONTROL_CONTEXT" create secret generic makdo-secrets "${args[@]}"

echo "Control cluster ($CONTROL_CONTEXT): kubeconfig of the worker cluster"
# --internal uses the worker's node address on the kind docker network, reachable from the k8s-ai pod
KUBECONFIG_FILE=$(mktemp)
kind get kubeconfig --internal --name "$WORKER_CLUSTER" > "$KUBECONFIG_FILE"
apply "$CONTROL_CONTEXT" create configmap makdo-kubeconfig --from-file=config="$KUBECONFIG_FILE"
rm -f "$KUBECONFIG_FILE"

echo "Done."
