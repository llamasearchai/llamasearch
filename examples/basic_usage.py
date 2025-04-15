#!/usr/bin/env python3
"""
LlamaFind Ultra Basic Usage Examples

This script demonstrates how to use the basic features of LlamaFind Ultra,
including the Chat, Search, and Finance agents.
"""

import json
import os
import sys
from pathlib import Path

# Add parent directory to path so we can import without installing
sys.path.append(str(Path(__file__).parent.parent))

from llamafind_ultra.agents import AgentConfig, AgentMessage
from llamafind_ultra.agents.chat_agent import ChatAgent
from llamafind_ultra.agents.finance_agent import FinanceAgent
from llamafind_ultra.agents.search_agent import SearchAgent
from llamafind_ultra.search.providers.brave import BraveSearch
from llamafind_ultra.search.providers.google import GoogleSearch
from llamafind_ultra.search.providers.perplexity import PerplexitySearch


def print_header(text):
    """Print a header with the given text."""
    print("\n" + "=" * 80)
    print(f" {text} ".center(80, "="))
    print("=" * 80 + "\n")


def print_response(response):
    """Print an agent response in a nice format."""
    print(f"\nResponse: {response.content}")
    if response.metadata:
        print("\nMetadata:")
        for key, value in response.metadata.items():
            print(f"  {key}: {value}")
    print("\n" + "-" * 80)


def demo_chat_agent():
    """Demonstrate the chat agent."""
    print_header("Chat Agent Demo")

    # Create a Chat Agent
    config = AgentConfig(
        name="Demo Chat Agent",
        agent_type="chat",
        capabilities=["conversation", "time_awareness"],
    )
    agent = ChatAgent(config)

    # Process some messages
    messages = [
        "Hello, who are you?",
        "What time is it now?",
        "Can you tell me about LlamaFind Ultra?",
    ]

    for msg in messages:
        print(f"\nUser: {msg}")
        response = agent.process_message(msg)
        print_response(response)

    # Create and run a task
    print("\nCreating a task...")
    task_id = agent.create_task("Summarize what LlamaFind Ultra is")
    print(f"Task created with ID: {task_id}")

    print("\nRunning the task...")
    result = agent.run_task(task_id)
    print_response(result)


def demo_search_agent():
    """Demonstrate the search agent."""
    print_header("Search Agent Demo")

    # Get API keys from environment
    brave_api_key = os.getenv("BRAVE_API_KEY", "demo_key")
    google_api_key = os.getenv("GOOGLE_API_KEY", "demo_key")
    google_cse_id = os.getenv("GOOGLE_CSE_ID", "demo_cse_id")
    perplexity_api_key = os.getenv("PERPLEXITY_API_KEY", "demo_key")

    # Create search engines
    brave_search = BraveSearch(api_key=brave_api_key)
    google_search = GoogleSearch(api_key=google_api_key, search_engine_id=google_cse_id)
    perplexity_search = PerplexitySearch(api_key=perplexity_api_key)

    # Create a Search Agent with Brave Search
    config = AgentConfig(
        name="Demo Search Agent", agent_type="search", capabilities=["web_search"]
    )
    agent = SearchAgent(config, search_engine=brave_search)

    # Process a search query
    query = "What is artificial intelligence?"
    print(f"\nUser: {query}")
    response = agent.process_message(query)
    print_response(response)

    # Switch to Google Search
    print("\nSwitching to Google Search...")
    agent.search_engine = google_search

    # Process another query
    query = "Latest advances in large language models"
    print(f"\nUser: {query}")
    response = agent.process_message(query)
    print_response(response)

    # Switch to Perplexity Search
    print("\nSwitching to Perplexity Search...")
    agent.search_engine = perplexity_search

    # Create and run a search task
    print("\nCreating a search task...")
    task_id = agent.create_task("What are the environmental impacts of AI?")
    print(f"Task created with ID: {task_id}")

    print("\nRunning the search task...")
    result = agent.run_task(task_id)
    print_response(result)


def demo_finance_agent():
    """Demonstrate the finance agent."""
    print_header("Finance Agent Demo")

    # Create a Finance Agent
    config = AgentConfig(
        name="Demo Finance Agent",
        agent_type="finance",
        capabilities=["stock_info", "market_data"],
    )
    agent = FinanceAgent(config)

    # Process stock queries
    queries = [
        "What's the stock price of AAPL?",
        "Show me financial information for MSFT",
        "Compare TSLA and GOOG stock performance",
    ]

    for query in queries:
        print(f"\nUser: {query}")
        response = agent.process_message(query)
        print_response(response)

    # Create and run a finance task
    print("\nCreating a finance task...")
    task_id = agent.create_task("Analyze the recent performance of tech stocks")
    print(f"Task created with ID: {task_id}")

    print("\nRunning the finance task...")
    result = agent.run_task(task_id)
    print_response(result)


def main():
    """Run all demos."""
    print_header("LlamaFind Ultra Demos")

    try:
        demo_chat_agent()
        demo_search_agent()
        demo_finance_agent()

        print_header("All Demos Completed Successfully!")
    except Exception as e:
        print(f"\nError: {e}")
        print("Demo failed. Please check your API keys and connection.")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
