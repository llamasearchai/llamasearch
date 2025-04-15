"""
Main entry point for Research Code Automation Tool.

This module provides the main entry point for the tool,
which can be run in API, CLI, or GUI mode.
"""

import argparse
import asyncio
import logging
import os
import sys

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from research_code_automation.api.routes import router as api_router
from research_code_automation.config import settings
from research_code_automation.db.models import Base
from research_code_automation.db.session import engine

# Configure rich logging
try:
    from rich.logging import RichHandler

    logging.basicConfig(
        level=getattr(logging, settings.log_level.upper()),
        format="%(message)s",
        datefmt="[%X]",
        handlers=[RichHandler(rich_tracebacks=True)],
    )
except ImportError:
    # Fallback to standard logging if rich is not available
    logging.basicConfig(
        level=getattr(logging, settings.log_level.upper()),
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )

logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="Research Code Automation API",
    description="API for research automation, web scraping, and code processing",
    version="0.1.0",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router
app.include_router(api_router, prefix="/api/v1")


@app.on_event("startup")
async def startup():
    """Initialize the application on startup."""
    # Create tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    logger.info("Database tables created")


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "name": "Research Code Automation Tool",
        "version": "0.1.0",
        "description": "A tool for research automation, web scraping, and code processing",
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "ok"}


def run_api(host: str = "0.0.0.0", port: int = 8000):
    """Run the FastAPI server."""
    uvicorn.run("research_code_automation.main:app", host=host, port=port, reload=True)


def run_cli():
    """Run the command-line interface."""
    # Import here to avoid circular imports
    from research_code_automation.cli.commands import cli

    cli()


def run_gui():
    """Run the graphical user interface."""
    # Import here to avoid circular imports
    from research_code_automation.gui.gui_app import run_gui_app

    run_gui_app()


def main():
    """Main entry point for the application."""
    parser = argparse.ArgumentParser(description="Research Code Automation Tool")
    parser.add_argument("--api", action="store_true", help="Run as API server")
    parser.add_argument(
        "--cli", action="store_true", help="Run as command-line interface"
    )
    parser.add_argument(
        "--gui", action="store_true", help="Run as graphical user interface"
    )
    parser.add_argument(
        "--host", default="0.0.0.0", help="Host for API server (default: 0.0.0.0)"
    )
    parser.add_argument(
        "--port", type=int, default=8000, help="Port for API server (default: 8000)"
    )

    args = parser.parse_args()

    # Determine which mode to run in
    if args.api:
        logger.info(f"Starting API server on {args.host}:{args.port}")
        run_api(args.host, args.port)
    elif args.cli:
        logger.info("Starting command-line interface")
        run_cli()
    elif args.gui:
        logger.info("Starting graphical user interface")
        run_gui()
    else:
        # Default to API mode
        logger.info(
            f"No mode specified, defaulting to API server on {args.host}:{args.port}"
        )
        run_api(args.host, args.port)


if __name__ == "__main__":
    main()
