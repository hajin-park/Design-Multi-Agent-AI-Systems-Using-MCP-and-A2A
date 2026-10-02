# Chapter 9: Implementing Multi-Agent Systems with A2A

This chapter builds **MAKDO** (Multi-Agent Kubernetes DevOps): an AI-driven DevOps team of four AI-6 agents
(Coordinator, Analyzer, Fixer, Slack Bot) that monitors a Kubernetes cluster through the k8s-ai A2A server and
reports to Slack.

```
ch09/
├── plan.md      # The design plan for MAKDO (roles, tools, communication patterns)
├── makdo/       # The multi-agent system (uses the ai-six package from PyPI)
└── k8s-ai/      # The k8s-ai A2A server (the-gigi/k8s-ai v2.2.0): read-only, session-based diagnostics
```

## Quick start

Prerequisites: [uv](https://docs.astral.sh/uv/getting-started/installation/) (it installs a matching Python if you
don't have one), Docker, [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation), `kubectl`, and either
an OpenAI API key or a tool-capable [Ollama](https://ollama.com) model.

```bash
# 1. A cluster to monitor, with some broken workloads
kind create cluster --name makdo-test
kubectl --context kind-makdo-test apply -f ch09/makdo/tests/fixtures/broken_workloads.yaml

# 2. The k8s-ai A2A server (terminal 1)
cd ch09/k8s-ai
uv sync
uv run k8s-ai-server --auth-key test-key

# 3. MAKDO (terminal 2)
cd ch09/makdo
uv sync
cp .env.example .env      # set OPENAI_API_KEY, or switch to the Ollama lines
uv run makdo
```

Each health-check cycle the Coordinator asks the Analyzer to diagnose the cluster through k8s-ai, the Fixer to
work out remediations, and the Slack Bot to report to `#makdo-devops` (Slack is optional).
See [makdo/README.md](makdo/README.md) for configuration, Slack setup and troubleshooting.

When you are done: `kind delete cluster --name makdo-test`.
