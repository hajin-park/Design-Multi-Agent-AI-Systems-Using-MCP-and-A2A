<h1 align="center">
Design Multi-Agent AI Systems Using MCP and A2A, First Edition</h1>
<p align="center">This is the code repository for <a href ="design-multi-agent-ai-systems-using-mcp-and-a2a-first-edition"> Design Multi-Agent AI Systems Using MCP and A2A, First Edition</a>, published by Packt.
</p>

<h2 align="center">
Engineer your own Python-based agentic AI framework with tool use, memory, and multi-agent workflows
</h2>
<p align="center">
Gigi Sayfan</p>

<p align="center">
   <a href="https://packt.link/I1tSU" alt="Discord" title="Learn more on the Discord server"><img width="32px" src="https://cliply.co/wp-content/uploads/2021/08/372108630_DISCORD_LOGO_400.gif"/></a>
  &#8287;&#8287;&#8287;&#8287;&#8287;
  <a href="https://packt.link/free-ebook/9781806116478"><img width="32px" alt="Free PDF" title="Free PDF" src="https://cdn-icons-png.flaticon.com/512/4726/4726010.png"/></a>
 &#8287;&#8287;&#8287;&#8287;&#8287;
  <a href="https://packt.link/gbp/9781806116478"><img width="32px" alt="Graphic Bundle" title="Graphic Bundle" src="https://cdn-icons-png.flaticon.com/512/2659/2659360.png"/></a>
  &#8287;&#8287;&#8287;&#8287;&#8287;
   <a href="https://www.amazon.com/Design-Multi-Agent-Systems-Using-MCP/dp/1806116472/"><img width="32px" alt="Amazon" title="Get your copy" src="https://cdn-icons-png.flaticon.com/512/15466/15466027.png"/></a>
  &#8287;&#8287;&#8287;&#8287;&#8287;
</p>
<details open>
  <summary><h2>About the book</summary>
<a href="https://www.packtpub.com/en-in/product/design-multi-agent-ai-systems-using-mcp-and-a2a-9781806116478">
<img src="https://m.media-amazon.com/images/I/81N7ZfV4MYL._SL1500_.jpg" alt="Design Multi-Agent AI Systems Using MCP and A2A, First Edition" height="350px" align="right">
</a>

Frustrated by opaque agent frameworks that hide how things work? This book gives you complete control by guiding you through building a fully functional, extensible agentic AI framework in Python without relying on external orchestration tools.
You’ll begin by implementing a simple tool-using agent, and then gradually extend its capabilities with structured tool schemas, user interfaces, and memory via the Model Context Protocol (MCP). From there, you’ll build collaborative multi-agent systems powered by Agent-to-Agent (A2A) messaging and deploy them in realistic environments. Along the way, you’ll explore secure tool invocation, message routing, observability, and human-in-the-loop workflows.
With annotated code, deep engineering insights, and practical deployment patterns, this hands-on guide equips you to build AI agents that reason, plan, act, and adapt, whether you’re shipping production systems or experimenting with cutting-edge LLM-based architectures.
Written by Gigi Sayfan, who builds AI agent infrastructure at Perplexity and is a bestselling author with decades of experience in AI and distributed systems, this book gives you the tools and knowledge to engineer your own advanced agentic systems.
*Email sign-up and proof of purchase required
</details>
<details open>
  <summary><h2>Key Learnings</summary>
<ul>

<li>Design and implement tool-using AI agents from the ground up</li>

<li>Build modular components for extensible agent frameworks</li>

<li>Create secure and observable tools with structured inputs</li>

<li>Integrate agents with chat UIs such as Slack and Chainlit</li>

<li>Leverage MCP for context handling and agent memory</li>

<li>Orchestrate collaborative agent workflows using A2A</li>

<li>Debug and deploy agents in production-like environments</li>

<li>Explore future-ready agent capabilities and GenUX design</li>

</ul>

  </details>

<details open>
  <summary><h2>Chapters</summary>


| Chapters | 
| :-------- |
| **Chapter 1: Introduction to Generative AI and AI agents** |
| **Chapter 2: Understanding How AI Agents Work** |
| **Chapter 3: A Hands on Walk-Through of a Simple AI Agent** |
| **Chapter 4: Building a Tool-Based Agentic AI Framework** |
| **Chapter 5: Implementing Custom Tools** |
| **Chapter 6: Creating Chat Interfaces Using Slack and Chainlit** |
| **Chapter 7: Integrating with the Model Context Protocol Ecosystem** |
| **Chapter 8: Designing Multi-Agent Systems** |
| **Chapter 9: Implementing Multi-Agent Systems with A2A** |
| **Chapter 10: Testing, Debugging, and Troubleshooting Multi-Agent Systems** |
| **Chapter 11: Deploying Multi- Agent Systems** |
| **Chapter 12: Advanced Topics and Future Directions** |






</details>


<details open>
  <summary><h2>Requirements for this book</summary>


## Software and Hardware Requirements

### Prerequisites
Before getting started, you should have:
- A basic understanding of Python programming
- Familiarity with machine learning concepts
- A basic understanding of large language models (LLMs)

### Supported Operating Systems
The examples in this book can be run on:
- macOS
- Linux
- Windows, inside [WSL 2](https://learn.microsoft.com/windows/wsl/install) (the code relies on bash scripts and
  Unix-only Python libraries, so it does not run in PowerShell or cmd)

### Required Software

