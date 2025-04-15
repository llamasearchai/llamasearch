#!/usr/bin/env python3
"""
Simple LlamaFind Ultra API Server.

This script provides a simple API server for LlamaFind Ultra, without relying on
the full package structure. It's useful for testing and development.
"""

import argparse
import json
import logging
import os
import sys
import time
import uuid
from typing import Any, Dict, List, Optional

from flask import Flask, jsonify, request
from flask_cors import CORS

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("llamafind-simple")

# Create the Flask app
app = Flask(__name__)
CORS(app)

# Version
VERSION = "1.0.0"

# In-memory storage for agents and tasks
agents = {
    "search": {
        "type": "search",
        "name": "Search Agent",
        "description": "Agent for performing web searches",
        "capabilities": ["web_search", "news_search"],
    },
    "chat": {
        "type": "chat",
        "name": "Chat Agent",
        "description": "Agent for conversational interactions",
        "capabilities": ["get_current_time", "get_weather"],
    },
    "finance": {
        "type": "finance",
        "name": "Finance Agent",
        "description": "Agent for financial information",
        "capabilities": ["get_stock_info", "get_stock_price", "get_stock_change"],
    },
}

tasks = {}


@app.route("/api/health", methods=["GET"])
def health_check():
    """
    Health check endpoint.

    Returns:
        JSON response with health status
    """
    logger.info("Health check request received")
    return jsonify(
        {
            "status": "ok",
            "message": f"LlamaFind Ultra API is running (v{VERSION})",
            "version": VERSION,
        }
    )


@app.route("/api/agents", methods=["GET"])
def list_agents():
    """
    List available agents.

    Returns:
        JSON response with available agents
    """
    logger.info("Agents list request received")
    return jsonify(list(agents.values()))


@app.route("/api/agents/<agent_type>/message", methods=["POST"])
def agent_message(agent_type):
    """
    Send a message to an agent.

    Args:
        agent_type: The type of agent to send the message to

    Returns:
        JSON response with the agent's response
    """
    logger.info(f"Message request received for agent: {agent_type}")

    # Check if agent exists
    if agent_type not in agents:
        return jsonify({"error": f"Agent not found: {agent_type}"}), 404

    # Get the message from the request
    data = request.json
    if not data or "message" not in data:
        return jsonify({"error": "Missing message parameter"}), 400

    message = data["message"]
    logger.info(f"Message content: {message}")

    # Process the message based on agent type
    if agent_type == "chat":
        response = {
            "content": f"Hello! I'm the Chat Agent. You said: {message}",
            "timestamp": time.time(),
        }
    elif agent_type == "search":
        response = {
            "content": f"I'll search for: {message}",
            "timestamp": time.time(),
        }
    elif agent_type == "finance":
        response = {
            "content": f"I'll look up financial information for: {message}",
            "timestamp": time.time(),
        }
    else:
        response = {
            "content": f"Agent {agent_type} received: {message}",
            "timestamp": time.time(),
        }

    return jsonify(response)


@app.route("/api/agents/<agent_type>/tasks", methods=["POST"])
def create_task(agent_type):
    """
    Create a task for an agent.

    Args:
        agent_type: The type of agent to create the task for

    Returns:
        JSON response with the created task
    """
    logger.info(f"Task creation request received for agent: {agent_type}")

    # Check if agent exists
    if agent_type not in agents:
        return jsonify({"error": f"Agent not found: {agent_type}"}), 404

    # Get the task description from the request
    data = request.json
    if not data or "description" not in data:
        return jsonify({"error": "Missing description parameter"}), 400

    description = data["description"]
    logger.info(f"Task description: {description}")

    # Create a task ID
    timestamp = int(time.time())
    task_id = f"task_{timestamp}_{len(tasks)}"

    # Create the task
    task = {
        "id": task_id,
        "agent_type": agent_type,
        "description": description,
        "status": "created",
        "created_at": time.time(),
        "updated_at": time.time(),
        "result": None,
        "error": None,
    }

    # Store the task
    tasks[task_id] = task
    logger.info(f"Task created with ID: {task_id}")

    return jsonify(task)


@app.route("/api/agents/<agent_type>/tasks/<task_id>", methods=["GET"])
def get_task(agent_type, task_id):
    """
    Get a task by ID.

    Args:
        agent_type: The type of agent that owns the task
        task_id: The ID of the task

    Returns:
        JSON response with the task
    """
    logger.info(
        f"Task retrieval request received for agent: {agent_type}, task: {task_id}"
    )

    # Check if agent exists
    if agent_type not in agents:
        return jsonify({"error": f"Agent not found: {agent_type}"}), 404

    # Check if task exists
    if task_id not in tasks:
        return jsonify({"error": f"Task not found: {task_id}"}), 404

    # Check if task belongs to agent
    task = tasks[task_id]
    if task["agent_type"] != agent_type:
        return (
            jsonify({"error": f"Task {task_id} does not belong to agent {agent_type}"}),
            404,
        )

    return jsonify(task)


