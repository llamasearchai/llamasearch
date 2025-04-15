#!/usr/bin/env python3
"""
Run all tests for the LlamaFind Ultra API.

This script runs the check_server.py script to ensure the server is running,
then runs the test_basic.py and test_api.py scripts.
"""

import argparse
import logging
import subprocess
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("llamafind-tests")


def run_command(cmd, description):
    """
    Run a command and log the output.

    Args:
        cmd: The command to run
        description: A description of the command

    Returns:
        The return code of the command
    """
    logger.info(f"Running {description}...")

    process = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    if process.stdout:
        for line in process.stdout.splitlines():
            logger.info(f"[{description}] {line}")

    if process.stderr:
        for line in process.stderr.splitlines():
            if "INFO" in line or "WARNING" in line:
                logger.info(f"[{description}] {line}")
            else:
                logger.error(f"[{description}] {line}")

    if process.returncode == 0:
        logger.info(f"{description} completed successfully")
    else:
        logger.error(f"{description} failed with return code {process.returncode}")

    return process.returncode


def main():
    """
    Main entry point.

    Returns:
        0 if all tests pass, 1 otherwise
    """
    parser = argparse.ArgumentParser(
        description="Run all tests for the LlamaFind Ultra API",
    )
    parser.add_argument(
        "--type",
        choices=["basic", "simple"],
        default="basic",
        help="Type of server to check/start",
    )
    parser.add_argument(
        "--host",
        default="localhost",
        help="Host to bind to",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=9090,
        help="Port to bind to",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Run in debug mode",
    )

    args = parser.parse_args()

    # Ensure the server is running
    check_server_cmd = [
        sys.executable,
        "check_server.py",
        "--type",
        args.type,
        "--host",
        args.host,
        "--port",
        str(args.port),
    ]

    if args.debug:
        check_server_cmd.append("--debug")

    if run_command(check_server_cmd, "check_server.py") != 0:
        return 1

    # Run the basic tests
    test_basic_cmd = [
        sys.executable,
        "test_basic.py",
        "--url",
        f"http://{args.host}:{args.port}",
    ]

    if run_command(test_basic_cmd, "test_basic.py") != 0:
        return 1

    # Run the API tests
    test_api_cmd = [
        sys.executable,
        "test_api.py",
        "--url",
        f"http://{args.host}:{args.port}",
    ]

    # If we're testing the basic server, only run the basic tests
    if args.type == "basic":
        test_api_cmd.append("--basic")

    if run_command(test_api_cmd, "test_api.py") != 0:
        return 1

    logger.info("All tests passed!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
