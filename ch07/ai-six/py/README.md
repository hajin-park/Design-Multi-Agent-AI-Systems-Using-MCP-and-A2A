# AI-6 - Python

This is the root directory of the Python implementation of AI-6

There are  backend and frontend directories

The backend directory contains the AI-6 engine and tools
The frontend directory contains the CLI and Slack frontend


# Python Setup

Currently multiple components of AI-6 are implemented in Python.
We will use a shared virtual environment for all Python components.

## Create virtual environment and activate it

```shell
python3 -m venv venv --prompt ai6
source venv/bin/activate
```

## Install dependencies

```
pip install -r requirements.txt
```

## Configure

```shell
cp .env.example .env    # add OPENAI_API_KEY if you use OpenAI models
cp frontend/cli/config_template.json frontend/cli/config.json
```

Edit `frontend/cli/config.json` and set `default_model_id` (and `provider_config.ollama.model` for Ollama).
Config paths are relative to this `py` directory.

## Run the tests

```shell
python -m unittest discover -s backend/tests
```
