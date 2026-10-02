# A2A Integration Test

This example demonstrates AI-6's A2A (Agent-to-Agent) client support.

## Architecture

The A2A integration follows the same pattern as MCP integration:

1. **A2A Client** (`backend/a2a_client/`) - Handles A2A protocol communication
2. **A2ATool** (`backend/tools/base/a2a_tool.py`) - Wraps A2A skills as standard Tools
3. **Configuration** - A2A servers defined in config under `a2a_servers`
4. **Discovery** - Agent cards fetched at init time, skills become tools

## Key Features

- **Agent Card Discovery**: Automatically fetches the server's agent card (`/.well-known/agent-card.json`)
- **Skill Mapping**: Each A2A agent skill becomes an individual tool named `<server name>_<skill name>` (spaces become `_`)
- **Async Tasks**: A2A tools return immediately; progress arrives later as `SystemMessage`s
- **Task Management**: `a2a_list_tasks`, `a2a_task_status`, `a2a_send_message`, `a2a_cancel_task`
- **Configuration Driven**: A2A servers defined declaratively in config

## Prerequisites

- The AI-6 virtual environment (`py/venv`, see the chapter README) - it already includes `a2a-sdk`
- [uv](https://docs.astral.sh/uv/getting-started/installation/) and the k8s-ai A2A server in
  [`ch08/k8s-ai`](../../../../k8s-ai) (`cd ch08/k8s-ai && uv sync`)
- A Kubernetes cluster, e.g. `kind create cluster -n k8s-ai` (context `kind-k8s-ai`)
- An LLM for both AI-6 (`config_async.yaml`) and k8s-ai (see the k8s-ai README for the Ollama variables)

## Running the test

```bash
cd ch08/ai-six/py
source venv/bin/activate
cd examples/a2a-test

export A2A_API_KEY=test-key            # shared secret between AI-6 and the k8s-ai server
export K8S_AI_CONTEXT=kind-k8s-ai      # kube context k8s-ai should use (default: kind-k8s-ai)
python test_a2a_e2e.py
```

If no A2A server is listening on `localhost:9999`, the test starts `../../../../k8s-ai` with
`uv run k8s-ai-server --context $K8S_AI_CONTEXT --auth-key $A2A_API_KEY` and stops it at the end. The k8s-ai server
needs its own LLM settings (`OPENAI_API_KEY`, and for Ollama also `OPENAI_BASE_URL` and `K8S_AI_MODEL`) in the
environment.

The test validates the complete async-to-sync A2A bridge: immediate responses, background processing with
SystemMessage injection, concurrent tasks, and task status/messaging/cancellation.

## Configuration

`config_async.yaml` configures the k8s-ai server:

```yaml
a2a_servers:
  - name: kind-k8s-ai
    url: http://localhost:9999
    timeout: 30.0
    api_key: ${A2A_API_KEY}
```

To use a local Ollama model for the AI-6 side, set `default_model_id` and `provider_config.ollama.model` in
`config_async.yaml` to the same tool-capable model.
