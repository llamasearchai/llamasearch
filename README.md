# LlamaSearch 🔎

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python Version](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)
<!-- Add build status, coverage badges -->

LlamaSearch is an advanced search and research platform, designed to provide comprehensive information retrieval by integrating multiple search engines with powerful AI-driven analysis and conversational capabilities.

## Core Features ✨

*   **Multi-Engine Integration**: Aggregates results from leading search providers (Brave, Google, Perplexity) for broad coverage.
*   **AI-Powered Chat**: Engages users with a time-aware, conversational interface for research and follow-up questions.
*   **Financial Data Agent**: Specialized agent for retrieving and presenting stock market information.
*   **Modular Agent Architecture**: Flexible design allowing easy extension with new agents and capabilities.
*   **RESTful API Server**: Provides endpoints for programmatic integration and building custom applications.
*   **Interactive CLI**: Offers a command-line interface for direct interaction with agents and tasks.
*   **Configurable**: Easy configuration via TOML files for models, API keys, and server settings.

## Architecture Overview 🏗️

LlamaSearch employs a modular, agent-based architecture:

```mermaid
graph LR
    subgraph User Interfaces
        CLI[CLI Interface]
        WebUI[Web UI / API Clients]
    end
    
    subgraph Core Services
        API[API Server (FastAPI)]
        AgentMgr[Agent Manager]
    end

    subgraph Agents
        Chat[Chat Agent]
        Search[Search Agent]
        Finance[Finance Agent]
        Custom[Custom Agents...]
    end

    subgraph Backend Modules
        Config[Configuration Loader]
        ModelMgr[LLM Model Manager]
        SearchMod[Search Module]
    end

    subgraph External Services
        Brave[Brave Search]
        Google[Google Search]
        Perp[Perplexity]
        LLM[LLM APIs (OpenAI/Anthropic)]
        FinanceAPI[Financial Data APIs]
    end

    CLI --> API;
    WebUI --> API;
    API --> AgentMgr;
    AgentMgr --> Chat;
    AgentMgr --> Search;
    AgentMgr --> Finance;
    AgentMgr --> Custom;
    
    AgentMgr --> Config;
    Chat --> ModelMgr;
    Search --> SearchMod;
    Finance --> SearchMod; # May use search for context
    Finance --> FinanceAPI;

    ModelMgr --> LLM;
    SearchMod --> Brave;
    SearchMod --> Google;
    SearchMod --> Perp;

    style API fill:#ccf,stroke:#333,stroke-width:2px
    style Agents fill:#f9d,stroke:#333,stroke-width:1px
```

*   The **API Server** acts as the main entry point.
*   The **Agent Manager** routes requests to appropriate **Agents**.
*   **Agents** utilize **Backend Modules** (Configuration, Models, Search) to perform tasks.
*   **Backend Modules** interact with **External Services**.

## Getting Started 🚀

### Prerequisites

*   Python 3.9+
*   API Keys (store securely using `llamakeys` or environment variables):
    *   Brave Search (`LLAMASEARCH_BRAVE_API_KEY`)
    *   Google Search (`GOOGLE_API_KEY`, `GOOGLE_CSE_ID`)
    *   Perplexity (`LLAMASEARCH_PERPLEXITY_API_KEY`)
    *   (Optional) OpenAI (`OPENAI_API_KEY`)
    *   (Optional) Anthropic (`ANTHROPIC_API_KEY`)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://llamasearch.ai # Update URL
    cd llamasearch
    ```

2.  **Set up environment variables:**
    *   Use a `.env` file (recommended, ensure it's in `.gitignore`):
        ```bash
        cp .env.example .env
        # Edit .env with your API keys
        ```
    *   Or export variables directly in your shell.

3.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt # Ensure requirements.txt exists and is complete
    pip install -e . # Install llamasearch in editable mode
    ```

### Configuration

Adjust settings in `config/llamafind.toml` (or your specified config file):

```toml
# config/llamafind.toml

app_name = "LlamaSearch"
version = "1.0.0"
debug = false

[server]
host = "127.0.0.1"
port = 8000
workers = 4

[models]
default = "gpt-3.5-turbo" # Or another supported model

# API keys can be sourced from environment variables
[api_keys]
brave = "$LLAMASEARCH_BRAVE_API_KEY"
google = "$GOOGLE_API_KEY" # Also needs GOOGLE_CSE_ID env var
perplexity = "$LLAMASEARCH_PERPLEXITY_API_KEY"
openai = "$OPENAI_API_KEY"
anthropic = "$ANTHROPIC_API_KEY"
```

## Usage Examples 💡

### CLI Interface

Interact directly with agents:

```bash
# Start a chat session
python cli.py --agent chat

# Perform a web search
python cli.py --agent search --task "Latest advancements in AI safety"

# Get financial info
python cli.py --agent finance --task "Get stock info for AAPL"
```

### API Server

Run the server:

```bash
# Ensure llamafind_ultra.server.app exists or adjust path
python -m llamafind_ultra.server.app # Example path, verify correct module
```

Access API endpoints (default: `http://127.0.0.1:8000`):

*   `GET /api/health`: Health check
*   `POST /api/agents/search/message`: Send message to search agent (e.g., `{"content": "Search query"}`)
*   Explore other endpoints as defined in the server code.

### Python Library Usage

Integrate into your Python applications:

```python
# Example assumes paths and imports are correct
from llamafind_ultra.agents import AgentConfig
from llamafind_ultra.agents.search_agent import SearchAgent
from llamafind_ultra.config import load_config

# Load configuration (adjust path if needed)
# config_data = load_config("config/llamafind.toml")

# Create agent config
search_config = AgentConfig(
    name="My Search Agent",
    agent_type="search",
    capabilities=["web_search"]
    # Pass other necessary config like API keys if not handled globally
)

# Instantiate the agent
search_agent = SearchAgent(search_config)

# Process a query
response = search_agent.process_message("What are the main features of LlamaSearch?")

if response and response.content:
    print("Response:", response.content)
else:
    print("Failed to get response.")
```

## Development 🛠️

### Running Tests

```bash
# Ensure you have testing dependencies installed (e.g., pytest)
pip install pytest
pytest # Discover and run tests in the tests/ directory
```

### Extending LlamaSearch

*   **New Search Providers**: Implement the `SearchEngine` interface in `llamafind_ultra/search/providers/`.
*   **New Agents**: Extend the `Agent` base class in `llamafind_ultra/agents/`.
*   Refer to the existing code structure for patterns.

## Contributing 🤝

Contributions are highly encouraged! Please review [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on secure development practices, code style, and pull request procedures.

## License 📄

Licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Support & Community 💬

*   **Issues**: Report bugs or suggest features on [GitHub Issues](https://llamasearch.ai *(Update link)*
*   **Discord**: Join the discussion on our [Community Discord](https://discord.gg/llamasearch). *(Update link)*

---

*Part of the LlamaSearchAI Ecosystem - Empowering Intelligent Search.* 
# Updated in commit 1 - 2025-04-04 16:59:27

# Updated in commit 9 - 2025-04-04 16:59:30

# Updated in commit 17 - 2025-04-04 16:59:33

# Updated in commit 25 - 2025-04-04 16:59:36
