# Chapter 7: Integrating with the Model Context Protocol Ecosystem

This directory contains a self-contained snapshot of the AI-6 framework
([Sayfan-AI/ai-six](https://github.com/Sayfan-AI/ai-six) v0.11.0) as it stands at the end of this chapter.
This chapter turns AI-6 into an MCP client. Tool discovery moves into `backend/engine/tool_manager.py`, which
combines three tool sources:

1. **Native AI-6 tools** from `backend/tools` (as in the previous chapters)
2. **Local MCP servers** in `backend/mcp_tools`, started over stdio:
   - `fs_mcp_server.py` - a Python [FastMCP](https://github.com/modelcontextprotocol/python-sdk) server exposing
     `ls`, `cat`, `pwd`, `mkdir` and `cp`
   - `github_mcp_server.sh` - a bash script that speaks the MCP JSON-RPC protocol directly and exposes `gh`
3. **Remote MCP servers** listed under `remote_mcp_servers` in the config file (SSE transport)

Each MCP tool is wrapped as an `MCPTool` (`backend/tools/base/mcp_tool.py`), so the engine and LLM providers
treat it like any other tool. When a native tool and an MCP tool share a name, the MCP tool wins.

```
ch07/ai-six/
├── ai6.sh                  # Launcher for all frontends
└── py/
    ├── requirements.txt
    ├── .env.example        # Environment variables template (copy to .env)
    ├── backend/
    │   ├── engine/         # Engine, Config, Session, Summarizer, tool_manager.py
    │   ├── llm_providers/  # OpenAI and Ollama providers + model_info.py
    │   ├── object_model/   # Tool, Message, LLMProvider abstractions
    │   ├── tools/          # Tools discovered automatically at startup
    │   ├── mcp_client/     # MCPClient: connects to local (stdio) and remote (SSE) MCP servers
    │   ├── mcp_tools/      # Local MCP servers, discovered automatically
    │   └── tests/
    └── frontend/
        ├── cli/            # config_template.json -> config.json
        ├── chainlit/       # config_template.yaml -> config.yaml
        └── slack/          # config_template.toml -> config.toml, slack_app_manifest.yaml
```

## Prerequisites

- Python 3.12 or newer (tested with 3.13)
- An LLM, either:
  - **Ollama** running locally with a model that supports tool calling, for example
    `ollama pull llama3.1:8b` (other tool-capable models such as `qwen3`, `gpt-oss` or `gemma4` work too), or
  - an **OpenAI API key** (the book uses `gpt-4o`)
- [`jq`](https://jqlang.org/download/) - used by the `github_mcp_server.sh` MCP server
- Optional, only needed by the tools of the same name: `git`, `kubectl`, `ollama`, `aws`,
  [`gh`](https://cli.github.com/) (for the `gh` MCP tool), and an
  [Anthropic API key](https://platform.claude.com/) (for the `claude` tool)

## Setup

```shell
cd ch07/ai-six/py
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

## Using MCP tools

Start the CLI (below) and ask for something that needs an MCP tool, e.g.

```
[You]: use the cat tool to show requirements.txt
[You]: use the gh tool with args "repo list"
```

Set `show_tool_calls = True` in `py/frontend/cli/ai6.py` to see each call; MCP calls are also logged as
`Invoking tool <name> on server <server>`.

### Connecting a remote MCP server

Add the server to `remote_mcp_servers` in your config file. AI-6 uses the SSE transport, so the URL usually
ends with `/sse`:

```json
"remote_mcp_servers": [
  { "name": "remote-demo", "url": "http://localhost:8765/sse" }
]
```

To try it without a public server, run this small FastMCP server in another terminal (with the venv active):

```python
# remote_demo.py
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("Remote Demo", port=8765)

@mcp.tool()
def add_numbers(a: int, b: int) -> str:
    """Add two integers and return the sum."""
    return str(a + b)

if __name__ == "__main__":
    mcp.run(transport="sse")
```

```
[You]: use the add_numbers tool to add 1234 and 4321
[AI-6]: The sum of 1234 and 4321 is 5555.
```

## Running the Chainlit web UI

```shell
cd ch07/ai-six
./ai6.sh chainlit
```

Open http://localhost:8000 and start chatting. The settings panel (gear icon next to the message box) lets you
switch between all the models the configured providers serve and enable/disable individual tools.
Sessions are stored in `py/memory/chainlit/`.

## Running the Slack bot

Follow [py/frontend/slack/README.md](ai-six/py/frontend/slack/README.md) to create the Slack app from the
included manifest and get the two tokens (`AI6_APP_TOKEN`, `AI6_BOT_TOKEN`), put them in `py/.env`, then:

```shell
cd ch07/ai-six
./ai6.sh slack
```

Post in a channel whose name starts with `ai-6-`, or mention `@AI-6` in a channel you invited it to.

## Running the CLI

```shell
cd ch07/ai-six
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
cd ch07/ai-six/py
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
| `Warning: Failed to connect to remote MCP server` | Check the server is running and the URL (SSE endpoint, usually `/sse`). |
| Chainlit fails with `No module named 'requests'` | `pip install -r requirements.txt` again (it pins `requests`, which a Chainlit dependency forgets to declare). |
| Slack: `AI6_APP_TOKEN and AI6_BOT_TOKEN must be set` | Put both tokens in `py/.env` (see the Slack README). |
| Slack: `invalid_auth` | The bot token is wrong, or the app was not installed to the workspace. |
| `virtualenv not found` | Create the virtual environment in `py/venv` as shown above. |
