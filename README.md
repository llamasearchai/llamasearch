# LlamaSearchAI

LlamaSearchAI is an advanced search and research platform that combines multiple search engines with AI-powered research capabilities.

## Features

- **Multi-Engine Search**: Search across multiple engines (Brave, Google, Perplexity) for comprehensive results
- **Conversational Chat**: AI-powered chat interface with time awareness
- **Financial Data**: Stock information with price, change, and volume data
- **Agent-Based Architecture**: Modular design with specialized agents for different tasks
- **API Server**: RESTful API for integration with other applications
- **CLI Interface**: Command-line interface for direct interactions

## Architecture

The system consists of:

- **Core Module**: Model handling and configuration management
- **Search Module**: Search engine integrations and result processing
- **Agents Module**: Specialized agents for different tasks
- **Server Module**: API server for web-based access
- **CLI Interface**: Command-line tool for direct interactions

## Getting Started

### Prerequisites

- Python 3.9+
- API keys for search providers:
  - Brave Search API key
  - Google Search API key and Search Engine ID
  - Perplexity API key
- API keys for LLMs (optional):
  - OpenAI API key
  - Anthropic API key

### Installation

1. Clone the repository:

```bash
git clone https://github.com/yourusername/llamasearchai.git
cd llamasearchai
```

2. Set up environment variables:

```bash
cp .env.example .env
# Edit .env with your API keys
```

3. Install the package:

```bash
pip install -e .
```

### Configuration

Create or edit `config/llamafind.toml` with your settings:

```toml
# LlamaFind Ultra Configuration

app_name = "LlamaFind Ultra"
version = "1.0.0"
debug = false

[server]
host = "127.0.0.1"
port = 8000
workers = 4

[models]
default = "gpt-3.5-turbo"

[api_keys]
brave = "$LLAMASEARCH_BRAVE_API_KEY"
google = "$GOOGLE_API_KEY"
perplexity = "$LLAMASEARCH_PERPLEXITY_API_KEY"
```

## Usage

### CLI Interface

Use the CLI for interactive sessions:

```bash
# Chat agent
python cli.py --agent chat

# Search agent
python cli.py --agent search

# Finance agent
python cli.py --agent finance

# Run a specific task
python cli.py --agent search --task "What is the capital of France?"
```

### API Server

Start the API server:

```bash
python -m llamafind_ultra.server.app
```

The server provides the following endpoints:

- `GET /api/health`: Check server health
- `GET /api/agents`: List available agents
- `POST /api/agents/{agent_type}/message`: Send a message to an agent
- `POST /api/agents/{agent_type}/tasks`: Create a task for an agent
- `GET /api/agents/{agent_type}/tasks/{task_id}`: Get a task by ID
- `POST /api/agents/{agent_type}/tasks/{task_id}/run`: Run a task

### Python API

Use the Python API directly in your code:

```python
from llamafind_ultra.agents import AgentConfig
from llamafind_ultra.agents.search_agent import SearchAgent

# Create a search agent
config = AgentConfig(
    name="My Search Agent",
    agent_type="search",
    capabilities=["web_search"]
)
agent = SearchAgent(config)

# Process a message
response = agent.process_message("What is the capital of France?")
print(response.content)
```

## Development

### Running Tests

Run the test suite:

```bash
python -m unittest discover -s tests
```

### Adding a New Search Provider

Create a new provider class that extends `SearchEngine` in `llamafind_ultra/search/providers/`:

```python
from ..engine import SearchEngine, SearchQuery, SearchResult

class MyNewSearch(SearchEngine):
    def search(self, query):
        # Implement search functionality
        pass
```

### Adding a New Agent

Create a new agent class that extends `Agent` in `llamafind_ultra/agents/`:

```python
from .base import Agent, AgentConfig, AgentMessage, AgentResponse

class MyNewAgent(Agent):
    def process_message(self, message):
        # Implement message processing
        pass
        
    def create_task(self, description):
        # Implement task creation
        pass
        
    def run_task(self, task_id):
        # Implement task execution
        pass
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- This project uses several open-source libraries and APIs
- Special thanks to the LlamaSearchAI team for their contributions 