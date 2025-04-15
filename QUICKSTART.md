# LlamaFind Quick Start Guide

This guide will help you get up and running with LlamaFind quickly.

## Installation

### Option 1: Quick Installation (All Features)

Run the installation script:

```bash
./install-all.sh
```

This script will:
- Detect your system and available features
- Create a virtual environment
- Install all dependencies
- Set up configuration files
- Make all scripts executable

### Option 2: Manual Installation

1. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install with all features:
   ```bash
   pip install -e ".[all]"
   ```

   Or install with specific features:
   ```bash
   pip install -e .                # Basic installation
   pip install -e ".[web]"         # With web interface
   ```

## Usage

### Command Line Interface

Search for something:
```bash
llamafind "your search query"
```

Interactive mode:
```bash
llamafind -i
```

### Web Interface

Start the web server:
```bash
llamafind-web
```

Then open your browser to http://localhost:8000

Options:
```bash
llamafind-web --port 8080          # Use a different port
llamafind-web --reload             # Auto-reload on code changes (development)
```

## Configuration

The default configuration file is located at `config/llamafind.toml`.

Key settings:
- `model.path`: Path to your LLM model
- `cache.enabled`: Enable/disable result caching
- `cache.directory`: Where to store cached results
- `web.port`: Default port for web interface

## Common Issues

1. **Model not found**: Ensure the model path in your configuration is correct
2. **Web interface not working**: Check if all web dependencies are installed with `pip install -e ".[web]"`
3. **Permission denied**: Make sure scripts are executable with `chmod +x scripts/llamafind.sh`

## Next Steps

- Check the full [README.md](README.md) for detailed documentation
- Explore advanced configuration options
- Try different search engines and models

Happy searching with LlamaFind! 🦙 