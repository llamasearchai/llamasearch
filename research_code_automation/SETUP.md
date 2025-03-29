# Research Code Automation Tool - Setup Guide

This guide will help you install and set up the Research Code Automation Tool, which integrates with LlamaSearchAI for advanced research automation.

## Prerequisites

Before you begin, make sure you have the following installed:

- Python 3.9 or higher
- pip (Python package manager)
- Git
- Virtual environment tools (`venv` or `virtualenv`)
- Docker and Docker Compose (optional, for containerized deployment)

## Installation

### Method 1: Using the Setup Script (Recommended)

We provide a convenient setup script that handles all the installation and configuration steps for you:

```bash
# Clone the repository
git clone https://github.com/llamasearchai/research-code-automation.git
cd research-code-automation

# Make the run script executable
chmod +x run.sh

# Run the setup process
./run.sh --setup
```

The setup script will:
1. Create a virtual environment
2. Install all required dependencies
3. Create a `.env` file from the template
4. Create necessary data directories

### Method 2: Manual Installation

If you prefer to set up manually, follow these steps:

```bash
# Clone the repository
git clone https://github.com/llamasearchai/research-code-automation.git
cd research-code-automation

# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cp .env.example .env

# Create necessary directories
mkdir -p data downloads cache
```

## Configuration

After installation, you need to configure the tool by editing the `.env` file:

1. Open the `.env` file in your favorite text editor
2. Set your API keys:
   - `OPENAI_API_KEY`: Required for AI text processing
   - `GITHUB_TOKEN`: Optional, for higher GitHub API rate limits
3. Configure database settings if you're using a database other than SQLite
4. Set other optional configurations like file paths

## Running the Tool

The tool can be run in three different modes:

### API Server Mode

```bash
# Run with default settings (host: 0.0.0.0, port: 8000)
./run.sh --api

# Specify custom host and port
./run.sh --api --host 127.0.0.1 --port 8080
```

Access the API documentation at:
- http://localhost:8000/docs (Swagger UI)
- http://localhost:8000/redoc (ReDoc)

### Command-Line Interface Mode

```bash
# Run in CLI mode
./run.sh --cli

# Examples of CLI commands:
./run.sh --cli text summarize "Your text to summarize"
./run.sh --cli pdf extract path/to/your.pdf --ocr
./run.sh --cli code analyze path/to/your/code.py
./run.sh --cli research questions "Your research topic"
```

### Graphical User Interface Mode

```bash
# Run in GUI mode
./run.sh --gui
```

### Docker Mode

```bash
# Run in Docker container (API mode by default)
./run.sh --docker

# Run in Docker with custom configuration
./run.sh --docker --api --port 8080
```

## Optional Features

### OCR Capabilities

To enable OCR for PDF processing:

```bash
# On Debian/Ubuntu
sudo apt-get install tesseract-ocr ocrmypdf

# On macOS with Homebrew
brew install tesseract ocrmypdf

# On Windows
# Download and install Tesseract OCR from: https://github.com/UB-Mannheim/tesseract/wiki
```

### Web Scraping with JavaScript Support

To enable JavaScript rendering for web scraping:

```bash
# Install Playwright
pip install playwright
playwright install
```

## Troubleshooting

If you encounter issues:

1. **Environment not found**: Run `./run.sh --setup` to create the virtual environment
2. **Missing dependencies**: Ensure you've activated the virtual environment before running
3. **API key errors**: Check your `.env` file has the correct API keys
4. **Permission denied**: Run `chmod +x run.sh` to make the script executable

For more detailed troubleshooting information, see the [README.md](README.md) file.

## Support

If you need help with installation or have any questions, please:

- Create an issue on our GitHub repository
- Contact us at support@llamasearch.ai

Thank you for using the Research Code Automation Tool! 