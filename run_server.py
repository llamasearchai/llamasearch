#!/usr/bin/env python3
"""
Run the LlamaFind Ultra API server.

This script starts the LlamaFind Ultra API server with the specified host, port,
and debug settings.
"""

import argparse
import logging
import sys

from llamafind_ultra.config import setup_logging
from llamafind_ultra.server import run_server

# Set up logging
setup_logging()
logger = logging.getLogger(__name__)

def main():
    """
    Main entry point.
    """
    parser = argparse.ArgumentParser(
        description="Run the LlamaFind Ultra API server",
    )
    parser.add_argument(
        "--host",
        default="0.0.0.0",
        help="Host to bind to",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=5000,
        help="Port to bind to",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Run in debug mode",
    )
    
    args = parser.parse_args()
    
    logger.info(f"Starting LlamaFind Ultra API server on {args.host}:{args.port}")
    
    try:
        run_server(
            host=args.host,
            port=args.port,
            debug=args.debug,
        )
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Server error: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 