#!/usr/bin/env python3
"""
Launcher script for LlamaSearchAI

This script provides a convenient way to start the LlamaSearchAI API server
or run commands directly from the command line.
"""

import argparse
import logging
import os
import sys

def setup_environment():
    """Set up the environment for running LlamaSearchAI."""
    # Add the current directory to the Python path
    current_dir = os.path.dirname(os.path.abspath(__file__))
    if current_dir not in sys.path:
        sys.path.insert(0, current_dir)
    
    # Set up logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout)
        ]
    )

def main():
    """Main entry point for the launcher script."""
    setup_environment()
    
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="LlamaSearchAI Launcher")
    parser.add_argument("--host", default="127.0.0.1", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8080, help="Port to bind to")
    parser.add_argument("--reload", action="store_true", help="Enable auto-reload for development")
    parser.add_argument("--log-level", choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"],
                        default="INFO", help="Logging level")
    
    args = parser.parse_args()
    
    # Set logging level
    logging.getLogger().setLevel(getattr(logging, args.log_level))
    
    try:
        # Import the server module and run the server
        from llamafind_ultra.server.app import run_server
        
        print(f"Starting LlamaSearchAI server at http://{args.host}:{args.port}")
        run_server(host=args.host, port=args.port, reload=args.reload)
        
    except ImportError as e:
        print(f"Error: Failed to import LlamaSearchAI modules. {e}")
        print("Make sure LlamaSearchAI is properly installed or that you're running from the correct directory.")
        return 1
    except KeyboardInterrupt:
        print("\nServer stopped by user.")
        return 0
    except Exception as e:
        print(f"Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main()) 