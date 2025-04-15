#!/bin/bash
set -e

# Create optimal Python development environment with UV
echo "🚀 Setting up LlamaSearchAI development environment..."

# Install UV if not available
if ! command -v uv &> /dev/null; then
    echo "Installing UV package manager..."
    curl -sSf https://install.astral.sh/uv | bash
fi

# Create fresh virtual environment
echo "Creating Python virtual environment..."
uv venv .venv --python=3.11
source .venv/bin/activate || { echo "Failed to activate venv"; exit 1; }

# Install dependencies with UV
echo "Installing dependencies..."
uv pip install -r requirements.txt
uv pip install -r requirements-dev.txt

# Install project in development mode
echo "Installing project in development mode..."
uv pip install -e ".[all]"

# Set up pre-commit hooks
if [ -f .pre-commit-config.yaml ]; then
    echo "Setting up pre-commit hooks..."
    uv pip install pre-commit
    pre-commit install
fi

# Check for MLX availability
echo "Checking for MLX acceleration..."
python -c "import mlx.core; print('✅ MLX is available!')" 2>/dev/null || echo "⚠️ MLX is not available. Some features will be disabled."

echo "✅ Setup complete! Activate your environment with: source .venv/bin/activate" 