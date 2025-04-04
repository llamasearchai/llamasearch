#!/bin/bash
# Run script for Research Code Automation Tool

set -e

# Default values
MODE="api"
HOST="0.0.0.0"
PORT=8000
DEBUG=0

# Function to print usage
function print_usage {
    echo "Usage: ./run.sh [OPTIONS]"
    echo
    echo "Options:"
    echo "  --api              Run in API server mode (default)"
    echo "  --cli              Run in command-line interface mode"
    echo "  --gui              Run in graphical user interface mode"
    echo "  --host HOST        Specify host for API server (default: 0.0.0.0)"
    echo "  --port PORT        Specify port for API server (default: 8000)"
    echo "  --debug            Enable debug mode"
    echo "  --setup            Install dependencies and set up environment"
    echo "  --docker           Run in Docker container"
    echo "  --help             Show this help message"
    echo
    echo "Examples:"
    echo "  ./run.sh --api --port 8080          # Run API server on port 8080"
    echo "  ./run.sh --cli                      # Run CLI mode"
    echo "  ./run.sh --gui                      # Run GUI mode"
    echo "  ./run.sh --setup                    # Install dependencies"
    echo "  ./run.sh --docker --api             # Run API server in Docker"
}

# Function to check dependencies
function check_dependencies {
    echo "Checking dependencies..."
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        echo "Error: Python 3 is required but not installed."
        exit 1
    fi
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        echo "Error: pip3 is required but not installed."
        exit 1
    fi
    
    # Check if virtual environment exists
    if [ ! -d "venv" ]; then
        echo "Virtual environment not found. Creating one..."
        python3 -m venv venv
    fi
    
    echo "All dependencies checked."
}

# Function to setup environment
function setup_environment {
    echo "Setting up environment..."
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Install dependencies
    echo "Installing dependencies..."
    pip install -r requirements.txt
    
    # Check if .env file exists
    if [ ! -f ".env" ]; then
        echo "Creating .env file from .env.example..."
        cp .env.example .env
        echo ".env file created. Please edit it with your configuration."
    fi
    
    # Create necessary directories
    mkdir -p data downloads cache
    
    echo "Environment setup complete."
}

# Function to run Docker
function run_docker {
    echo "Running in Docker mode..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is required but not installed."
        exit 1
    fi
    
    # Check if docker-compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo "Error: docker-compose is required but not installed."
        exit 1
    fi
    
    # Build and run with docker-compose
    docker-compose up --build -d
    
    echo "Docker containers started."
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --api)
            MODE="api"
            shift
            ;;
        --cli)
            MODE="cli"
            shift
            ;;
        --gui)
            MODE="gui"
            shift
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        --port)
            PORT=$2
            shift 2
            ;;
        --debug)
            DEBUG=1
            shift
            ;;
        --setup)
            check_dependencies
            setup_environment
            exit 0
            ;;
        --docker)
            run_docker
            exit 0
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Check if we're in a virtual environment
if [ -z "$VIRTUAL_ENV" ]; then
    echo "Activating virtual environment..."
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    else
        echo "Virtual environment not found. Run with --setup first."
        exit 1
    fi
fi

# Run the application
PYTHON_CMD="python -m research_code_automation.main"

if [ $DEBUG -eq 1 ]; then
    export LOG_LEVEL=DEBUG
fi

if [ "$MODE" == "api" ]; then
    echo "Starting API server on $HOST:$PORT..."
    $PYTHON_CMD --api --host $HOST --port $PORT
elif [ "$MODE" == "cli" ]; then
    echo "Starting command-line interface..."
    $PYTHON_CMD --cli "$@"
elif [ "$MODE" == "gui" ]; then
    echo "Starting graphical user interface..."
    $PYTHON_CMD --gui
fi 