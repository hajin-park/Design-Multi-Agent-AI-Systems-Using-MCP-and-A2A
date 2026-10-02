# Python CLI Program Builder Agent

This example demonstrates how to create a multi-agent system that builds Python CLI programs. The system uses a project
manager agent that coordinates with specialized sub-agents to design, implement, and test Python command-line
applications.

## What This Agent System Does

The Python CLI Builder consists of three specialized agents:

- **Project Manager**: Coordinates the overall workflow and manages project requirements
- **Python CLI Developer**: Expert in building Python CLI applications with proper argument parsing, commands, and
  structure
- **Python Tester**: Creates comprehensive tests and validates the generated CLI programs

Together, they can build complete Python CLI applications from user specifications.

## Setup

**Python environment**: the examples use the AI-6 virtual environment in `py/venv` (see the chapter README):

```bash
cd ch08/ai-six/py
source venv/bin/activate
```

**Model**: `config.yaml` uses `gpt-4o` with `OPENAI_API_KEY` (from your environment or `py/.env`). To use a local
Ollama model instead, set `default_model_id` and `provider_config.ollama.model` in `config.yaml` to the same
tool-capable model (e.g. `llama3.1:8b`). Paths in `config.yaml` use `${AI6_PY_DIR}`, which the script sets to the
`py` directory automatically.

**No additional authentication is required** - the agent system works entirely with local Python development tools.

## Running the Agent

**Run the Agent** from this directory:

```bash
python cli_program_builder.py
```

**Command Line Options**:

- `--output-dir PATH`: Specify where CLI projects should be created (default: `~/cli-python-projects`)
- Environment variable: `CLI_PROGRAM_BUILDER_OUTPUT_DIR` can also set the output directory

Examples:

```bash
# Use default output directory
python cli_program_builder.py

# Specify custom output directory
python cli_program_builder.py --output-dir ~/python-cli-projects

# Use environment variable
export CLI_PROGRAM_BUILDER_OUTPUT_DIR=~/python-cli-projects
python cli_program_builder.py
```

## Example Session

Here's a short session building a simple file organizer CLI:

```bash
$ python cli_program_builder.py

📁 Projects will be created in: /Users/username/cli-python-projects
🔧 Starting Python CLI Program Builder
=====================================

Project Manager: Hello! I'm a project manager specializing in building Python CLI programs. 
I work with two expert sub-agents:
- A Python CLI Developer who writes the code
- A Python Tester who ensures quality and creates tests

What Python CLI program would you like me to help you build today?

User: I need a CLI tool that organizes files in a directory by their extensions

Project Manager: Excellent! I'll coordinate with my team to build a file organizer CLI.
Let me start by having our CLI Developer create the initial program structure...

[The system then coordinates between the project manager, developer, and tester agents 
to create a complete CLI application with proper argument parsing, file organization 
logic, and comprehensive tests]
```

## Configuration

The agent uses a [multi-agent configuration](config.yaml) file that defines a project manager and two specialized
sub-agents. The configuration file is structured as follows:

```yaml
default_model_id: gpt-4o
tools_dirs:
  - ${AI6_PY_DIR}/backend/tools
mcp_tools_dirs:
  - ${AI6_PY_DIR}/backend/mcp_tools
memory_dir: ${AI6_PY_DIR}/memory/cli-program-builder
checkpoint_interval: 3
provider_config:
  openai:
    api_key: ${OPENAI_API_KEY}
system_prompt: |
  You are a project manager specializing in building Python CLI programs. You coordinate
  with two expert sub-agents to deliver complete CLI applications:

  1. A Python CLI Developer - builds the actual CLI program
  2. A Python Tester - creates tests and ensures quality

  Your scope is ONLY Python CLI programs. If users request non-CLI programs or non-Python
  programs, politely decline and explain your specialization.

  When building CLI programs, coordinate the workflow and pass the output directory
  context to your sub-agents.

agents:
  - name: cli-developer
    system_prompt: |
      You are an expert Python CLI developer. You specialize in building well-structured
      command-line applications using modern Python practices, proper argument parsing,
      and clean code architecture.
    enabled_tools:
      - filesystem

  - name: cli-tester
    system_prompt: |
      You are a Python testing specialist. You create comprehensive test suites for
      CLI applications, including unit tests, integration tests, and edge case validation.
    enabled_tools:
      - filesystem
      - pytest
```

## How It Works

1. **Multi-Agent Initialization**: Creates a project manager agent with two specialized sub-agents
2. **Workflow Coordination**: Project manager coordinates between developer and tester agents
3. **Output Directory Management**: Command-line specified output directory is injected into agent system prompts for
   consistent project organization
4. **Interactive Development**: Allows iterative refinement and follow-up questions
5. **Memory Persistence**: Maintains conversation history and project context across agents

## Customization

You can modify the system's behavior by:

- Editing the system prompts for each agent in `config.yaml`
- Changing the output directory location
- Adding additional tools to specific agents
- Modifying the agent coordination workflow
- Adding new specialized sub-agents for specific tasks

This example demonstrates how to create a coordinated multi-agent system with AI-6 that specializes in building Python
CLI applications through agent collaboration.
