# MAKDO - Multi-Agent Kubernetes DevOps System

A multi-agent system built on the AI-6 framework (installed from PyPI as `ai-six`) for autonomous Kubernetes
cluster management and DevOps operations.

## Architecture

MAKDO consists of 4 specialized AI-6 agents, all defined in
[src/makdo/agents/coordinator.yaml](src/makdo/agents/coordinator.yaml):

1. **Coordinator Agent** - Main orchestrator; delegates to the other agents (each sub-agent is a tool of the coordinator)
2. **Analyzer Agent** - Cluster health assessment through the k8s-ai A2A server's diagnostic skills
3. **Fixer Agent** - Root-cause analysis and remediation recommendations (k8s-ai is read-only)
4. **Slack Agent** - User communication via a small Slack MCP server ([src/makdo/mcp_tools/slack.py](src/makdo/mcp_tools/slack.py))

`analyzer.yaml`, `fixer.yaml` and `slack.yaml` in the same directory describe each role on its own; the running
system uses the combined `coordinator.yaml`.

```
             ┌──────────────┐
             │ Coordinator  │  (health check every MAKDO_CHECK_INTERVAL seconds)
             └──────┬───────┘
      ┌─────────────┼──────────────┐
┌─────▼────┐  ┌─────▼────┐  ┌──────▼─────┐
│ Analyzer │  │  Fixer   │  │ Slack Bot  │──MCP──> Slack
└─────┬────┘  └────┬─────┘  └────────────┘
      └────A2A─────┘
           │
   ┌───────▼────────┐  session token   ┌──────────────┐
   │ k8s-ai server  │ ───────────────> │ kind cluster │
   └────────────────┘                  └──────────────┘
```

## Features

- **Session-Based** - MAKDO registers the cluster with k8s-ai's Admin API and gets a session token for it
- **Read-only diagnostics** - k8s-ai diagnoses issues and recommends fixes; it never changes the cluster
- **Slack Integration** - Reports go to a Slack channel (optional)
- **Multi-agent orchestration** - The coordinator decides which agent to involve

## Prerequisites

