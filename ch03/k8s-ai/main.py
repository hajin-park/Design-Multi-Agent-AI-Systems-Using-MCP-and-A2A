import json
import os

import sh
from openai import OpenAI

# Set OPENAI_BASE_URL to use any OpenAI-compatible server, e.g. Ollama (http://localhost:11434/v1)
client = OpenAI(api_key=os.environ['OPENAI_API_KEY'])
model_name = os.environ.get('K8S_AI_MODEL', 'gpt-4o')
tools = [{
    "type": "function",
    "function": {
        "name": "kubectl",
        "description": "execute a kubectl command against the current k8s cluster",
        "parameters": {
            "type": "object",
            "properties": {
                "cmd": {
                    "type": "string",
                    "description": (
                        "the kubectl command to execute (without kubectl, just "
                        "the arguments). For example, 'get pods'"
                    ),
                },
            },
            "required": ["cmd"],
        },
    },
}]


def send(messages: list[dict[str, any]]) -> str:
    response = client.chat.completions.create(
        model=model_name, messages=messages, tools=tools, tool_choice="auto")
    r = response.choices[0].message
    if r.tool_calls:
        message = dict(
            role=r.role,
            content=r.content,
            tool_calls=[dict(id=t.id, type=t.type, function=dict(name=t.function.name, arguments=t.function.arguments)
                             ) for t in r.tool_calls if t.function])
        messages.append(message)
        for t in r.tool_calls:
            if t.function.name == 'kubectl':
                cmd = json.loads(t.function.arguments)['cmd'].split()
                if cmd and cmd[0] == 'kubectl':  # some models include the command name
                    cmd = cmd[1:]
                try:
                    result = sh.kubectl(cmd)
                except sh.ErrorReturnCode as e:
                    # Let the LLM see the error instead of crashing
                    result = e.stderr.decode() or e.stdout.decode()
                messages.append(dict(tool_call_id=t.id, role="tool", name=t.function.name, content=result))
        return send(messages)
    return (r.content or '').strip()


def main():
    print("☸️ Interactive Kubernetes Chat. Type 'exit' to quit.\n" + "-" * 52)
    messages = [{'role': 'system', 'content': 'You are a Kubernetes expert ready to help'}]
    while (user_input := input("👤 You: ")).lower() != 'exit':
        messages.append(dict(role="user", content=user_input))
        response = send(messages)
        print(f"🤖 AI: {response}\n----------")


if __name__ == "__main__":
    main()
