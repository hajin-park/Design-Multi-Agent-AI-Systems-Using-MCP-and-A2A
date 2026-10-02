# MAKDO - Kubernetes deployment

The MAKDO multi-agent system from Chapter 9, packaged to run as a pod in the `makdo-control` cluster.
See the [chapter README](../README.md) for the full deployment walk-through.

## Contents

```
makdo/
├── Dockerfile          # python:3.13-slim + kubectl + MAKDO
├── requirements.txt    # ai-six 0.14.6 and the tested dependency ranges
├── deployment.yaml     # makdo-config config map + makdo Deployment
├── config/makdo.yaml   # The same settings as the makdo-config config map (reference / local runs)
└── src/makdo/
    ├── main.py         # Health check loop; registers the first configured cluster with k8s-ai
    ├── agents/         # coordinator.yaml defines the four agents (others are role descriptions)
    ├── mcp_tools/      # Slack MCP server used by the Slack Bot agent
    └── tools/          # Native AI-6 Slack tools (alternative to the MCP server)
```

## How the deployment is wired

| Setting | Source |
|---|---|
| Monitored cluster | `clusters[0].context` in the `makdo-config` config map (`kind-makdo-worker`) |
| Kubeconfig for that cluster | `makdo-kubeconfig` config map, mounted at `/root/.kube/config` |
| k8s-ai A2A / Admin API | `k8s_ai.base_url` / `k8s_ai.admin_api_url` in the config map |
| k8s-ai API key | `K8S_AI_API_KEY` from the `makdo-secrets` secret |
| LLM | `OPENAI_API_KEY`, and optionally `OPENAI_BASE_URL` / `MAKDO_MODEL`, from `makdo-secrets` |
| Slack | `AI6_BOT_TOKEN` from `makdo-secrets` (optional) |

Build and load the image after changing anything under `src/`:

```bash
docker build -t makdo:latest .
kind load docker-image makdo:latest --name makdo-control
kubectl --context kind-makdo-control rollout restart deploy/makdo
```