1. **Python 3.12+** and [uv](https://docs.astral.sh/uv/getting-started/installation/)
2. **Docker**, [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) and `kubectl`
3. **An LLM** - an OpenAI API key, or a tool-capable model served by [Ollama](https://ollama.com)
   (e.g. `ollama pull llama3.1:8b`)
4. **Slack bot token** - optional, only for posting reports to Slack

## Setup

### 1. Install dependencies

```bash
cd ch09/makdo
uv sync

cd ../k8s-ai
uv sync
```

### 2. Configure the environment

```bash
cd ch09/makdo
cp .env.example .env
# Edit .env: OPENAI_API_KEY (or the Ollama lines), and optionally AI6_BOT_TOKEN
```

`config/makdo.yaml` holds the system settings (k8s-ai URLs, health check interval, logging).
`config/makdo.example.yaml` is a fuller reference copy.

### 3. Create a cluster to monitor and break it

```bash
kind create cluster --name makdo-test     # kube context: kind-makdo-test
kubectl --context kind-makdo-test apply -f tests/fixtures/broken_workloads.yaml
```

This creates a `test-workload` namespace with a crash-looping pod, a pod whose image doesn't exist, and a healthy pod
for comparison.

### 4. Start the k8s-ai A2A server

In a separate terminal:

```bash
cd ch09/k8s-ai
uv run k8s-ai-server --auth-key test-key
```

The A2A server listens on `http://localhost:9999` and the Admin API (session management) on
`http://localhost:9998`. The key must match `K8S_AI_API_KEY` in `makdo/.env`.

### 5. Run MAKDO

```bash
cd ch09/makdo
uv run makdo
```

MAKDO creates a k8s-ai session for `MAKDO_CLUSTER_CONTEXT`, then runs a health check cycle every
`MAKDO_CHECK_INTERVAL` seconds (default 60): Analyzer -> Fixer -> Slack Bot. Watch the log for the agents' tool
calls (`🔧 [MAKDO_Analyzer] Calling tool: ...`). Press `Ctrl+C` to stop.

With a local model each cycle can take several minutes; set `MAKDO_CHECK_INTERVAL=600` to space them out.

## Slack (optional)

1. Create a Slack app (https://api.slack.com/apps -> **Create New App** -> **From scratch**).
2. **OAuth & Permissions** -> add the bot scopes `chat:write` and `channels:read`, then **Install to Workspace**.
3. Copy the **Bot User OAuth Token** (`xoxb-...`) into `AI6_BOT_TOKEN` in `.env`.
4. Create the `#makdo-devops` channel and invite the bot (`/invite @<your app>`).

Without a token, MAKDO still runs; the Slack Bot agent reports that Slack is not configured.

## Configuration Files

### `.env`

- `OPENAI_API_KEY`, `MAKDO_MODEL` (and `OPENAI_BASE_URL` for Ollama) - the LLM used by all four agents
- `K8S_AI_BASE_URL`, `K8S_AI_ADMIN_URL`, `K8S_AI_API_KEY` - how to reach the k8s-ai server
- `MAKDO_CLUSTER_CONTEXT` - kube context of the monitored cluster (default `kind-makdo-test`)
- `MAKDO_CHECK_INTERVAL` - seconds between health checks
- `AI6_BOT_TOKEN` - Slack bot token (optional)

### `src/makdo/agents/coordinator.yaml`

The AI-6 configuration of all four agents: system prompts, sub-agents, A2A servers and MCP tools.
It uses `${MAKDO_MODEL}`, `${K8S_AI_BASE_URL}`, `${K8S_AI_API_KEY}` and `${AI6_PACKAGE_DIR}` (set by MAKDO to the
installed `ai_six` package, whose built-in tools the coordinator uses).

### `config/makdo.yaml`

System configuration: k8s-ai server URLs, Slack channel, monitoring interval and logging.

## Directory Structure

```
makdo/
├── README.md
├── pyproject.toml / uv.lock   # Dependencies (ai-six from PyPI)
├── .env.example               # Environment template (copy to .env)
├── config/
│   ├── makdo.yaml             # System configuration
│   └── makdo.example.yaml     # Configuration reference
├── src/makdo/
│   ├── main.py                # Main orchestrator (health check loop)
│   ├── agents/                # Agent configurations (coordinator.yaml is the one in use)
│   ├── tools/                 # Native AI-6 Slack tools (alternative to the MCP server)
│   └── mcp_tools/slack.py     # Slack MCP server used by the Slack Bot agent
├── tests/
│   ├── fixtures/              # broken_workloads.yaml (demo failures) + test namespace setup
│   └── e2e/                   # End-to-end tests (see below)
└── data/memory/               # Agent session data (created at runtime)
```

## End-to-end tests

`run_e2e_test.sh` (which runs `tests/e2e/test_makdo_e2e.py`) and the other scripts in `tests/e2e/` are the author's end-to-end tests; `test_slack_*.py` check the Slack integration (they need `AI6_BOT_TOKEN`).
They create the kind clusters `k8s-ai` and `makdo-test` if needed, start the k8s-ai server from `../k8s-ai`,
inject failures and check MAKDO's reports. Some of them post to a real Slack workspace or capture screenshots of the
Slack desktop app (macOS) for the book's figures.

## Troubleshooting

1. **`Failed to create session: 401`**
   - `K8S_AI_API_KEY` doesn't match the server's `--auth-key`.

2. **`Error creating k8s-ai session: ... Connection refused`**
   - Start the k8s-ai server first: `cd ../k8s-ai && uv run k8s-ai-server --auth-key test-key`

3. **`Getting kubeconfig for context ... failed`**
   - Check `kubectl config get-contexts` and set `MAKDO_CLUSTER_CONTEXT`.

4. **The model doesn't use its tools / makes up results**
   - Use a model with good tool-calling support. Small local models may need several cycles to get it right.

### Logs and Debugging

MAKDO logs to the console. Set `MAKDO_DEBUG=1` (or `logging.level: "DEBUG"` in `config/makdo.yaml`) for verbose output.

## Development

To modify agent behavior:
1. Edit the agent definitions in `src/makdo/agents/coordinator.yaml`
2. Modify system prompts and tool selections
3. Update operational parameters in `config/makdo.yaml`
4. Restart MAKDO to apply changes