| Software | Version / Requirement | Needed for |
|---|---|---|
| Python | 3.12 or 3.13 | All chapters |
| An LLM | An OpenAI API key, **or** [Ollama](https://ollama.com) with a tool-calling model (e.g. `llama3.1:8b`) | All chapters |
| [uv](https://docs.astral.sh/uv/getting-started/installation/) | Latest | Chapters 8, 9 |
| Docker, [kind](https://kind.sigs.k8s.io/), kubectl | Docker Desktop, or Docker Engine on Linux | Chapters 3, 8, 9, 11 |
| Slack workspace + app | Optional | Chapters 6, 9, 11 (Slack parts) |

Every example works with either OpenAI or a local Ollama model; each chapter README shows both configurations.

### Recommended Hardware
- A machine with at least **8 GB of RAM** is recommended for running more complex examples
  (16 GB or more if you run local models with Ollama alongside the kind clusters).

### Additional Notes
If you are using the digital version of this book, we recommend typing the code manually or accessing it directly from the book’s GitHub repository (link provided in the next section).  
This helps avoid errors that may occur from copying and pasting code.
  </details>

<details open>
  <summary><h2>Using this repository</h2></summary>

Every chapter directory is **self-contained**: it has all the code, configuration templates and instructions it needs,
so you can open the book at any chapter and follow along without the previous chapters' work. Start with the
chapter's `README.md`.

| Chapter | Directory | What's inside |
|---|---|---|
| 1, 2 | - | No code in this repository |
| 3: A Hands-on Walk-Through of a Simple AI Agent | [ch03](ch03) | `k8s-ai`: a ~70-line agent that runs kubectl for you |
| 4: Building a Tool-Based Agentic AI Framework | [ch04](ch04) | AI-6 framework v0.8.0: engine, LLM providers, tools, CLI |
| 5: Implementing Custom Tools | [ch05](ch05) | AI-6 v0.9.0: custom tools (`claude`, `github`, ...) |
| 6: Creating Chat Interfaces Using Slack and Chainlit | [ch06](ch06) | AI-6 v0.10.0: Chainlit web UI and Slack bot |
| 7: Integrating with the Model Context Protocol Ecosystem | [ch07](ch07) | AI-6 v0.11.0: local and remote MCP servers |
| 8: Designing Multi-Agent Systems | [ch08](ch08) | AI-6 v0.13.0 (sub-agents, A2A client) + k8s-ai A2A server |
| 9: Implementing Multi-Agent Systems with A2A | [ch09](ch09) | MAKDO multi-agent DevOps team + k8s-ai A2A server |
| 10: Testing, Debugging, and Troubleshooting Multi-Agent Systems | - | No separate directory in this repository |
| 11: Deploying Multi-Agent Systems | [ch11](ch11) | MAKDO and k8s-ai deployed to two kind clusters |
| 12: Advanced Topics and Future Directions | - | No code in this repository |

### Choosing the LLM

- **OpenAI**: set `OPENAI_API_KEY` (the examples use `gpt-4o`, which you can change in the config files).
- **Ollama**: install Ollama, `ollama pull llama3.1:8b` (or another
  [model with tool support](https://ollama.com/search?c=tools)), and select it in the chapter's config file as
  described in the chapter README. Chapters 3, 9 and 11 use Ollama through its OpenAI-compatible endpoint
  (`OPENAI_BASE_URL=http://localhost:11434/v1`).

### Dependency versions

The code was written against the 1.x line of the MCP Python SDK and the 0.3.x line of the A2A SDK. Both have since
released new major versions with breaking API changes (e.g. `mcp` 2.x renamed `FastMCP`), so the requirement files
pin each dependency to the newest compatible range that was tested with the chapter's code.

### Platform notes

The commands in the chapter READMEs are for a bash-compatible shell and are the same on macOS, Linux and WSL 2.

- **Windows**: do everything inside WSL 2. Clone the repository there, and install Python, Ollama and the other
  tools there. For the Kubernetes chapters, turn on WSL integration in Docker Desktop's settings.
- **Debian/Ubuntu (including WSL 2)**: `python3 -m venv` needs the `python3-venv` package
  (`sudo apt install python3-venv`).
- **Python 3.14 or newer**: Chainlit, a dependency of Chapters 4-8, does not run on it yet. Create those chapters'
  virtual environments with Python 3.13 instead (`python3.13 -m venv venv`). Chapters 8, 9 and 11 use `uv` or
  Docker for the other components, which pick a suitable Python on their own.
- **Linux with Docker Engine** (no Docker Desktop): Chapter 11 needs a few changed addresses, listed in
  [ch11/README.md](ch11/README.md#linux-with-docker-engine).

</details>




<details>
  <summary><h2>Get to know Author</h2></summary>

_Gigi Sayfan_ is a member of the AI agents infra team at Perplexity, focused on building large-scale environments and harnesses for AI agents. He brings over 30 years of software development experience across domains, including instant messaging, chip fabrication process control, embedded multimedia for game consoles, brain-inspired machine learning, custom browser development, web services for distributed 3D game platforms, IoT sensors, and virtual reality. He has written production code in Go, Python, Java, C#, C++, and TypeScript/JavaScript. His expertise includes AI agents, generative AI, cloud-native technologies, DevOps, databases, networking, and distributed systems. Gigi has authored books and articles on Kubernetes and microservices.



</details>
<details>
  <summary><h2>Other Related Books</h2></summary>
<ul>

  <li><a href="https://www.packtpub.com/en-us/product/context-engineering-for-multi-agent-systems-first-edition/9781806690053">Context Engineering for Multi-Agent Systems, First Edition</a></li>

  <li><a href="https://www.packtpub.com/en-us/product/unlocking-data-with-generative-ai-and-rag-second-edition/9781806381654">Unlocking Data with Generative AI and RAG, Second Edition</a></li>

</ul>

</details>
