#!/bin/bash
set -e

# Initialize a new LlamaSearchAI project
echo "🦙 Initializing new LlamaSearchAI project..."

# Parse arguments
PROJECT_NAME=${1:-llamasearch-project}
MODELS_LOCATION=${2:-"models"}
DATA_LOCATION=${3:-"data"}

# Create project directory
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create basic directory structure
mkdir -p "$MODELS_LOCATION" "$DATA_LOCATION" "cache" "logs"

# Create .env file
cat > .env << EOL
# LlamaSearchAI Configuration
LLAMASEARCH_MODEL_DIR=$(pwd)/$MODELS_LOCATION
LLAMASEARCH_DATA_DIR=$(pwd)/$DATA_LOCATION
LLAMASEARCH_CACHE_DIR=$(pwd)/cache
LLAMASEARCH_LOG_LEVEL=INFO

# API Keys (fill in your keys)
LLAMASEARCH_EXA_API_KEY=your_exa_key_here
GOOGLE_API_KEY=your_google_key_here
GOOGLE_CX=your_google_cx_here

# Server Configuration
API_HOST=0.0.0.0
API_PORT=8080
EOL

# Create config files
mkdir -p config
cat > config/llamasearch.toml << EOL
# LlamaSearchAI Configuration

[logging]
level = "INFO"
file = "logs/llamasearch.log"

[server]
host = "0.0.0.0"
port = 8080
workers = 4

[search]
default_engine = "exa"
results_per_page = 10
vector_search = true

[storage]
vector_db = "json"  # Options: json, qdrant, faiss
vector_db_path = "$DATA_LOCATION/vectors.json"

[model]
embeddings_model = "all-mpnet-base-v2"
mlx_acceleration = true
EOL

# Create Docker Compose file
cat > docker-compose.yml << EOL
version: '3.8'

services:
  # LlamaSearchAI API server
  llamasearch:
    image: llamasearchai/llamafind-ultra:latest
    ports:
      - "8080:8080"
    volumes:
      - ./$MODELS_LOCATION:/data/models
      - ./$DATA_LOCATION:/data/data
      - ./cache:/data/cache
      - ./logs:/data/logs
      - ./config:/app/config
    environment:
      - LLAMASEARCH_MODEL_DIR=/data/models
      - LLAMASEARCH_DATA_DIR=/data/data
      - LLAMASEARCH_CACHE_DIR=/data/cache
      - API_HOST=0.0.0.0
      - API_PORT=8080
    restart: unless-stopped

  # Vector database (Qdrant) - optional
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
    volumes:
      - ./data/qdrant:/qdrant/storage
    restart: unless-stopped
EOL

# Create README.md
cat > README.md << EOL
# $PROJECT_NAME

This is a LlamaSearchAI project for advanced search and research.

## Setup

1. Install dependencies:
   \`\`\`
   pip install llamafind-ultra
   \`\`\`

2. Set up environment:
   \`\`\`
   source .env
   \`\`\`

3. Start the server:
   \`\`\`
   llamasearch server
   \`\`\`

## Using Docker

Run with Docker Compose:
\`\`\`
docker-compose up -d
\`\`\`

## Configuration

Edit \`.env\` and \`config/llamasearch.toml\` to customize your settings.
EOL

echo "✅ Project initialized successfully!"
echo "📁 Project location: $(pwd)"
echo "🔧 Next steps:"
echo "   1. Edit .env with your API keys"
echo "   2. Install LlamaSearchAI: pip install llamafind-ultra"
echo "   3. Start the server: llamasearch server" 