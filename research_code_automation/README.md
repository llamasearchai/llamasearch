# Research Code Automation Tool

A powerful research automation tool integrated with LlamaSearchAI for advanced searching, text analysis, PDF processing, and code analysis.

## Features

- **Text Analysis**: Summarize and extract key information from research texts
- **PDF Processing**: Extract text from PDFs with optional OCR capabilities
- **Code Analysis**: Analyze code for complexity, issues, and recommendations
- **Research Support**: Generate research questions and organize research materials
- **LlamaSearchAI Integration**: Leverage LlamaSearchAI capabilities for advanced searching

## Installation

### Prerequisites

- Python 3.9 or higher
- Poetry (recommended for dependency management)
- OCRmyPDF (optional, for OCR capabilities)
- PyTesseract and Tesseract OCR (optional, for OCR capabilities)

### Method 1: Quick Setup (Recommended)

We provide a convenient setup script that handles all the installation and configuration steps for you:

```bash
# Clone the repository
git clone https://github.com/llamasearchai/research-code-automation.git
cd research-code-automation

# Make the setup script executable
chmod +x setup_env.py

# Run the setup process with development dependencies
./setup_env.py --dev
```

### Method 2: Manual Installation with pip

```bash
# Clone the repository
git clone https://github.com/llamasearchai/research-code-automation.git
cd research-code-automation

# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -e .
```

### Method 3: Installation with Make

If you have `make` installed, you can use our Makefile:

```bash
# Clone the repository
git clone https://github.com/llamasearchai/research-code-automation.git
cd research-code-automation

# Setup development environment
make setup
```

### Method 4: Installation with Docker

```bash
# Clone the repository
git clone https://github.com/llamasearchai/research-code-automation.git
cd research-code-automation

# Build and run with Docker
docker-compose up -d
```

## Configuration

After installation, you need to configure the tool by creating a `.env` file:

```bash
# Copy the example environment file
cp .env.example .env

# Edit the file with your preferred editor
nano .env
```

Set the following required variables:
- `OPENAI_API_KEY`: Your OpenAI API key for AI text processing
- `GITHUB_TOKEN`: (Optional) Your GitHub token for code repositories access

## Usage

The tool can be run in three different modes:

### API Mode

```bash
# Run the API server
./run.sh --api

# Specify host and port
./run.sh --api --host 127.0.0.1 --port 8080
```

### CLI Mode

```bash
# Run a specific CLI command
./run.sh --cli text summarize "Your text to summarize"
./run.sh --cli pdf extract path/to/your.pdf --ocr
./run.sh --cli code analyze path/to/your/code.py
```

### GUI Mode

```bash
# Launch the graphical user interface
./run.sh --gui
```

## Development

We use various tools to maintain code quality:

```bash
# Run tests
make test

# Run linters
make lint

# Format code
make format

# Run all checks
make checks
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [LlamaSearchAI](https://github.com/llamasearchai) for providing the search capabilities
- The open-source community for the various libraries used in this project 