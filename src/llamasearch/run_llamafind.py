#!/usr/bin/env python3
"""
Run LlamaFind Web Server.
This script provides a convenient way to start the LlamaFind web server.
"""

import argparse
import importlib.util
import logging
import os
import subprocess
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    filename="llamafind_web.log",
)
logger = logging.getLogger("llamafind_web")


def check_dependencies():
    """Check if all required dependencies are installed."""
    required_packages = ["fastapi", "uvicorn", "jinja2", "aiofiles"]
    missing_packages = []

    for package in required_packages:
        if importlib.util.find_spec(package) is None:
            missing_packages.append(package)

    if missing_packages:
        logger.error(f"Missing required dependencies: {', '.join(missing_packages)}")
        print(f"Error: Missing required dependencies: {', '.join(missing_packages)}")
        print(
            'Please install them with: pip install -e ".[web]" or pip install -e ".[all]"'
        )
        return False

    return True


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="LlamaFind Web Server",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    # Add arguments
    parser.add_argument("--host", default="127.0.0.1", help="Host to bind to")
    parser.add_argument("-p", "--port", type=int, default=8000, help="Port to bind to")
    parser.add_argument(
        "--reload", action="store_true", help="Enable auto-reload for development"
    )
    parser.add_argument(
        "-c",
        "--config",
        default="config/llamafind.toml",
        help="Configuration file path",
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable verbose logging"
    )
    parser.add_argument(
        "--no-mlx", action="store_true", help="Disable MLX acceleration"
    )

    args = parser.parse_args()

    # Configure logging level
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Check dependencies
    if not check_dependencies():
        return 1

    # Set environment variables
    os.environ["LLAMAFIND_CONFIG"] = args.config
    if args.no_mlx:
        os.environ["LLAMAFIND_NO_MLX"] = "1"

    try:
        # Import the API module
        try:
            from llamafind.api import run_api_server
        except ImportError as e:
            logger.error(f"Failed to import LlamaFind modules: {e}")
            logger.error(
                "Make sure you're running this script from the LlamaFind project directory"
            )
            print(f"Error: Failed to import LlamaFind modules: {e}")
            print(
                "Make sure you're running this script from the LlamaFind project directory"
            )
            return 1

        # Run the web server
        print(f"Starting LlamaFind web server on http://{args.host}:{args.port}")
        print("Press Ctrl+C to stop the server")

        # Run the API server
        run_api_server(host=args.host, port=args.port, reload=args.reload)

        return 0

    except KeyboardInterrupt:
        print("\nWeb server stopped by user")
        return 0
    except Exception as e:
        logger.error(f"Error running web server: {e}")
        print(f"Error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
