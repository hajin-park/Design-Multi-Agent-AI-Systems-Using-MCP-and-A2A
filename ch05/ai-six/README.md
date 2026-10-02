# AI-6
Agentic AI focused on ubiquitous tool using.

![](ai-6.png)

The current implementation is in Python. check out the [py](py/README.md) directory.

There may be implementations in other languages too, in the near future.

See this [link](https://deepwiki.com/Sayfan-AI/ai-six) for a super-deep dive into the project.

# LLM Access

It delegates all the heavy lifting to an LLM provider. Two providers are supported:

- **OpenAI** - expects the environment variable `OPENAI_API_KEY` to be set (e.g. in `py/.env`).
- **Ollama** - runs local models (e.g. `llama3.1:8b`) on `http://localhost:11434` (override with `OLLAMA_HOST`).

The model is selected with `default_model_id` in the frontend's config file.

# Usage

First create the virtual environment, install the dependencies and create your config file
(see [py/README.md](py/README.md) and [../README.md](../README.md) for the full walk-through).

Then you can run an AI-6 frontend using the startup script (`ai6.sh`), which runs everything from the `py` directory.

**Example — Run the CLI frontend:**

```
./ai6.sh cli
```

## Debugging with VS Code

If you are developing in VS Code, you can use one of the following debug configurations to:

 - Launch the startup script directly with the debugger attached, or

 - Attach the debugger to a running process (by manually running the script with `--debug`)

Add these debug configurations to your `.vscode/launch.json` file:

```
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        <... Other Configurations ...>,
        {
            "name": "AI6 Debugger: CLI",
            "type": "debugpy",
            "request": "launch",
            "program": "${workspaceFolder}/ai6.sh",
            "args": [
                "cli",
                "--debug",
            ],
            "console": "integratedTerminal"
        },
        {
            "name": "AI6 Debugger: Attach",
            "type": "debugpy",
            "request": "attach",
            "connect": {
                "host": "localhost",
                "port": 5678
            },
            "justMyCode": true
        }
    ]
}
```





