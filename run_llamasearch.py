#!/usr/bin/env python3
"""
LlamaSearchAI Runner

This script provides a convenient way to start the LlamaSearchAI web server
and all its components, including Prometheus monitoring if enabled.
"""

import os
import sys
import argparse
import logging
import subprocess
import asyncio
import signal
import time
from pathlib import Path
import importlib.util
from typing import List, Dict, Any, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("llamasearch.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("llamasearch")

def check_dependencies() -> bool:
    """Check if all required dependencies are installed."""
    required_packages = [
        "fastapi", "uvicorn", "jinja2", "aiofiles", 
        "openai", "anthropic", "prometheus_client"
    ]
    missing_packages = []
    
    for package in required_packages:
        if importlib.util.find_spec(package) is None:
            missing_packages.append(package)
    
    if missing_packages:
        logger.error(f"Missing required dependencies: {', '.join(missing_packages)}")
        print(f"Error: Missing required dependencies: {', '.join(missing_packages)}")
        print("Please install them with: pip install -r requirements.txt")
        return False
    
    return True

def load_env_file(env_file: str = ".env") -> None:
    """Load environment variables from .env file if it exists."""
    if not os.path.exists(env_file):
        logger.warning(f"{env_file} file not found. Using existing environment variables.")
        return
    
    logger.info(f"Loading environment variables from {env_file}")
    with open(env_file, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
                
            key, value = line.split("=", 1)
            os.environ[key.strip()] = value.strip()

def check_api_keys() -> Dict[str, bool]:
    """Check if required API keys are set in environment variables."""
    api_keys = {
        "Perplexity": "LLAMASEARCH_PERPLEXITY_API_KEY",
        "Tavily": "LLAMASEARCH_TAVILY_API_KEY",
        "Brave": "LLAMASEARCH_BRAVE_API_KEY",
        "VoyageAI": "LLAMASEARCH_VOYAGE_API_KEY",
        "Exa": "LLAMASEARCH_EXA_API_KEY",
        "Google": "GOOGLE_API_KEY",
        "Anthropic": "ANTHROPIC_API_KEY",
        "OpenAI": "OPENAI_API_KEY"
    }
    
    results = {}
    for name, env_var in api_keys.items():
        has_key = bool(os.environ.get(env_var))
        results[name] = has_key
        if has_key:
            logger.info(f"{name} API key found")
        else:
            logger.warning(f"{name} API key not found. Set {env_var} to use {name} features.")
    
    return results

async def start_server(host: str, port: int) -> None:
    """Start the FastAPI server."""
    try:
        # Import the API module
        try:
            from llamafind_ultra.server import app
            
            import uvicorn
            config = uvicorn.Config(
                app=app,
                host=host,
                port=port,
                reload=True,
                log_level="info"
            )
            server = uvicorn.Server(config)
            await server.serve()
            
        except ImportError as e:
            logger.error(f"Failed to import LlamaSearchAI modules: {e}")
            logger.error("Make sure you're running this script from the LlamaSearchAI project directory")
            print(f"Error: Failed to import LlamaSearchAI modules: {e}")
            print("Make sure you're running this script from the LlamaSearchAI project directory")
            return
        
    except Exception as e:
        logger.error(f"Error running web server: {e}")
        print(f"Error: {e}")

def start_monitoring():
    """Start the monitoring stack using Docker Compose if metrics are enabled."""
    if os.environ.get("LLAMASEARCH_METRICS_ENABLED", "").lower() == "true":
        logger.info("Starting monitoring stack...")
        try:
            subprocess.Popen(
                ["docker-compose", "-f", "monitoring/docker-compose.yml", "up", "-d"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            logger.info("Monitoring stack started")
        except Exception as e:
            logger.error(f"Failed to start monitoring stack: {e}")
    else:
        logger.info("Metrics disabled. Set LLAMASEARCH_METRICS_ENABLED=true to enable monitoring.")

def signal_handler(sig, frame):
    """Handle Ctrl+C gracefully."""
    print("\nShutting down LlamaSearchAI...")
    # Stop monitoring if it was started
    if os.environ.get("LLAMASEARCH_METRICS_ENABLED", "").lower() == "true":
        try:
            subprocess.run(
                ["docker-compose", "-f", "monitoring/docker-compose.yml", "down"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            logger.info("Monitoring stack stopped")
        except Exception as e:
            logger.error(f"Failed to stop monitoring stack: {e}")
    
    sys.exit(0)

async def main() -> int:
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="LlamaSearchAI Server",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    # Add arguments
    parser.add_argument("--host", default="127.0.0.1", help="Host to bind to")
    parser.add_argument("-p", "--port", type=int, default=8000, help="Port to bind to")
    parser.add_argument("-e", "--env", default=".env", help="Path to .env file")
    parser.add_argument("-c", "--config", default="config/llamafind.toml", help="Configuration file path")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose logging")
    parser.add_argument("--no-mlx", action="store_true", help="Disable MLX acceleration")
    parser.add_argument("--no-monitoring", action="store_true", help="Disable Prometheus monitoring")
    
    args = parser.parse_args()
    
    # Configure logging level
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Load environment variables
    load_env_file(args.env)
    
    # Check dependencies
    if not check_dependencies():
        return 1
    
    # Check API keys
    api_keys = check_api_keys()
    
    # Set environment variables
    os.environ["LLAMASEARCH_CONFIG"] = args.config
    if args.no_mlx:
        os.environ["LLAMASEARCH_NO_MLX"] = "1"
    if args.no_monitoring:
        os.environ["LLAMASEARCH_METRICS_ENABLED"] = "false"
    
    # Register signal handler for Ctrl+C
    signal.signal(signal.SIGINT, signal_handler)
    
    # Start monitoring if enabled
    if not args.no_monitoring and os.environ.get("LLAMASEARCH_METRICS_ENABLED", "").lower() == "true":
        start_monitoring()
    
    try:
        # Start the web server
        print(f"Starting LlamaSearchAI web server on http://{args.host}:{args.port}")
        print("Press Ctrl+C to stop the server")
        
        await start_server(host=args.host, port=args.port)
        
        return 0
        
    except KeyboardInterrupt:
        print("\nWeb server stopped by user")
        return 0
    except Exception as e:
        logger.error(f"Error running web server: {e}")
        print(f"Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(asyncio.run(main())) 