#!/usr/bin/env python3
"""
LlamaFind Test Script.
This script tests all search engines and features of LlamaFind.
"""

import argparse
import asyncio
import importlib.util
import json
import logging
import os
import sys
import time
from datetime import datetime
from typing import Any, Dict, List, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    filename="llamafind_test.log",
)
logger = logging.getLogger("llamafind_test")

# Import MLX compatibility module
from llamafind.mlx_compat import is_mlx_available, should_use_mlx

HAS_MLX = is_mlx_available()

# Try to import LlamaFind modules
try:
    from llamafind.data_models import SearchResult
    from llamafind.search_engines import (
        get_available_engines,
        get_engine,
        get_travel_engines,
    )
    from llamafind.utils.query_expander import QueryExpander
    from llamafind.utils.result_ranker import get_ranker
except ImportError as e:
    logger.error(f"Failed to import LlamaFind modules: {e}")
    logger.error(
        "Make sure you're running this script from the LlamaFind project directory"
    )
    sys.exit(1)


class LlamaFindTester:
    """
    Test runner for LlamaFind.
    """

    def __init__(self, use_mlx: bool = True):
        """
        Initialize the tester.

        Args:
            use_mlx: Whether to use MLX acceleration for ranking and query expansion.
                     If MLX is not available, the fallback ranker will be used regardless.
        """
        self.use_mlx = use_mlx and HAS_MLX
        self.results = {}
        self.errors = []

        # Set MLX environment variable
        if not self.use_mlx:
            os.environ["LLAMAFIND_NO_MLX"] = "1"
            logger.warning("MLX is not available, will use fallback ranker")

        # Initialize query expander
        self.query_expander = QueryExpander(mlx_enabled=self.use_mlx)

        # Get available engines
        self.available_engines = get_available_engines()
        self.travel_engines = get_travel_engines()

        logger.info("Starting LlamaFind tests...")
        logger.info(f"MLX enabled: {self.use_mlx}")

    async def test_web_search_engines(self):
        """Test web search engines."""
        logger.info("Testing web search engines...")

        # Test queries for web search
        test_queries = {
            "google": [
                "machine learning frameworks",
                "climate change solutions",
                "best programming languages 2023",
            ],
            "duckduckgo": [
                "machine learning frameworks",
                "climate change solutions",
                "best programming languages 2023",
            ],
            "bing": [
                "machine learning frameworks",
                "climate change solutions",
                "best programming languages 2023",
            ],
        }

        # Test each engine
        for engine_name, queries in test_queries.items():
            if engine_name not in self.available_engines:
                logger.warning(f"Engine {engine_name} not available, skipping")
                continue

            logger.info(f"Testing {engine_name} engine...")

            try:
                # Initialize engine
                engine = get_engine(engine_name)

                # Initialize results dictionary for this engine
                self.results[engine_name] = {}

                # Test each query
                for query in queries:
                    try:
                        logger.info(f"  Searching for: '{query}'")

                        # Measure search time
                        start_time = time.time()
                        results = await engine.search(query, num_results=10)
                        elapsed_time = time.time() - start_time

                        # Check if results have MLX scores
                        has_mlx_scores = all(
                            result.rank is not None for result in results if result
                        )

                        # Store results
                        self.results[engine_name][query] = {
                            "count": len(results),
                            "time": elapsed_time,
                            "has_mlx_scores": has_mlx_scores,
                            "first_result": results[0].dict() if results else None,
                        }

                        logger.info(
                            f"  Found {len(results)} results in {elapsed_time:.2f}s"
                        )
                        logger.info(f"  Results have MLX scores: {has_mlx_scores}")
                    except Exception as e:
                        logger.error(
                            f"Error testing {engine_name} with query '{query}': {e}"
                        )
                        self.errors.append(f"{engine_name}: {e}")

                logger.info(f"Completed testing {engine_name} engine")
            except Exception as e:
                logger.error(f"Error initializing {engine_name} engine: {e}")
                self.errors.append(f"{engine_name}: {e}")

    async def test_flight_search(self):
        """Test flight search engine."""
        logger.info("Testing flight search engine...")

        engine_name = "flights"
        if engine_name not in self.travel_engines:
            logger.warning(f"Engine {engine_name} not available, skipping")
            return

        # Test queries for flight search
        test_queries = [
            "flights from NYC to LAX on 2023-12-15",
            "flights from SFO to LHR on 2023-11-20",
            "flights from Chicago to Miami on 2023-10-30",
        ]

        try:
            # Initialize engine
            engine = get_engine(engine_name)

            # Initialize results dictionary for this engine
            self.results[engine_name] = {}

            # Test each query
            for query in test_queries:
                try:
                    logger.info(f"  Searching for: '{query}'")

                    # Measure search time
                    start_time = time.time()
                    results = await engine.search(query, num_results=10)
                    elapsed_time = time.time() - start_time

                    # Check if results have MLX scores
                    has_mlx_scores = all(
                        result.rank is not None for result in results if result
                    )

                    # Store results
                    self.results[engine_name][query] = {
                        "count": len(results),
                        "time": elapsed_time,
                        "has_mlx_scores": has_mlx_scores,
                        "first_result": results[0].dict() if results else None,
                    }

                    logger.info(
                        f"  Found {len(results)} results in {elapsed_time:.2f}s"
                    )
                    logger.info(f"  Results have MLX scores: {has_mlx_scores}")
                except Exception as e:
                    logger.error(
                        f"Error testing {engine_name} with query '{query}': {e}"
                    )
                    self.errors.append(f"{engine_name}: {e}")

            logger.info(f"Completed testing flight search engine")
        except Exception as e:
            logger.error(f"Error initializing {engine_name} engine: {e}")
            self.errors.append(f"{engine_name}: {e}")

    async def test_hotel_search(self):
        """Test hotel search engine."""
        logger.info("Testing hotel search engine...")

        engine_name = "hotels"
        if engine_name not in self.travel_engines:
            logger.warning(f"Engine {engine_name} not available, skipping")
            return

        # Test queries for hotel search
        test_queries = [
            "hotels in New York from 2023-12-15 to 2023-12-20",
            "hotels in Paris from 2023-11-10 to 2023-11-15",
            "hotels in Tokyo from 2023-10-25 to 2023-10-30",
        ]

        try:
            # Initialize engine
            engine = get_engine(engine_name)

            # Initialize results dictionary for this engine
            self.results[engine_name] = {}

            # Test each query
            for query in test_queries:
                try:
                    logger.info(f"  Searching for: '{query}'")

                    # Measure search time
                    start_time = time.time()
                    results = await engine.search(query, num_results=10)
                    elapsed_time = time.time() - start_time

                    # Check if results have MLX scores
                    has_mlx_scores = all(
                        result.rank is not None for result in results if result
                    )

                    # Store results
                    self.results[engine_name][query] = {
                        "count": len(results),
                        "time": elapsed_time,
                        "has_mlx_scores": has_mlx_scores,
                        "first_result": results[0].dict() if results else None,
                    }

                    logger.info(
                        f"  Found {len(results)} results in {elapsed_time:.2f}s"
                    )
                    logger.info(f"  Results have MLX scores: {has_mlx_scores}")
                except Exception as e:
                    logger.error(
                        f"Error testing {engine_name} with query '{query}': {e}"
                    )
                    self.errors.append(f"{engine_name}: {e}")

            logger.info(f"Completed testing hotel search engine")
        except Exception as e:
            logger.error(f"Error initializing {engine_name} engine: {e}")
            self.errors.append(f"{engine_name}: {e}")

    async def test_package_search(self):
        """Test package search engine."""
        logger.info("Testing package search engine...")

        engine_name = "packages"
        if engine_name not in self.travel_engines:
            logger.warning(f"Engine {engine_name} not available, skipping")
            return

        # Test queries for package search
        test_queries = [
            "vacation in Hawaii from 2023-12-15 to 2023-12-22",
            "vacation in Paris from 2023-11-10 to 2023-11-15",
            "vacation in Cancun from 2023-10-25 to 2023-10-30",
        ]

        try:
            # Initialize engine
            engine = get_engine(engine_name)

            # Initialize results dictionary for this engine
            self.results[engine_name] = {}

            # Test each query
            for query in test_queries:
                try:
                    logger.info(f"  Searching for: '{query}'")

                    # Measure search time
                    start_time = time.time()
                    results = await engine.search(query, num_results=10)
                    elapsed_time = time.time() - start_time

                    # Check if results have MLX scores
                    has_mlx_scores = all(
                        result.rank is not None for result in results if result
                    )

                    # Store results
                    self.results[engine_name][query] = {
                        "count": len(results),
                        "time": elapsed_time,
                        "has_mlx_scores": has_mlx_scores,
                        "first_result": results[0].dict() if results else None,
                    }

                    logger.info(
                        f"  Found {len(results)} results in {elapsed_time:.2f}s"
                    )
                    logger.info(f"  Results have MLX scores: {has_mlx_scores}")
                except Exception as e:
                    logger.error(
                        f"Error testing {engine_name} with query '{query}': {e}"
                    )
                    self.errors.append(f"{engine_name}: {e}")
                    logger.error(f"Error testing package search engine: {e}")

            logger.info(f"Completed testing package search engine")
        except Exception as e:
            logger.error(f"Error initializing {engine_name} engine: {e}")
            self.errors.append(f"{engine_name}: {e}")

    async def test_hybrid_search(self):
        """Test hybrid search engine."""
        logger.info("Testing hybrid search engine...")

        engine_name = "hybrid"
        if engine_name not in self.available_engines:
            logger.warning(f"Engine {engine_name} not available, skipping")
            return

        # Test queries for hybrid search
        test_queries = [
            "artificial intelligence ethics",
            "renewable energy technologies",
            "quantum computing applications",
        ]

        try:
            # Initialize engine
            engine = get_engine(engine_name)

            # Initialize results dictionary for this engine
            self.results[engine_name] = {}

            # Test each query
            for query in test_queries:
                try:
                    logger.info(f"  Searching for: '{query}'")

                    # Measure search time
                    start_time = time.time()
                    results = await engine.search(query, num_results=10)
                    elapsed_time = time.time() - start_time

                    # Check if results have MLX scores
                    has_mlx_scores = all(
                        result.rank is not None for result in results if result
                    )

                    # Count results by source
                    sources = {}
                    for result in results:
                        source = (
                            result.source
                            if hasattr(result, "source") and result.source
                            else "unknown"
                        )
                        sources[source] = sources.get(source, 0) + 1

                    # Store results
                    self.results[engine_name][query] = {
                        "count": len(results),
                        "time": elapsed_time,
                        "has_mlx_scores": has_mlx_scores,
                        "sources": sources,
                        "first_result": results[0].dict() if results else None,
                    }

                    logger.info(
                        f"  Found {len(results)} results in {elapsed_time:.2f}s"
                    )
                    logger.info(f"  Results have MLX scores: {has_mlx_scores}")
                    logger.info(f"  Source distribution: {sources}")
                except Exception as e:
                    logger.error(
                        f"Error testing {engine_name} with query '{query}': {e}"
                    )
                    self.errors.append(f"{engine_name}: {e}")

            logger.info(f"Completed testing hybrid search engine")
        except Exception as e:
            logger.error(f"Error initializing {engine_name} engine: {e}")
            self.errors.append(f"{engine_name}: {e}")

    async def run_all_tests(self):
        """Run all tests."""
        # Test web search engines
        await self.test_web_search_engines()

        # Test travel search engines
        await self.test_flight_search()
        await self.test_hotel_search()
        await self.test_package_search()

        # Test hybrid search engine
        await self.test_hybrid_search()

        # Save results
        self.save_results()

        # Print summary
        self.print_summary()

    def save_results(self):
        """Save test results to a file."""
        # Create results dictionary
        results_data = {
            "timestamp": time.time(),
            "mlx_enabled": self.use_mlx,
            "mlx_available": HAS_MLX,
            "results": self.results,
            "errors": self.errors,
        }

        # Save to file
        with open("llamafind_test_results.json", "w") as f:
            json.dump(results_data, f, indent=2)

        logger.info("Test results saved to llamafind_test_results.json")

    def print_summary(self):
        """Print a summary of the test results."""
        print("\n" + "=" * 80)
        print("LlamaFind Test Results")
        print("=" * 80)

        # Print MLX status
        print(f"MLX Acceleration: {'Enabled' if self.use_mlx else 'Disabled'}")
        print(f"MLX Available: {'Yes' if HAS_MLX else 'No'}")

        # Print engine results
        print("\nSearch Engine Results:")
        print("-" * 80)

        for engine_name, queries in self.results.items():
            print(f"\n{engine_name.upper()} Engine:")

            for query, data in queries.items():
                print(f"  • Query: '{query}'")
                print(f"    - Results: {data['count']}")
                print(f"    - Time: {data['time']:.2f}s")
                print(f"    - MLX Scores: {'Yes' if data['has_mlx_scores'] else 'No'}")

                if "sources" in data:
                    print(f"    - Sources: {data['sources']}")

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


