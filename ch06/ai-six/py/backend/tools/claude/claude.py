import anthropic
from backend.object_model import Tool, Parameter

class Claude(Tool):
    def __init__(self):
        desc = """Send inference requests to Anthropic Claude LLM. Useful for getting a second opinion or 
                  different perspective from another AI model.
        """
        super().__init__(
            name='claude',
            description=desc,
            parameters=[
                Parameter(
                    name='prompt',
                    type='string',
                    description='The prompt or question to send to Claude'),
                Parameter(
                    name='model',
                    type='string',
                    description="""See https://platform.claude.com/docs/en/about-claude/models/overview.
                                   Default is claude-sonnet-5-5
                    """),
                Parameter(
                    name='max_tokens',
                    type='integer',
                    description='Maximum number of tokens to generate. Defaults to 16000'),
                Parameter(
                    name='temperature',
                    type='number',
                    description='Temperature for sampling (0.0-1.0). Only for older models; newer models reject it')
            ],
            required={'prompt'}
        )
        self.client = None
    
    def configure(self, config: dict) -> None:
        """Configure the Claude tool with API key."""
        if 'api_key' in config:
            self.client = anthropic.Anthropic(api_key=config['api_key'])
    
    def run(self, **kwargs) -> str:
        if self.client is None:
            return "Error: Claude API key not configured. Set 'api_key' in tool_config for claude tool"
        
        prompt = kwargs['prompt']
        model = kwargs.get('model', 'claude-sonnet-5-5')
        max_tokens = kwargs.get('max_tokens', 16000)
        # Newer Claude models reject non-default sampling parameters, so only send temperature if requested
        extra = {'temperature': kwargs['temperature']} if 'temperature' in kwargs else {}

        try:
            response = self.client.messages.create(
                model=model,
                max_tokens=max_tokens,
                **extra,
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )
            # The response may start with a thinking block, so return the first text block
            return next((b.text for b in response.content if b.type == 'text'), '')
        except Exception as e:
            return f"Error calling Claude API: {str(e)}"
