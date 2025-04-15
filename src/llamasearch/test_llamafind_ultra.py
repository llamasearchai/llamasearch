#!/usr/bin/env python3
"""
LlamaFind Ultra Test Script.

This script tests the functionality of LlamaFind Ultra, including the API server,
search capabilities, and agent system.
"""

import argparse
import asyncio
import json
import logging
import os
import sys
import time
from datetime import datetime
from typing import Any, Dict, List, Optional

import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("llamafind-ultra-test")


class LlamaFindUltraTester:
    """
    Test suite for LlamaFind Ultra.

    This class provides methods for testing various aspects of LlamaFind Ultra,
    including the API server, search capabilities, and agent system.
    """

    def __init__(self, base_url: str = "http://localhost:5000"):
        """
        Initialize the tester.

        Args:
            base_url: The base URL of the LlamaFind Ultra API server
        """
        self.base_url = base_url
        self.results = {
            "health_check": None,
            "agents_list": None,
            "chat_agent": None,
            "search_agent": None,
            "vector_search": None,
        }
        self.start_time = time.time()

        logger.info(f"Initializing LlamaFind Ultra tester with base URL: {base_url}")

    def test_health_check(self) -> Dict[str, Any]:
        """
        Test the health check endpoint.

        Returns:
            The response from the health check endpoint
        """
        logger.info("Testing health check endpoint...")

        try:
            response = requests.get(f"{self.base_url}/api/health")
            response.raise_for_status()
            result = response.json()

            logger.info(f"Health check successful: {result}")
            self.results["health_check"] = {
                "success": True,
                "data": result,
                "time": time.time() - self.start_time,
            }

            return result
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            self.results["health_check"] = {
                "success": False,
                "error": str(e),
                "time": time.time() - self.start_time,
            }

            return {"error": str(e)}

    def test_agents_list(self) -> List[Dict[str, Any]]:
        """
        Test the agents list endpoint.

        Returns:
            The list of available agents
        """
        logger.info("Testing agents list endpoint...")

        try:
            response = requests.get(f"{self.base_url}/api/agents")
            response.raise_for_status()
            result = response.json()

            logger.info(f"Found {len(result)} agents")
            for agent in result:
                logger.info(
                    f"  - {agent['type']}: {agent['name']} ({len(agent['capabilities'])} capabilities)"
                )

            self.results["agents_list"] = {
                "success": True,
                "data": result,
                "time": time.time() - self.start_time,
            }

            return result
        except Exception as e:
            logger.error(f"Agents list failed: {e}")
            self.results["agents_list"] = {
                "success": False,
                "error": str(e),
                "time": time.time() - self.start_time,
            }

            return []

    def test_chat_agent(self, message: str = "What time is it?") -> Dict[str, Any]:
        """
        Test the chat agent.

        Args:
            message: The message to send to the chat agent

        Returns:
            The response from the chat agent
        """
        logger.info(f"Testing chat agent with message: {message}")

        try:
            response = requests.post(
                f"{self.base_url}/api/agents/chat/message",
                json={"message": message},
            )
            response.raise_for_status()
            result = response.json()

            logger.info(f"Chat agent response: {result}")
            self.results["chat_agent"] = {
                "success": True,
                "data": result,
                "time": time.time() - self.start_time,
            }

            return result
        except Exception as e:
            logger.error(f"Chat agent failed: {e}")
            self.results["chat_agent"] = {
                "success": False,
                "error": str(e),
                "time": time.time() - self.start_time,
            }

            return {"error": str(e)}

    def test_search_agent(self, query: str = "LlamaFind Ultra") -> Dict[str, Any]:
        """
        Test the search agent.

        Args:
            query: The search query

        Returns:
            The search results
        """
        logger.info(f"Testing search agent with query: {query}")

        try:
            # Create a search task
            response = requests.post(
                f"{self.base_url}/api/agents/search/tasks",
                json={"description": f"Search for {query}"},
            )
            response.raise_for_status()
            task = response.json()
            task_id = task["id"]

            logger.info(f"Created search task with ID: {task_id}")

            # Run the task
            response = requests.post(
                f"{self.base_url}/api/agents/search/tasks/{task_id}/run",
            )
            response.raise_for_status()
            result = response.json()

            logger.info(f"Search task completed with status: {result['status']}")

            # Get the task result
            response = requests.get(
                f"{self.base_url}/api/agents/search/tasks/{task_id}",
            )
            response.raise_for_status()
            final_result = response.json()

            # Extract search results
            search_results = []
            if final_result.get("result") and isinstance(final_result["result"], dict):
                search_results = final_result["result"].get("results", [])

            logger.info(f"Found {len(search_results)} search results")

            self.results["search_agent"] = {
                "success": True,
                "data": final_result,
                "time": time.time() - self.start_time,
            }

            return final_result
        except Exception as e:
            logger.error(f"Search agent failed: {e}")
            self.results["search_agent"] = {
                "success": False,
                "error": str(e),
                "time": time.time() - self.start_time,
            }

            return {"error": str(e)}

    def test_vector_search(
        self, query: str = "LlamaFind Ultra"
    ) -> List[Dict[str, Any]]:
        """
        Test the vector search endpoint.

        Args:
            query: The search query

        Returns:
            The search results
        """
        logger.info(f"Testing vector search with query: {query}")

        try:
            response = requests.get(
                f"{self.base_url}/api/vector-search",
                params={"q": query, "limit": 5},
            )
            response.raise_for_status()
            result = response.json()

            logger.info(f"Found {len(result)} vector search results")

            self.results["vector_search"] = {
                "success": True,
                "data": result,
                "time": time.time() - self.start_time,
            }

            return result
        except Exception as e:
            logger.error(f"Vector search failed: {e}")
            self.results["vector_search"] = {
                "success": False,
                "error": str(e),
                "time": time.time() - self.start_time,
            }

            return []

    def run_all_tests(self) -> Dict[str, Any]:
        """
        Run all tests.

        Returns:
            The test results
        """
        logger.info("Running all tests...")

        self.test_health_check()
        self.test_agents_list()
        self.test_chat_agent()
        self.test_search_agent()
        self.test_vector_search()

        return self.results

    def save_results(
        self, output_file: str = "llamafind_ultra_test_results.json"
    ) -> None:
        """
        Save the test results to a file.

        Args:
            output_file: The output file path
        """
        logger.info(f"Saving test results to {output_file}")

        with open(output_file, "w") as f:
            json.dump(self.results, f, indent=2)

    def print_summary(self) -> None:
        """
        Print a summary of the test results.
        """
        logger.info("Test summary:")

        total_tests = len(self.results)
        successful_tests = sum(
            1
            for result in self.results.values()
            if result and result.get("success", False)
        )

        logger.info(f"Total tests: {total_tests}")
        logger.info(f"Successful tests: {successful_tests}")
        logger.info(f"Failed tests: {total_tests - successful_tests}")

        for test_name, result in self.results.items():
            if result:
                status = "✅ Success" if result.get("success", False) else "❌ Failed"
                time_taken = result.get("time", 0)
                logger.info(f"  - {test_name}: {status} ({time_taken:.2f}s)")

                if not result.get("success", False) and "error" in result:
                    logger.info(f"    Error: {result['error']}")


