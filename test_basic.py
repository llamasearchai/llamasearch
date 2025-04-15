#!/usr/bin/env python3
"""
Test script for the basic LlamaFind Ultra API server.

This script tests the health check endpoint of the basic LlamaFind Ultra API server.
"""

import argparse
import logging
import sys
import time

import requests
from requests.exceptions import ConnectionError, Timeout

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("llamafind-basic-test")

# Default API base URL
DEFAULT_URL = "http://localhost:9090"


def test_health_check(base_url):
    """
    Test the health check endpoint.

    Args:
        base_url: The base URL of the API server

    Returns:
        True if the test passes, False otherwise
    """
    logger.info("Testing health check endpoint...")

    try:
        response = requests.get(f"{base_url}/health", timeout=5)
        response.raise_for_status()
        result = response.json()

        logger.info(f"Health check response: {result}")

        # Verify the response contains the expected fields
        assert "status" in result, "Response missing 'status' field"
        assert "message" in result, "Response missing 'message' field"
        assert "version" in result, "Response missing 'version' field"

        # Verify the values are as expected
        assert (
            result["status"] == "ok"
        ), f"Expected status 'ok', got '{result['status']}'"
        assert (
            "LlamaFind Ultra API is running" in result["message"]
        ), "Unexpected message format"
        assert (
            result["version"] == "1.0.0"
        ), f"Expected version '1.0.0', got '{result['version']}'"

        logger.info("Health check test passed!")
        return True
    except ConnectionError as e:
        logger.error(f"Connection error: {e}. Is the server running?")
        return False
    except Timeout as e:
        logger.error(f"Request timed out: {e}")
        return False
    except AssertionError as e:
        logger.error(f"Assertion failed: {e}")
        return False
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return False


def wait_for_server(base_url, max_retries=5, delay=1):
    """
    Wait for the server to become available.

    Args:
        base_url: The base URL of the API server
        max_retries: Maximum number of retry attempts
        delay: Delay between retries in seconds

    Returns:
        True if server becomes available, False otherwise
    """
    logger.info(f"Waiting for server to become available at {base_url}...")

    for attempt in range(max_retries):
        try:
            response = requests.get(f"{base_url}/health", timeout=2)
            if response.status_code == 200:
                logger.info(f"Server is available after {attempt + 1} attempts")
                return True
        except (ConnectionError, Timeout):
            pass

        if attempt < max_retries - 1:
            logger.info(f"Attempt {attempt + 1} failed, retrying in {delay} seconds...")
            time.sleep(delay)

    logger.error(f"Server did not become available after {max_retries} attempts")
    return False


def main():
    """
    Main entry point.

    Returns:
        0 if all tests pass, 1 otherwise
    """
    parser = argparse.ArgumentParser(
        description="Test the basic LlamaFind Ultra API server"
    )
    parser.add_argument(
        "--url", default=DEFAULT_URL, help=f"API base URL (default: {DEFAULT_URL})"
    )
    parser.add_argument(
        "--wait", action="store_true", help="Wait for server to become available"
    )

    args = parser.parse_args()

    logger.info(f"Running basic API tests against {args.url}...")

    if args.wait and not wait_for_server(args.url):
        return 1

    if test_health_check(args.url):
        logger.info("All tests passed!")
        return 0
    else:
        logger.error("Some tests failed!")
        return 1


if __name__ == "__main__":
    sys.exit(main())
