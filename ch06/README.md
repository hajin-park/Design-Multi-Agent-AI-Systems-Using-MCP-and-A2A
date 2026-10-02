# Chapter 6: Creating Chat Interfaces Using Slack and Chainlit

This directory contains a self-contained snapshot of the AI-6 framework
([Sayfan-AI/ai-six](https://github.com/Sayfan-AI/ai-six) v0.10.0) as it stands at the end of this chapter.
The focus of this chapter is the two chat frontends that sit on top of the same engine as the CLI:

- **Chainlit** (`py/frontend/chainlit`) - a web chat UI with streaming, model selection and per-tool on/off switches
- **Slack** (`py/frontend/slack`) - a Slack bot that keeps a separate session per channel

```
ch06/ai-six/
├── ai6.sh                  # Launcher for all frontends
└── py/
    ├── requirements.txt
    ├── .env.example        # Environment variables template (copy to .env)
    ├── backend/
    │   ├── engine/         # Engine, Config, Session, Summarizer
    │   ├── llm_providers/  # OpenAI and Ollama providers + model_info.py
    │   ├── object_model/   # Tool, Message, LLMProvider abstractions
    │   ├── tools/          # Tools discovered automatically at startup
    │   ├── mcp_client/     # Preview of MCP tool discovery (covered in Chapter 7)
    │   ├── mcp_tools/      # Example MCP servers
    │   └── tests/
    └── frontend/
        ├── cli/            # config_template.json -> config.json
        ├── chainlit/       # config_template.yaml -> config.yaml
        └── slack/          # config_template.toml -> config.toml, slack_app_manifest.yaml
```

## Prerequisites

- Python 3.12 or 3.13 (Chainlit, one of the dependencies, does not run on Python 3.14 yet)
- An LLM, either:
  - **Ollama** running locally with a model that supports tool calling, for example
    `ollama pull llama3.1:8b` (other tool-capable models such as `qwen3`, `gpt-oss` or `gemma4` work too), or
  - an **OpenAI API key** (the book uses `gpt-4o`)
- Optional, only needed by the tools of the same name: `git`, `kubectl`, `ollama`,
  [`gh`](https://cli.github.com/) (for the `github` tool; log in with `gh auth login`), and an
  [Anthropic API key](https://platform.claude.com/) (for the `claude` tool)

## Setup

```shell
cd ch06/ai-six/py
python3 -m venv venv              # use python3.13 if your python3 is 3.14 or newer
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
- **Ollama**: set both `default_model_id` and `provider_config.ollama.model` to the model you pulled, written exactly
  as `ollama list` shows it (including the tag):

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
from `ANTHROPIC_API_KEY` (set it in `py/.env`); without a key the tool is still listed, but answers that the key
is not configured when the agent calls it. It uses `claude-sonnet-5-5` unless the agent asks for another model.

## Running the Chainlit web UI

```shell
cd ch06/ai-six
./ai6.sh chainlit
```

Open http://localhost:8000 and start chatting. The settings panel (gear icon next to the message box) lets you
switch between all the models the configured providers serve and enable/disable individual tools.
Sessions are stored in `py/memory/chainlit/`.

## Running the Slack bot

Follow [py/frontend/slack/README.md](ai-six/py/frontend/slack/README.md) to create the Slack app from the
included manifest and get the two tokens (`AI6_APP_TOKEN`, `AI6_BOT_TOKEN`), put them in `py/.env`, then:

```shell
cd ch06/ai-six
./ai6.sh slack
```

Post in a channel whose name starts with `ai-6-`, or mention `@AI-6` in a channel you invited it to.

## Running the CLI

```shell
cd ch06/ai-six
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
cd ch06/ai-six/py
source venv/bin/activate
python -m unittest discover -s backend/tests
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Error: default_model_id '...' is not served by any configured provider` | The model in `default_model_id` must be served by a configured provider: set `OPENAI_API_KEY` for OpenAI models, or pull the model with Ollama (`ollama list` shows what is available). |
| `model '...' not found (status code: 404)` | `ollama pull <model>`, or point `OLLAMA_HOST` at the Ollama server that has it. |
| The agent answers without using tools | Use a model that supports tool calling (see [Ollama tool models](https://ollama.com/search?c=tools)). |
| Chainlit fails with `No module named 'requests'` | `pip install -r requirements.txt` again (it pins `requests`, which a Chainlit dependency forgets to declare). |
| Slack: `AI6_APP_TOKEN and AI6_BOT_TOKEN must be set` | Put both tokens in `py/.env` (see the Slack README). |
| Slack: `invalid_auth` | The bot token is wrong, or the app was not installed to the workspace. |
| `Configuration file not found: ...` | Copy the template to the name the frontend expects, e.g. `cp frontend/cli/config_template.json frontend/cli/config.json` (see Setup). |
| `virtualenv not found` | Create the virtual environment in `py/venv` as shown above. |
