#!/usr/bin/env python3
"""
Test script for the LlamaFind Agent API
"""

import asyncio
import json
import time

import requests

API_BASE_URL = "http://localhost:3000/api"


def print_json(data):
    """Print JSON data in a readable format."""
    print(json.dumps(data, indent=2))


async def test_agent_api():
    """Test the agent API endpoints."""
    print("Testing Agent API...")

    try:
        # Test health endpoint
        print("\n--- Testing /api/health ---")
        response = requests.get(f"{API_BASE_URL}/health")
        print_json(response.json())

        # Test agents list endpoint
        print("\n--- Testing /api/agents ---")
        response = requests.get(f"{API_BASE_URL}/agents")
        agents_data = response.json()
        print_json(agents_data)

        if agents_data.get("status") == "success":
            # Test chat agent message
            print("\n--- Testing chat agent message ---")
            chat_response = requests.post(
                f"{API_BASE_URL}/agents/chat/message",
                json={"message": "What time is it?"},
            )
            chat_data = chat_response.json()
            print_json(chat_data)

            # Test search agent message
            print("\n--- Testing search agent message ---")
            search_response = requests.post(
                f"{API_BASE_URL}/agents/search/message",
                json={"message": "Tell me about the MLX framework"},
            )
            search_data = search_response.json()
            print_json(search_data)

            # Test creating a task
            print("\n--- Testing task creation ---")
            task_response = requests.post(
                f"{API_BASE_URL}/agents/chat/tasks",
                json={"description": "Tell me a joke"},
            )
            task_data = task_response.json()
            print_json(task_data)

            if task_data.get("status") == "success":
                task_id = task_data["task_id"]

                # Test getting task status
                print(f"\n--- Testing get task status for {task_id} ---")
                status_response = requests.get(
                    f"{API_BASE_URL}/agents/chat/tasks/{task_id}"
                )
                status_data = status_response.json()
                print_json(status_data)

                # Test running the task
                print(f"\n--- Testing running task {task_id} ---")
                run_response = requests.post(
                    f"{API_BASE_URL}/agents/chat/tasks/{task_id}/run"
                )
                run_data = run_response.json()
                print_json(run_data)

                # Check task status after running
                print(f"\n--- Checking task status after running ---")
                status_response = requests.get(
                    f"{API_BASE_URL}/agents/chat/tasks/{task_id}"
                )
                status_data = status_response.json()
                print_json(status_data)

    except Exception as e:
        print(f"Error testing API: {str(e)}")

    print("\n--- Agent API Testing Complete ---")


if __name__ == "__main__":
    asyncio.run(test_agent_api())
