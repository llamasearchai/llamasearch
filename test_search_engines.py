#!/usr/bin/env python3
"""
LlamaFind Search Engines Test Script.
Tests the functionality of different search engines in LlamaFind.
"""

import argparse
import asyncio
import json
import logging
import time
from datetime import datetime
from typing import Any, Dict, List, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("engine_test")

# Try to import LlamaFind modules
try:
    from llamafind.data_models import SearchResult
    from llamafind.search_engines import get_available_engines, get_engine
    from llamafind.utils.mlx_utils import is_mlx_available, log_mlx_status
except ImportError as e:
    logger.error(f"Failed to import LlamaFind modules: {e}")
    logger.error(
        "Make sure you're running this script from the LlamaFind project directory"
    )
    import sys

    sys.exit(1)


class EngineTestRunner:
    """
    Test runner for LlamaFind search engines.
    """

    def __init__(
        self, engines: List[str] = None, use_mlx: bool = True, verbose: bool = False
    ):
        """
        Initialize the test runner.

        Args:
            engines: List of search engines to test. If None, all available engines will be tested.
            use_mlx: Whether to use MLX acceleration
            verbose: Whether to print verbose output
        """
        self.use_mlx = use_mlx
        self.verbose = verbose
        self.results = {}
        self.errors = []

        # Get available engines
        self.available_engines = get_available_engines()

        # Filter engines to test
        if engines:
            self.engines_to_test = [
                engine for engine in engines if engine in self.available_engines
            ]
            if not self.engines_to_test:
                logger.warning(
                    f"None of the specified engines {engines} are available. Using all available engines."
                )
                self.engines_to_test = self.available_engines
        else:
            self.engines_to_test = self.available_engines

        # Log MLX status
        log_mlx_status()

        logger.info(f"Testing search engines: {', '.join(self.engines_to_test)}")
        logger.info(f"MLX enabled: {self.use_mlx}")

    async def test_engine(
        self, engine_name: str, queries: List[str], num_results: int = 5
    ):
        """
        Test a specific search engine with multiple queries.

        Args:
            engine_name: Name of the search engine to test
            queries: List of queries to test
            num_results: Number of results to request per query
        """
        logger.info(f"Testing {engine_name} engine...")

        # Initialize engine-specific results
        self.results[engine_name] = {}

        # Configure search engine
        engine_config = {
            "use_mlx": self.use_mlx,
            "use_cache": False,  # Disable cache for testing
        }

        # Get search engine
        try:
            engine = get_engine(engine_name, engine_config)
            if not engine:
                error_msg = f"Could not initialize {engine_name} engine"
                logger.error(error_msg)
                self.errors.append(error_msg)
                return
        except Exception as e:
            error_msg = f"Error initializing {engine_name} engine: {e}"
            logger.error(error_msg)
            self.errors.append(error_msg)
            return

        # Test each query
        for query in queries:
            try:
                logger.info(f"Searching {engine_name} for '{query}'...")

                # Perform search
                start_time = time.time()
                results = await engine.search(query, num_results=num_results)
                elapsed_time = time.time() - start_time

                # Check if results has MLX scores
                has_mlx_scores = any(result.score is not None for result in results)

                # Collect sources (if available)
                sources = {}
                for result in results:
                    source = result.source
                    if source:
                        sources[source] = sources.get(source, 0) + 1

                # Store results
                self.results[engine_name][query] = {
                    "count": len(results),
                    "time": elapsed_time,
                    "has_mlx_scores": has_mlx_scores,
                    "sources": sources if sources else None,
                }

                # Print results if verbose
                if self.verbose:
                    print(f"\nResults for '{query}' using {engine_name} engine:")
                    for i, result in enumerate(results[:num_results], 1):
                        print(f"\n{i}. {result.title}")
                        print(f"   URL: {result.url}")
                        print(
                            f"   Snippet: {result.snippet[:100]}..."
                            if result.snippet
                            else "   No snippet"
                        )
                        if result.rank is not None:
                            print(f"   Rank: {result.rank:.4f}")
                        if result.score is not None:
                            print(f"   Score: {result.score:.4f}")

                logger.info(
                    f"Found {len(results)} results for '{query}' in {elapsed_time:.2f}s"
                )

            except Exception as e:
                error_msg = f"Error searching {engine_name} for '{query}': {e}"
                logger.error(error_msg)
                self.errors.append(error_msg)
                self.results[engine_name][query] = {
                    "count": 0,
                    "time": 0,
                    "error": str(e),
                }

    async def run_tests(self):
        """Run all tests."""
        # Test queries for different engines
        test_queries = {
            "google": [
                "python programming",
                "machine learning frameworks",
                "climate change solutions",
            ],
            "duckduckgo": [
                "python programming",
                "machine learning frameworks",
                "climate change solutions",
            ],
            "bing": [
                "python programming",
                "machine learning frameworks",
                "climate change solutions",
            ],
            "hybrid": [
                "python programming",
                "machine learning frameworks",
                "climate change solutions",
            ],
            "flights": [
                "flights from NYC to LAX",
                "cheap flights to Europe",
                "business class to Tokyo",
            ],
            "hotels": [
                "hotels in Paris",
                "luxury resorts in Hawaii",
                "budget hotels in London",
            ],
            "packages": [
                "vacation packages to Caribbean",
                "all-inclusive Mexico resorts",
                "Europe tour packages",
            ],
        }

        # Run tests for each engine
        for engine_name in self.engines_to_test:
            # Get queries for this engine or use default
            queries = test_queries.get(
                engine_name,
                ["python programming", "machine learning", "climate change"],
            )
            await self.test_engine(engine_name, queries)

        # Save results
        self.save_results()

        # Print summary
        self.print_summary()

    def save_results(self):
        """Save test results to file."""
        # Prepare data for JSON serialization
        results_data = {
            "timestamp": datetime.now().isoformat(),
            "mlx_enabled": self.use_mlx,
            "mlx_available": is_mlx_available(),
            "engines_tested": self.engines_to_test,
            "results": self.results,
            "errors": self.errors,
        }

        # Save to file
        filename = (
            f"llamafind_engine_test_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        )
        with open(filename, "w") as f:
            json.dump(results_data, f, indent=2)

        logger.info(f"Test results saved to {filename}")

    def print_summary(self):
        """Print a summary of the test results."""
        print("\n" + "=" * 80)
        print("LlamaFind Search Engine Test Results")
        print("=" * 80)

        # Print MLX status
        print(f"MLX Acceleration: {'Enabled' if self.use_mlx else 'Disabled'}")
        print(f"MLX Available: {'Yes' if is_mlx_available() else 'No'}")

        # Print engine results
        print("\nSearch Engine Results:")
        print("-" * 80)

        for engine_name, queries in self.results.items():
            print(f"\n{engine_name.upper()} Engine:")

            for query, data in queries.items():
                print(f"  • Query: '{query}'")
                print(f"    - Results: {data.get('count', 0)}")
                print(f"    - Time: {data.get('time', 0):.2f}s")

                if "has_mlx_scores" in data:
                    print(
                        f"    - MLX Scores: {'Yes' if data['has_mlx_scores'] else 'No'}"
                    )

                if data.get("sources"):
                    sources_str = ", ".join(
                        [f"{src}({count})" for src, count in data["sources"].items()]
                    )
                    print(f"    - Sources: {sources_str}")

                if "error" in data:
                    print(f"    - Error: {data['error']}")

        # Print errors
        if self.errors:
            print("\nErrors:")
            print("-" * 80)

            for error in self.errors:
                print(f"  • {error}")

        print("\n" + "=" * 80)
        print(f"Total Engines Tested: {len(self.results)}")
        print(f"Total Errors: {len(self.errors)}")
        print("=" * 80)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="LlamaFind Search Engine Test")
    parser.add_argument("--engines", nargs="+", help="Search engines to test")
    parser.add_argument(
        "--no-mlx", action="store_true", help="Disable MLX acceleration"
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Print verbose output"
    )
    args = parser.parse_args()

    # Run tests
    test_runner = EngineTestRunner(
        engines=args.engines, use_mlx=not args.no_mlx, verbose=args.verbose
    )
    asyncio.run(test_runner.run_tests())

    return 0


if __name__ == "__main__":
    import sys

    sys.exit(main())
