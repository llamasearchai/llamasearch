#!/usr/bin/env python3
"""
LlamaSearch CLI - Command Line Interface for LlamaSearch
"""

import argparse
import json
import os
import sys
from typing import Dict, List, Optional, Union

from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from llamasearch import __version__
from llamasearch.config import SearchConfig
from llamasearch.search import SearchClient

console = Console()


def search_command(args: argparse.Namespace) -> None:
    """Execute search command"""
    try:
        # Configure the search client
        client = SearchClient(
            google_api_key=os.environ.get("GOOGLE_API_KEY"),
            brave_api_key=os.environ.get("BRAVE_API_KEY"),
            perplexity_api_key=os.environ.get("PERPLEXITY_API_KEY"),
        )

        # Execute the search
        results = client.search(
            query=args.query,
            provider=args.provider,
            max_results=args.max_results,
            filter_domains=args.include_domains,
            exclude_domains=args.exclude_domains,
        )

        # Format and display results
        if args.format == "json":
            print(json.dumps(results, indent=2))
        else:  # Default to pretty format
            table = Table(title=f"Search Results for '{args.query}'")
            table.add_column("Title", style="cyan", no_wrap=False)
            table.add_column("URL", style="blue", no_wrap=False)
            table.add_column("Snippet", style="green", no_wrap=False)

            for result in results:
                table.add_row(
                    result.get("title", "No title"),
                    result.get("url", "No URL"),
                    result.get("snippet", "No snippet")[:100] + "...",
                )

            console.print(table)

    except Exception as e:
        console.print(f"[bold red]Error:[/bold red] {str(e)}")
        sys.exit(1)


def rag_command(args: argparse.Namespace) -> None:
    """Execute RAG command"""
    try:
        # Configure the search client
        client = SearchClient(
            google_api_key=os.environ.get("GOOGLE_API_KEY"),
            brave_api_key=os.environ.get("BRAVE_API_KEY"),
            perplexity_api_key=os.environ.get("PERPLEXITY_API_KEY"),
            openai_api_key=os.environ.get("OPENAI_API_KEY"),
        )

        # Execute the RAG request
        answer = client.generate_answer(
            question=args.question,
            context=args.context,
            search_provider=args.provider,
            max_tokens=args.max_tokens,
        )

        # Format and display results
        if args.format == "json":
            print(json.dumps(answer, indent=2))
        else:  # Default to pretty format
            panel = Panel(
                answer.get("text", "No answer generated"),
                title=f"Answer to '{args.question}'",
                border_style="green",
                padding=(1, 2),
            )
            console.print(panel)

            if args.verbose:
                console.print("\n[bold]Sources:[/bold]")
                for i, source in enumerate(answer.get("sources", []), 1):
                    console.print(f"{i}. {source.get('title')}: {source.get('url')}")

    except Exception as e:
        console.print(f"[bold red]Error:[/bold red] {str(e)}")
        sys.exit(1)


def version_command(_: argparse.Namespace) -> None:
    """Show version information"""
    console.print(f"LlamaSearch CLI v{__version__}")


def main() -> None:
    """Main entry point for the CLI"""
    parser = argparse.ArgumentParser(
        description="LlamaSearch - Advanced AI-powered search and RAG platform"
    )
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # Version command
    version_parser = subparsers.add_parser("version", help="Show version information")
    version_parser.set_defaults(func=version_command)

    # Search command
    search_parser = subparsers.add_parser("search", help="Execute a search query")
    search_parser.add_argument("query", type=str, help="Search query")
    search_parser.add_argument(
        "--provider",
        "-p",
        type=str,
        default="google",
        choices=["google", "brave", "perplexity", "all"],
        help="Search provider to use (default: google)",
    )
    search_parser.add_argument(
        "--max-results",
        "-m",
        type=int,
        default=10,
        help="Maximum number of results to return (default: 10)",
    )
    search_parser.add_argument(
        "--include-domains",
        "-i",
        type=str,
        nargs="+",
        help="Only include results from these domains",
    )
    search_parser.add_argument(
        "--exclude-domains",
        "-e",
        type=str,
        nargs="+",
        help="Exclude results from these domains",
    )
    search_parser.add_argument(
        "--format",
        "-f",
        type=str,
        choices=["pretty", "json"],
        default="pretty",
        help="Output format (default: pretty)",
    )
    search_parser.set_defaults(func=search_command)

    # RAG command
    rag_parser = subparsers.add_parser(
        "rag", help="Generate an answer using RAG (Retrieval-Augmented Generation)"
    )
    rag_parser.add_argument("question", type=str, help="Question to answer")
    rag_parser.add_argument(
        "--context", "-c", type=str, help="Additional context for the question"
    )
    rag_parser.add_argument(
        "--provider",
        "-p",
        type=str,
        default="google",
        choices=["google", "brave", "perplexity", "all"],
        help="Search provider to use for retrieval (default: google)",
    )
    rag_parser.add_argument(
        "--max-tokens",
        "-t",
        type=int,
        default=500,
        help="Maximum tokens for the generated answer (default: 500)",
    )
    rag_parser.add_argument(
        "--format",
        "-f",
        type=str,
        choices=["pretty", "json"],
        default="pretty",
        help="Output format (default: pretty)",
    )
    rag_parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Show detailed information including sources",
    )
    rag_parser.set_defaults(func=rag_command)

    # Parse arguments
    args = parser.parse_args()

    # Execute command or show help
    if hasattr(args, "func"):
        args.func(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
