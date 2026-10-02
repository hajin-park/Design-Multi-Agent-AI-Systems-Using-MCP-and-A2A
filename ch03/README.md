# Chapter 3: A Hands-on Walk-Through of a Simple AI Agent

The code for this chapter is [k8s-ai](k8s-ai): a ~70-line agent that chats with you about your Kubernetes
cluster and runs `kubectl` commands on your behalf.

## Quick start

```shell
cd ch03/k8s-ai
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create a local cluster to experiment with (needs Docker + kind)
kind create cluster -n k8s-ai

# Pick ONE LLM option:
export OPENAI_API_KEY=sk-your-openai-api-key          # OpenAI (gpt-4o)
# -- or --
export OPENAI_API_KEY=ollama OPENAI_BASE_URL=http://localhost:11434/v1 K8S_AI_MODEL=llama3.1:8b   # Ollama

python main.py
```

[k8s-ai/README.md](k8s-ai/README.md) has the full walk-through: it breaks the cluster with two bad deployments
and lets the agent diagnose and fix them. When you are done, delete the cluster with
`kind delete cluster -n k8s-ai`.
