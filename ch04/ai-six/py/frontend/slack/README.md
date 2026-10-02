# AI-6 Slack UI

Integrate the AI-6 bot with Slack to provide a seamless messaging experience.

## Using Slack programmatically

Slack provides an RPC-style API that allows programmatic interaction. It facilitates sending messages, managing channels, and more. The API includes two main groups:

- [Web API](https://docs.slack.dev/apis/web-api/): Interact with and modify Slack workspaces.
- [Event API](https://docs.slack.dev/apis/events-api/): Build apps and bots that respond to Slack activities.

Using the API directly can be complex due to the need to handle HTTP requests, JSON payloads, authentication, retries, rate limiting, and pagination.

To simplify, use the [Bolt library](https://tools.slack.dev/bolt-python/).

## Create the Slack app

1. Go to [api.slack.com/apps](https://api.slack.com/apps) and click **Create New App** -> **From a manifest**.
   Pick your workspace and paste the contents of [slack_app_manifest.yaml](slack_app_manifest.yaml)
   (YAML tab). It enables Socket Mode, subscribes to message events and requests the bot scopes AI-6 needs.
2. **Basic Information** -> **App-Level Tokens** -> **Generate Token and Scopes**: add the `connections:write`
   scope. The generated `xapp-...` token is your `AI6_APP_TOKEN`.
3. **Install App** -> **Install to Workspace**. The **Bot User OAuth Token** (`xoxb-...`) is your `AI6_BOT_TOKEN`.
4. Put both tokens in `py/.env` (see `py/.env.example`) or in `py/frontend/slack/.env`:

   ```
   AI6_APP_TOKEN=xapp-...
   AI6_BOT_TOKEN=xoxb-...
   ```

5. In Slack, create a public channel whose name starts with `ai-6-` (e.g. `#ai-6-playground`). On startup AI-6
   joins the first such channel and responds to every message posted there. In any other public channel,
   invite the bot (`/invite @AI-6`) and mention it (`@AI-6 ...`).

## Configure and run

```shell
cd py
source venv/bin/activate          # see py/README.md for creating it
cp frontend/slack/config_template.toml frontend/slack/config.toml   # then set default_model_id
cd ..
./ai6.sh slack
```

Each channel gets its own session, stored under `py/memory/slack/<channel_id>/`.
Press `Ctrl+C` to stop; AI-6 posts a goodbye message and leaves the channels it joined.

# Reference

For more detailed documentation, visit:
- [Slack Dev](https://docs.slack.dev/)
- [Slack API Apps](https://api.slack.com/apps)
- [Bolt for Python](https://tools.slack.dev/bolt-python/getting-started)
