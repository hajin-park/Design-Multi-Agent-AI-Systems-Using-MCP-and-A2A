# Chapter 11: Deploying Multi-Agent Systems

This chapter deploys the MAKDO system from Chapter 9 to Kubernetes, using two local kind clusters:

- **makdo-control** runs MAKDO (the Coordinator, Analyzer, Fixer and Slack Bot agents)
- **makdo-worker** runs the k8s-ai A2A server, plus the workloads MAKDO monitors

MAKDO reaches k8s-ai through the worker cluster's host port mappings (`host.docker.internal:8100` for A2A,
`:8099` for the Admin API), and registers the worker cluster with k8s-ai using the worker's internal kubeconfig.

```
 ┌──────── kind: makdo-control ────────┐          ┌──────── kind: makdo-worker ─────────┐
 │                                     │   A2A    │                                     │
 │  MAKDO pod  ──────────────────────────────────────▶ k8s-ai pod (NodePort 30100/30099) │
 │  (4 agents)   host.docker.internal:8100 / 8099  │       │ session kubeconfig          │
 │                                     │          │       ▼                             │
 └─────────────────────────────────────┘          │  test-workload pods (broken)        │
                                                  └─────────────────────────────────────┘
```

## Files

| File | Purpose |
|---|---|
| `check-prerequisites.sh` | Checks Docker, kubectl, kind, free host ports and disk space |
| `control-cluster.yaml`, `worker-cluster.yaml` | kind cluster definitions (with host port mappings) |
| `test-connectivity.sh` | Verifies pods in the control cluster can reach the worker cluster |
| `.env.example`, `create-secrets.sh` | Values for, and creation of, the secrets/config maps both deployments need |
| `k8s-ai/` | k8s-ai A2A server (the-gigi/k8s-ai v2.2.0): `Dockerfile` and `deployment.yaml` |
| `makdo/` | MAKDO: `Dockerfile`, `deployment.yaml` (incl. the `makdo-config` config map), source |
| `test-workload.yaml` | Broken workloads (crash loop, bad image) plus a healthy pod |

## Prerequisites

