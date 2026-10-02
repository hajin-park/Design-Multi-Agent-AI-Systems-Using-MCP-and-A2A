# Chapter 4: Building a Tool-Based Agentic AI Framework

This directory contains a self-contained snapshot of the AI-6 framework
([Sayfan-AI/ai-six](https://github.com/Sayfan-AI/ai-six) v0.8.0) as it stands at the end of this chapter:
the engine (agentic loop), the object model, the LLM providers (OpenAI and Ollama), the tool system
(file system, git, kubectl, ollama, test runner, bootstrap, session memory) and the CLI frontend.

```
ch04/ai-six/
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
        ├── chainlit/       # (covered in Chapter 6)
        └── slack/          # (covered in Chapter 6)
```

## Prerequisites

- Python 3.12 or newer (tested with 3.13)
- An LLM, either:
  - **Ollama** running locally with a model that supports tool calling, for example
    `ollama pull llama3.1:8b` (other tool-capable models such as `qwen3`, `gpt-oss` or `gemma4` work too), or
  - an **OpenAI API key** (the book uses `gpt-4o`)
- Optional, only needed by the tools of the same name: `git`, `kubectl`, `ollama`, `gh`

## Setup

```shell
cd ch04/ai-six/py
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

cp .env.example .env                                         # then edit .env
cp frontend/cli/config_template.json frontend/cli/config.json  # then edit config.json
```

### Choosing the model

`frontend/cli/config.json` selects the model through `default_model_id`. Each entry under
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

## Running the CLI

```shell
cd ch04/ai-six
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
cd ch04/ai-six/py
source venv/bin/activate
python -m unittest discover -s backend/tests
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Error: default_model_id '...' is not served by any configured provider` | The model in `default_model_id` must be served by a configured provider: set `OPENAI_API_KEY` for OpenAI models, or pull the model with Ollama (`ollama list` shows what is available). |
| `model '...' not found (status code: 404)` | `ollama pull <model>`, or point `OLLAMA_HOST` at the Ollama server that has it. |
| The agent answers without using tools | Use a model that supports tool calling (see [Ollama tool models](https://ollama.com/search?c=tools)). |
| `virtualenv not found` | Create the virtual environment in `py/venv` as shown above. |