async def run_web_server():
    """Run the web server."""
    try:
        # Import the API server module
        # Create a new process to run the web server
        import subprocess

        from llamafind.api import run_api_server

        # Run the web server in a new process
        process = subprocess.Popen(
            [
                sys.executable,
                "run_llamafind.py",
                "--host",
                "127.0.0.1",
                "--port",
                "8000",
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        # Wait for the web server to start
        print("Starting web server...")
        await asyncio.sleep(2)

        print(f"Web server running at http://127.0.0.1:8000")
        print(f"Search UI available at http://127.0.0.1:8000/search")
        print(f"API documentation available at http://127.0.0.1:8000/docs")
        print("Press Ctrl+C to stop")

        # Keep the web server running
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        print("\nStopping web server...")
    except Exception as e:
        print(f"Error running web server: {e}")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="LlamaFind Test Script")
    parser.add_argument(
        "--no-mlx", action="store_true", help="Disable MLX acceleration"
    )
    parser.add_argument(
        "--web", action="store_true", help="Start web server after tests"
    )
    args = parser.parse_args()

    # Run tests
    tester = LlamaFindTester(use_mlx=not args.no_mlx)
    asyncio.run(tester.run_all_tests())

    # Start web server if requested
    if args.web:
        try:
            asyncio.run(run_web_server())
        except KeyboardInterrupt:
            print("\nWeb server stopped by user")

    return 0


if __name__ == "__main__":
    sys.exit(main())