@app.route("/api/agents/<agent_type>/tasks/<task_id>/run", methods=["POST"])
def run_task(agent_type, task_id):
    """
    Run a task.

    Args:
        agent_type: The type of agent that owns the task
        task_id: The ID of the task

    Returns:
        JSON response with the task result
    """
    logger.info(
        f"Task execution request received for agent: {agent_type}, task: {task_id}"
    )

    # Check if agent exists
    if agent_type not in agents:
        return jsonify({"error": f"Agent not found: {agent_type}"}), 404

    # Check if task exists
    if task_id not in tasks:
        return jsonify({"error": f"Task not found: {task_id}"}), 404

    # Check if task belongs to agent
    task = tasks[task_id]
    if task["agent_type"] != agent_type:
        return (
            jsonify({"error": f"Task {task_id} does not belong to agent {agent_type}"}),
            404,
        )

    # Update task status
    task["status"] = "running"
    task["updated_at"] = time.time()
    logger.info(f"Running task: {task_id}")

    # Process the task based on agent type
    try:
        if agent_type == "chat":
            # Simulate chat processing
            task["result"] = {
                "content": f"I've processed your request: {task['description']}",
                "timestamp": time.time(),
            }
        elif agent_type == "search":
            # Simulate search processing
            task["result"] = {
                "query": task["description"].replace("Search for ", ""),
                "results": [
                    {
                        "title": "LlamaFind Ultra Documentation",
                        "url": "https://llamafind.ai/docs",
                        "snippet": "LlamaFind Ultra is an advanced search and agent system...",
                    },
                    {
                        "title": "Getting Started with LlamaFind Ultra",
                        "url": "https://llamafind.ai/docs/getting-started",
                        "snippet": "Learn how to use LlamaFind Ultra for your search needs...",
                    },
                ],
                "timestamp": time.time(),
            }
        elif agent_type == "finance":
            # Simulate finance processing
            task["result"] = {
                "ticker": "AAPL",
                "price": 175.34,
                "change": 2.45,
                "change_percent": 1.42,
                "timestamp": time.time(),
            }

        # Update task status
        task["status"] = "completed"
        logger.info(f"Task completed: {task_id}")
    except Exception as e:
        # Update task status
        task["status"] = "failed"
        task["error"] = str(e)
        logger.error(f"Task failed: {task_id}, error: {e}")

    # Update task timestamp
    task["updated_at"] = time.time()

    return jsonify(task)


@app.route("/api/search", methods=["GET"])
def search():
    """
    Perform a search.

    Returns:
        JSON response with search results
    """
    logger.info("Search request received")

    # Get search parameters
    query = request.args.get("q")
    if not query:
        return jsonify({"error": "Missing query parameter"}), 400

    logger.info(f"Search query: {query}")

    # Simulate search processing
    results = [
        {
            "title": "LlamaFind Ultra Documentation",
            "url": "https://llamafind.ai/docs",
            "snippet": "LlamaFind Ultra is an advanced search and agent system...",
        },
        {
            "title": "Getting Started with LlamaFind Ultra",
            "url": "https://llamafind.ai/docs/getting-started",
            "snippet": "Learn how to use LlamaFind Ultra for your search needs...",
        },
    ]

    return jsonify(
        {
            "query": query,
            "results": results,
            "timestamp": time.time(),
        }
    )


@app.route("/api/vector-search", methods=["GET"])
def vector_search():
    """
    Search the vector database.

    Returns:
        JSON response with search results
    """
    logger.info("Vector search request received")

    # Get search parameters
    query = request.args.get("q")
    if not query:
        return jsonify({"error": "Missing query parameter"}), 400

    logger.info(f"Vector search query: {query}")

    # Simulate vector search processing
    results = [
        {
            "title": "LlamaFind Ultra Vector Search",
            "url": "https://llamafind.ai/docs/vector-search",
            "snippet": "Learn how to use vector search in LlamaFind Ultra...",
            "score": 0.95,
        },
        {
            "title": "Semantic Search with LlamaFind Ultra",
            "url": "https://llamafind.ai/docs/semantic-search",
            "snippet": "Understand how semantic search works in LlamaFind Ultra...",
            "score": 0.87,
        },
    ]

    return jsonify(results)


def main():
    """
    Main entry point.
    """
    parser = argparse.ArgumentParser(
        description="Simple LlamaFind Ultra API Server",
    )
    parser.add_argument(
        "--host",
        default="localhost",
        help="Host to bind to",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=5000,
        help="Port to bind to",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Run in debug mode",
    )

    args = parser.parse_args()

    logger.info(f"Starting simple LlamaFind API server on {args.host}:{args.port}")

    app.run(host=args.host, port=args.port, debug=args.debug)


if __name__ == "__main__":
    main()
