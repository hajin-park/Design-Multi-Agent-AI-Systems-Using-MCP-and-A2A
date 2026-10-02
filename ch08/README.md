# Chapter 8: Designing Multi-Agent Systems

This directory contains self-contained snapshots of the two projects used in this chapter:

- [`ai-six`](ai-six) - the AI-6 framework ([Sayfan-AI/ai-six](https://github.com/Sayfan-AI/ai-six) v0.13.0). The
  `Engine` is now an `Agent`, and an agent can have **sub-agents** (the `agents:` section of a config file), each
  exposed to its parent as a tool. AI-6 is also an **A2A client**: every skill of every server listed under
  `a2a_servers` becomes a tool, executed asynchronously with task-management tools (`a2a_list_tasks`,
  `a2a_task_status`, `a2a_send_message`, `a2a_cancel_task`).
- [`k8s-ai`](k8s-ai) - the k8s-ai agent from Chapter 3, grown into an **A2A server**
  ([the-gigi/k8s-ai](https://github.com/the-gigi/k8s-ai) v2.1.0) that AI-6 can delegate Kubernetes work to.

```
ch08/
├── ai-six/
│   ├── ai6.sh
│   └── py/
│       ├── requirements.txt, .env.example
│       ├── backend/
│       │   ├── agent/          # Agent, Config (incl. sub-agents), Session, tool_manager.py
│       │   ├── a2a_client/     # A2A client + async-to-sync bridge
│       │   ├── tools/          # native tools (incl. web_fetch, a2a_task_manager, memory)
│       │   └── mcp_tools/      # local MCP servers
│       ├── examples/
│       │   ├── cli-program-builder/  # project manager + developer + tester sub-agents
│       │   ├── github-analyzer/      # single specialized agent using gh
│       │   └── a2a-test/             # end-to-end test of AI-6 <-> k8s-ai over A2A
│       └── frontend/           # cli, chainlit, slack (config_template.* -> config.*)
└── k8s-ai/                     # A2A server (uv project)
```

## Prerequisites

- Python 3.12 or newer (tested with 3.13)
- An LLM, either:
  - **Ollama** running locally with a model that supports tool calling, for example
    `ollama pull llama3.1:8b` (other tool-capable models such as `qwen3`, `gpt-oss` or `gemma4` work too), or
  - an **OpenAI API key** (the configs use `gpt-4o`; any OpenAI chat model with tool calling works)
- [`jq`](https://jqlang.org/download/) - used by the `github_mcp_server.sh` MCP server
- For the A2A parts: [uv](https://docs.astral.sh/uv/getting-started/installation/), Docker,
  [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) and `kubectl`
- Optional, only needed by the tools of the same name: `git`, `kubectl`, `ollama`, `aws`,
  [`gh`](https://cli.github.com/) (for the `gh` MCP tool; log in with `gh auth login`), and an
  [Anthropic API key](https://platform.claude.com/) (for the `claude` tool)

## Setup

```shell
cd ch08/ai-six/py
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

cp .env.example .env                                         # then edit .env
cp frontend/cli/config_template.json frontend/cli/config.json            # CLI
cp frontend/chainlit/config_template.yaml frontend/chainlit/config.yaml  # Chainlit
cp frontend/slack/config_template.toml frontend/slack/config.toml        # Slack
```

### Choosing the model

Each frontend has its own config file (JSON for the CLI, YAML for Chainlit, TOML for Slack - all three formats
are supported by the same `Config` class). Each one selects the model through `default_model_id`. Each entry under
`provider_config` configures one provider; a provider whose settings are missing or invalid is skipped.

- **OpenAI**: put your key in `py/.env` (`OPENAI_API_KEY=sk-...`) and keep `"default_model_id": "gpt-4o"`.
- **Ollama**: set both `default_model_id` and `provider_config.ollama.model` to the model you pulled:

  ```json
  "default_model_id": "llama3.1:8b",
  ...
  "ollama": { "model": "llama3.1:8b" }
  ```

  If Ollama is not on `http://localhost:11434`, set `OLLAMA_HOST` in `py/.env`.

All paths in the config file (`tools_dir`, `mcp_tools_dir`, `memory_dir`) are relative to the `py/` directory,
which is where `ai6.sh` runs everything from.

### Configuring tools

Tools that need settings get them from `tool_config` in the same config file. The `claude` tool reads its key
from `ANTHROPIC_API_KEY` (set it in `py/.env`); without a key the tool is still listed, but reports an
authentication error when the agent calls it. It uses `claude-sonnet-5-5` unless the agent asks for another model.

## Multi-agent example: CLI program builder

A project manager agent coordinates two sub-agents (`cli-developer`, `cli-tester`) defined in
[examples/cli-program-builder/config.yaml](ai-six/py/examples/cli-program-builder/config.yaml):

```shell
cd ch08/ai-six/py
source venv/bin/activate
cd examples/cli-program-builder
python cli_program_builder.py --output-dir ~/cli-python-projects
```

```
📝 Describe your CLI program idea (or 'quit' to exit): Build a tiny CLI called wordcount.py that counts
words in a text file. Delegate the implementation to cli-developer and a quick test to cli-tester.
```

The example configs default to `gpt-4o`; for Ollama, set `default_model_id` and `provider_config.ollama.model` in the
example's `config.yaml`. See each example's README, including
[github-analyzer](ai-six/py/examples/github-analyzer/README.md) (requires the `gh` CLI).

## Multi-agent over A2A: AI-6 + k8s-ai

1. Create a cluster to work on and break it like in Chapter 3:

   ```shell
   kind create cluster -n k8s-ai          # kube context: kind-k8s-ai
   ```

   The manifests in [k8s-ai/README.md](k8s-ai/README.md#k8s-ai-in-action) create a pending deployment and one
   with a bad image.

2. Start the k8s-ai A2A server in its own terminal:

   ```shell
   cd ch08/k8s-ai
   uv sync
   export OPENAI_API_KEY=sk-...           # or the Ollama variables shown in k8s-ai/README.md
   uv run k8s-ai-server --context kind-k8s-ai --auth-key test-key
   ```

3. Point AI-6 at it. In `py/frontend/cli/config.json` set:

   ```json
   "a2a_servers": [
     { "name": "kind-k8s-ai", "url": "http://localhost:9999", "timeout": 30.0, "api_key": "${A2A_API_KEY}" }
   ]
   ```

   and add `A2A_API_KEY=test-key` to `py/.env`.

4. Run the CLI and delegate:

   ```
   ./ai6.sh cli
   [You]: use the kind-k8s-ai Kubernetes Operations tool to ask which pods are not running in the default namespace
   [AI-6]: The following pods in the `default` namespace are not running:
   *   nginx-588645b458-t2ck5: Status is `ErrImagePull`
   *   some-app-5f585cc995-cq7dt: Status is `Pending`
   ...
   ```

   A2A tasks run in the background: the first answer may only say the task started, and the result arrives as
   an update a few seconds later (ask "what did k8s-ai report?").

The automated version of this flow is [examples/a2a-test](ai-six/py/examples/a2a-test/README.md).

## Running the Chainlit web UI

```shell
cd ch08/ai-six
./ai6.sh chainlit
```

Open http://localhost:8000 and start chatting. The settings panel (gear icon next to the message box) lets you
switch between all the models the configured providers serve and enable/disable individual tools.
Sessions are stored in `py/memory/chainlit/`.

## Running the Slack bot

Follow [py/frontend/slack/README.md](ai-six/py/frontend/slack/README.md) to create the Slack app from the
included manifest and get the two tokens (`AI6_APP_TOKEN`, `AI6_BOT_TOKEN`), put them in `py/.env`, then:

```shell
cd ch08/ai-six
./ai6.sh slack
```

Post in a channel whose name starts with `ai-6-`, or mention `@AI-6` in a channel you invited it to.

## Running the CLI

```shell
cd ch08/ai-six
./ai6.sh cli                       # start a new session (type 'exit' to quit)
./ai6.sh cli -l                    # list saved sessions
./ai6.sh cli -s <session_id>       # continue a saved session
./ai6.sh cli -c <config_file>      # use another config file (path relative to py/)
```

Example:

```
[You]: what's in the current directory?
[AI-6]: The current directory contains: README.md, __init__.py, backend, frontend, requirements.txt, ...
----------
[You]: exit
Session saved with ID: 4f51b401-b1cc-49da-8bb1-05f7d99c3207
```

Sessions are stored as JSON files in `py/memory/cli/`. To print every tool call the agent makes, set
`show_tool_calls = True` at the top of `py/frontend/cli/ai6.py`.

## Running the tests

```shell
cd ch08/ai-six/py
source venv/bin/activate
python -m unittest discover -s backend/tests
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Error: default_model_id '...' is not served by any configured provider` | The model in `default_model_id` must be served by a configured provider: set `OPENAI_API_KEY` for OpenAI models, or pull the model with Ollama (`ollama list` shows what is available). |
| `model '...' not found (status code: 404)` | `ollama pull <model>`, or point `OLLAMA_HOST` at the Ollama server that has it. |
| The agent answers without using tools | Use a model that supports tool calling (see [Ollama tool models](https://ollama.com/search?c=tools)). |
| `Warning: Failed to connect to MCP server ...github_mcp_server.sh` | Install `jq`. |
| `gh: command not found` in a tool result | Install the [GitHub CLI](https://cli.github.com/) and run `gh auth login`. |
| `To get started with GitHub CLI, please run: gh auth login` in a tool result | Run `gh auth login` (or set `GH_TOKEN`). |
| `Warning: Failed to discover A2A server` | Start the k8s-ai server first and check `url` / `api_key` in `a2a_servers`. |
| A2A calls return `Authentication failed` | `A2A_API_KEY` must match the server's `--auth-key`. |
| Chainlit fails with `No module named 'requests'` | `pip install -r requirements.txt` again (it pins `requests`, which a Chainlit dependency forgets to declare). |
| Slack: `AI6_APP_TOKEN and AI6_BOT_TOKEN must be set` | Put both tokens in `py/.env` (see the Slack README). |
| Slack: `invalid_auth` | The bot token is wrong, or the app was not installed to the workspace. |
| `virtualenv not found` | Create the virtual environment in `py/venv` as shown above. |
