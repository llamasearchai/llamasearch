#!/usr/bin/env python3
"""
Test script for the LlamaFind Ultra API.

This script tests the functionality of the LlamaFind Ultra API server.
"""

import json
import logging
import requests
import sys
import time
import argparse
from requests.exceptions import ConnectionError, Timeout

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("llamafind-test")

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
        
        assert result["status"] == "ok"
        assert "LlamaFind Ultra API is running" in result["message"]
        
        logger.info("Health check test passed!")
        return True
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return False

def test_agents_list(base_url):
    """
    Test the agents list endpoint.
    """
    logger.info("Testing agents list endpoint...")
    
    try:
        response = requests.get(f"{base_url}/agents")
        response.raise_for_status()
        agents = response.json()
        
        logger.info(f"Found {len(agents)} agents")
        for agent in agents:
            logger.info(f"  - {agent['type']}: {agent['name']} ({len(agent['capabilities'])} capabilities)")
        
        assert len(agents) >= 2
        assert any(agent["type"] == "search" for agent in agents)
        assert any(agent["type"] == "chat" for agent in agents)
        
        logger.info("Agents list test passed!")
        return True
    except Exception as e:
        logger.error(f"Agents list failed: {e}")
        return False

def test_chat_agent(base_url):
    """
    Test the chat agent.
    """
    logger.info("Testing chat agent...")
    
    try:
        # Test sending a message
        message = "What time is it?"
        response = requests.post(
            f"{base_url}/agents/chat/message",
            json={"message": message},
        )
        response.raise_for_status()
        result = response.json()
        
        logger.info(f"Chat agent response: {result}")
        
        assert "content" in result
        assert "timestamp" in result
        
        # Test creating a task
        response = requests.post(
            f"{base_url}/agents/chat/tasks",
            json={"description": "Tell a joke"},
        )
        response.raise_for_status()
        task = response.json()
        
        logger.info(f"Created chat task: {task}")
        
        assert "id" in task
        assert task["status"] == "created"
        
        # Test running the task
        task_id = task["id"]
        response = requests.post(
            f"{base_url}/agents/chat/tasks/{task_id}/run",
        )
        response.raise_for_status()
        result = response.json()
        
        logger.info(f"Chat task result: {result}")
        
        assert result["status"] == "completed"
        assert "result" in result
        
        logger.info("Chat agent test passed!")
        return True
    except Exception as e:
        logger.error(f"Chat agent failed: {e}")
        return False

def test_search_agent(base_url):
    """
    Test the search agent.
    """
    logger.info("Testing search agent...")
    
    try:
        # Test creating a task
        response = requests.post(
            f"{base_url}/agents/search/tasks",
            json={"description": "Search for LlamaFind Ultra"},
        )
        response.raise_for_status()
        task = response.json()
        
        logger.info(f"Created search task: {task}")
        
        assert "id" in task
        assert task["status"] == "created"
        
        # Test running the task
        task_id = task["id"]
        response = requests.post(
            f"{base_url}/agents/search/tasks/{task_id}/run",
        )
        response.raise_for_status()
        result = response.json()
        
        logger.info(f"Search task result: {result}")
        
        assert result["status"] == "completed"
        assert "result" in result
        
        # Get the task result
        response = requests.get(
            f"{base_url}/agents/search/tasks/{task_id}",
        )
        response.raise_for_status()
        final_result = response.json()
        
        logger.info(f"Final search task result: {final_result}")
        
        # Extract search results
        search_results = []
        if final_result.get("result") and isinstance(final_result["result"], dict):
            search_results = final_result["result"].get("results", [])
        
        logger.info(f"Found {len(search_results)} search results")
        
        assert len(search_results) > 0
        
        logger.info("Search agent test passed!")
        return True
    except Exception as e:
        logger.error(f"Search agent failed: {e}")
        return False

def test_search_endpoint(base_url):
    """
    Test the search endpoint.
    """
    logger.info("Testing search endpoint...")
    
    try:
        query = "LlamaFind Ultra"
        response = requests.get(
            f"{base_url}/search",
            params={"q": query},
        )
        response.raise_for_status()
        result = response.json()
        
        logger.info(f"Search response: {result}")
        
        assert "query" in result
        assert result["query"] == query
        assert "results" in result
        assert len(result["results"]) > 0
        
        logger.info("Search endpoint test passed!")
        return True
    except Exception as e:
        logger.error(f"Search endpoint failed: {e}")
        return False

def test_vector_search_endpoint(base_url):
    """
    Test the vector search endpoint.
    """
    logger.info("Testing vector search endpoint...")
    
    try:
        query = "LlamaFind Ultra"
        response = requests.get(
            f"{base_url}/vector-search",
            params={"q": query},
        )
        response.raise_for_status()
        results = response.json()
        
        logger.info(f"Vector search response: {results}")
        
        assert isinstance(results, list)
        assert len(results) > 0
        assert "title" in results[0]
        assert "url" in results[0]
        assert "snippet" in results[0]
        assert "score" in results[0]
        
        logger.info("Vector search endpoint test passed!")
        return True
    except Exception as e:
        logger.error(f"Vector search failed: {e}")
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
    parser = argparse.ArgumentParser(description="Test the LlamaFind Ultra API server")
    parser.add_argument("--url", default=DEFAULT_URL, help=f"API base URL (default: {DEFAULT_URL})")
    parser.add_argument("--wait", action="store_true", help="Wait for server to become available")
    parser.add_argument("--basic", action="store_true", help="Only test basic endpoints (health check)")
    parser.add_argument("--skip-agents", action="store_true", help="Skip agent-related tests")
    parser.add_argument("--skip-search", action="store_true", help="Skip search endpoint tests")
    parser.add_argument("--skip-vector", action="store_true", help="Skip vector search tests")
    
    args = parser.parse_args()
    base_url = args.url
    
    logger.info(f"Running API tests against {base_url}...")
    
    if args.wait and not wait_for_server(base_url):
        return 1
    
    all_passed = True
    
    # Health check is always tested
    if not test_health_check(base_url):
        all_passed = False
        # If health check fails, don't continue with other tests
        return 1
    
    # Skip other tests if --basic is specified
    if args.basic:
        logger.info("Only testing basic endpoints as requested")
        return 0 if all_passed else 1
    
    # Test agents endpoints if not skipped
    if not args.skip_agents:
        if not test_agents_list(base_url):
            all_passed = False
        
        if not test_chat_agent(base_url):
            all_passed = False
        
        if not test_search_agent(base_url):
            all_passed = False
    else:
        logger.info("Skipping agent tests as requested")
    
    # Test search endpoint if not skipped
    if not args.skip_search:
        if not test_search_endpoint(base_url):
            all_passed = False
    else:
        logger.info("Skipping search endpoint test as requested")
    
    # Test vector search endpoint if not skipped
    if not args.skip_vector:
        if not test_vector_search_endpoint(base_url):
            all_passed = False
    else:
        logger.info("Skipping vector search test as requested")
    
    if all_passed:
        logger.info("All tests passed!")
        return 0
    else:
        logger.error("Some tests failed!")
        return 1
    
if __name__ == "__main__":
    sys.exit(main()) 