- Docker, [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) and `kubectl`. The walk-through
  assumes Docker Desktop, which gives containers the `host.docker.internal` address; with Docker Engine on Linux,
  apply the changes in [Linux with Docker Engine](#linux-with-docker-engine) before step 3.
- An LLM: an OpenAI API key, or [Ollama](https://ollama.com) running on your machine with a tool-capable model
- A Slack bot token (optional)

```bash
cd ch11
./check-prerequisites.sh
```

## 1. Create the clusters

```bash
kind create cluster --config control-cluster.yaml   # context: kind-makdo-control
kind create cluster --config worker-cluster.yaml    # context: kind-makdo-worker
./test-connectivity.sh
```

## 2. Build the images and load them into the clusters

```bash
docker build -t k8s-ai:latest k8s-ai
docker build -t makdo:latest makdo

kind load docker-image k8s-ai:latest --name makdo-worker
kind load docker-image makdo:latest --name makdo-control
```

## 3. Create the secrets

```bash
cp .env.example .env      # set K8S_AI_API_KEY and your LLM settings (OpenAI or Ollama)
./create-secrets.sh
```

This creates the `k8s-ai-secrets` secret in the worker cluster, and the `makdo-secrets` secret plus the
`makdo-kubeconfig` config map (generated with `kind get kubeconfig --internal --name makdo-worker`) in the control
cluster.

## 4. Deploy k8s-ai and the test workload to the worker cluster

```bash
kubectl --context kind-makdo-worker apply -f k8s-ai/deployment.yaml
kubectl --context kind-makdo-worker rollout status deploy/k8s-ai
kubectl --context kind-makdo-worker apply -f test-workload.yaml

# k8s-ai is now reachable from your machine (and from the control cluster via host.docker.internal)
curl http://localhost:8100/.well-known/agent-card.json
```

## 5. Deploy MAKDO to the control cluster

```bash
kubectl --context kind-makdo-control apply -f makdo/deployment.yaml
kubectl --context kind-makdo-control rollout status deploy/makdo
kubectl --context kind-makdo-control logs -f deploy/makdo
```

In the log you should see MAKDO create a k8s-ai session for `kind-makdo-worker`, then every
`MAKDO_CHECK_INTERVAL` seconds (120 in `makdo/deployment.yaml`) run a health check in which the Analyzer calls
`kind-makdo-worker_Kubernetes_Diagnostics` over A2A and gets back the broken `crashloop-pod` and `imagepull-pod`:

```
makdo - INFO - ✅ Created session for kind-makdo-worker: k8s-ai-session-...
makdo.tools - INFO - 🔧 [MAKDO_Analyzer] Calling tool: kind-makdo-worker_Kubernetes_Diagnostics
ai_six.a2a_client.a2a_message_pump - INFO - Task kind-makdo-worker_Kubernetes Diagnostics_... finished with status: completed
```

## Changing the configuration

- **MAKDO settings** (clusters, k8s-ai URLs, check interval, logging) live in the `makdo-config` config map in
  `makdo/deployment.yaml`. Re-apply it and restart: `kubectl --context kind-makdo-control rollout restart deploy/makdo`.
- **Secrets**: edit `.env`, re-run `./create-secrets.sh`, then restart the deployment.
- **Agents**: edit `makdo/src/makdo/agents/coordinator.yaml`, then rebuild and reload the image (step 2) and restart.

## Using Ollama

Set these in `.env` before `./create-secrets.sh`:

```
OPENAI_API_KEY=ollama
OPENAI_BASE_URL=http://host.docker.internal:11434/v1
MAKDO_MODEL=llama3.1:8b
```

The model must be pulled on the Ollama server that answers on port 11434 of your machine
(`curl http://localhost:11434/api/tags`). Larger models follow MAKDO's multi-step instructions much more reliably;
with small models some health-check cycles may end without the Analyzer calling k8s-ai.

## Linux with Docker Engine

`host.docker.internal` only exists with Docker Desktop (macOS, Windows/WSL 2, Docker Desktop for Linux). With plain
Docker Engine, address the worker node by its name on the `kind` Docker network instead of the host port mappings:

| File | Setting | Value |
|---|---|---|
| `makdo/deployment.yaml` | `base_url` | `http://makdo-worker-control-plane:30100` |
| `makdo/deployment.yaml` | `admin_api_url` | `http://makdo-worker-control-plane:30099` |
| `k8s-ai/deployment.yaml` | `K8S_AI_PUBLIC_URL` | `http://makdo-worker-control-plane:30100/` |

For Ollama, make it listen on all interfaces (`OLLAMA_HOST=0.0.0.0 ollama serve`) and set `OPENAI_BASE_URL` in `.env`
to the gateway address of the `kind` network, for example `http://172.18.0.1:11434/v1`
(`docker network inspect kind` shows the gateway).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `kind create cluster` fails with `port is already allocated` | Something else uses host port 8080, 9090, 8100, 8099 or 8200, often an old cluster (`kind get clusters`). Stop or delete it. |
| Pods in `ErrImageNeverPull` | The image wasn't loaded into that cluster: `kind load docker-image ... --name ...` |
| MAKDO pod `CreateContainerConfigError` | `makdo-secrets` or `makdo-kubeconfig` is missing: run `./create-secrets.sh` |
| `Failed to create session: 401` | `K8S_AI_API_KEY` differs between the two secrets: fix `.env`, re-run `./create-secrets.sh`, restart both deployments |
| `Error in A2A task ...: All connection attempts failed` | k8s-ai advertises an address MAKDO can't reach: check `K8S_AI_PUBLIC_URL` in `k8s-ai/deployment.yaml` |

## Clean up

```bash
kind delete cluster --name makdo-control
kind delete cluster --name makdo-worker
```