async def run_server():
    """
    Run the LlamaFind Ultra API server.
    """
    logger.info("Starting LlamaFind Ultra API server...")

    # Run the server in a separate process
    import multiprocessing

    from llamafind_ultra.server import run_server

    server_process = multiprocessing.Process(
        target=run_server,
        kwargs={"host": "localhost", "port": 5000, "debug": False},
    )
    server_process.start()

    # Wait for the server to start
    logger.info("Waiting for the server to start...")
    time.sleep(2)

    return server_process


def main():
    """
    Main entry point.
    """
    parser = argparse.ArgumentParser(
        description="LlamaFind Ultra Test Script",
    )
    parser.add_argument(
        "--base-url",
        default="http://localhost:5000",
        help="Base URL of the LlamaFind Ultra API server",
    )
    parser.add_argument(
        "--start-server",
        action="store_true",
        help="Start the LlamaFind Ultra API server",
    )
    parser.add_argument(
        "--output-file",
        default="llamafind_ultra_test_results.json",
        help="Output file for test results",
    )

    args = parser.parse_args()

    server_process = None

    try:
        # Start the server if requested
        if args.start_server:
            server_process = asyncio.run(run_server())

        # Run the tests
        tester = LlamaFindUltraTester(base_url=args.base_url)
        tester.run_all_tests()
        tester.save_results(output_file=args.output_file)
        tester.print_summary()
    finally:
        # Stop the server if we started it
        if server_process:
            logger.info("Stopping the server...")
            server_process.terminate()
            server_process.join()


if __name__ == "__main__":
    main()
