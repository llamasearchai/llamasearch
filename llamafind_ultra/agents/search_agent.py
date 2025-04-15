"""
Search agent for LlamaFind Ultra.

This module provides the SearchAgent class, which handles search-related
functionality using various search engines.
"""

import logging
import time
import uuid
from typing import Any, Dict, List, Optional, Union

from ..core.model import Model, ModelConfig, RemoteModel
from ..search.engine import SearchQuery, SearchResult
from ..search.providers import BraveSearch, GoogleSearch, PerplexitySearch, TavilySearch
from .base import Agent, AgentConfig, AgentMessage, AgentResponse

logger = logging.getLogger("llamafind.agents.search")


class SearchAgent(Agent):
    """Agent for performing search-related tasks.

    This agent can search the web, news, and other sources using various
    search engines, and can process search results.
    """

    def __init__(
        self, config: Union[Dict[str, Any], AgentConfig], model: Optional[Model] = None
    ):
        """Initialize the search agent.

        Args:
            config: Agent configuration.
            model: Model to use for processing search results. If None, a model will be
                loaded based on the configuration if needed.
        """
        # Set default agent type if not provided
        if isinstance(config, dict) and "agent_type" not in config:
            config["agent_type"] = "search"
        elif isinstance(config, AgentConfig) and config.agent_type == "base":
            config.agent_type = "search"

        super().__init__(config, model)

        # Initialize search engines
        self.search_engines = {}
        self._initialize_search_engines()

        # Initialize tasks storage
        self.tasks = {}

    def process_message(self, message: Union[str, AgentMessage]) -> AgentResponse:
        """Process a message and generate a search response.

        Args:
            message: Message to process.

        Returns:
            Agent response.
        """
        # Create message object if needed
        message_obj = self._create_message(message)
        self._add_to_history(message_obj)

        logger.info(f"Processing search message: {message_obj.content}")

        try:
            # Check if this is a search query
            query = message_obj.content
            results = self._perform_search(query)

            # Create a response with search results
            if results:
                response_content = self._format_search_results(results)
            else:
                response_content = "I couldn't find any results for your search query."

            # Create and return response
            response = self._create_response(response_content, message_obj)
            response.metadata["search_results"] = [r.to_dict() for r in results]
            self._add_to_history(response)

            return response

        except Exception as e:
            logger.error(f"Error processing search message: {e}")
            error_response = self._create_response(
                f"Sorry, I encountered an error while processing your search: {str(e)}",
                message_obj,
            )
            self._add_to_history(error_response)
            return error_response

    def create_task(self, description: str) -> str:
        """Create a search task.

        Args:
            description: Description of the search task.

        Returns:
            Task ID.
        """
        logger.info(f"Creating search task: {description}")

        # Create a task ID
        task_id = f"search_task_{int(time.time())}_{len(self.tasks)}"

        # Store the task
        self.tasks[task_id] = {
            "id": task_id,
            "description": description,
            "status": "created",
            "created_at": time.time(),
            "updated_at": time.time(),
            "result": None,
            "error": None,
        }

        logger.info(f"Created task {task_id}")
        return task_id

    def run_task(self, task_id: str) -> Dict[str, Any]:
        """Run a search task.

        Args:
            task_id: ID of the task to run.

        Returns:
            Task result.

        Raises:
            ValueError: If the task is not found.
        """
        logger.info(f"Running search task: {task_id}")

        # Check if task exists
        if task_id not in self.tasks:
            raise ValueError(f"Task not found: {task_id}")

        # Get the task
        task = self.tasks[task_id]

        # Update task status
        task["status"] = "running"
        task["updated_at"] = time.time()

        try:
            # Perform the search
            query = task["description"]
            results = self._perform_search(query)

            # Update task with results
            task["result"] = {
                "content": self._format_search_results(results),
                "timestamp": time.time(),
                "results": [r.to_dict() for r in results],
            }
            task["status"] = "completed"

        except Exception as e:
            logger.error(f"Error running search task {task_id}: {e}")
            task["status"] = "failed"
            task["error"] = str(e)

        # Update task timestamp
        task["updated_at"] = time.time()

        return task

    def _initialize_search_engines(self) -> None:
        """Initialize search engines based on configuration."""
        # Get search engine configurations from agent config
        engines_config = self.config.params.get("search_engines", {})

        # Initialize Brave Search if configured
        if "brave" in engines_config:
            brave_config = engines_config["brave"]
            self.search_engines["brave"] = BraveSearch(
                api_key=brave_config.get("api_key"), config=brave_config.get("config")
            )

        # Initialize Google Search if configured
        if "google" in engines_config:
            google_config = engines_config["google"]
            self.search_engines["google"] = GoogleSearch(
                api_key=google_config.get("api_key"), config=google_config.get("config")
            )

        # Initialize Perplexity Search if configured
        if "perplexity" in engines_config:
            perplexity_config = engines_config["perplexity"]
            self.search_engines["perplexity"] = PerplexitySearch(
                api_key=perplexity_config.get("api_key"),
                config=perplexity_config.get("config"),
            )

        # Initialize Tavily Search if configured
        if "tavily" in engines_config:
            tavily_config = engines_config["tavily"]
            self.search_engines["tavily"] = TavilySearch(
                api_key=tavily_config.get("api_key"), config=tavily_config.get("config")
            )

        # If no search engines configured, use a default one
        if not self.search_engines:
            logger.warning("No search engines configured, using a mock search engine")
            self.search_engines["mock"] = self._create_mock_search_engine()

    def _perform_search(self, query: str) -> List[SearchResult]:
        """Perform a search with all configured search engines.

        Args:
            query: Search query.

        Returns:
            Combined list of search results.
        """
        all_results = []

        # Search with each configured engine
        for engine_name, engine in self.search_engines.items():
            logger.info(f"Searching with {engine_name}: {query}")
            try:
                engine_results = engine.search(query)
                logger.info(f"Found {len(engine_results)} results with {engine_name}")
                all_results.extend(engine_results)
            except Exception as e:
                logger.error(f"Error searching with {engine_name}: {e}")

        # Sort results by rank
        all_results.sort(key=lambda r: r.rank if r.rank is not None else 999)

        return all_results

    def _format_search_results(self, results: List[SearchResult]) -> str:
        """Format search results for display.

        Args:
            results: List of search results.

        Returns:
            Formatted search results as a string.
        """
        if not results:
            return "No results found."

        output = f"Here are the search results:\n\n"

        # Add each result
        for i, result in enumerate(results[:5]):  # Show top 5 results
            output += f"{i+1}. {result.title}\n"
            output += f"   {result.url}\n"
            output += f"   {result.snippet}\n\n"

        # Add a note if there are more results
        if len(results) > 5:
            output += f"...and {len(results) - 5} more results."

        return output

    def _create_mock_search_engine(self) -> Any:
        """Create a mock search engine for testing.

        Returns:
            Mock search engine.
        """

        class MockSearchEngine:
            def search(self, query):
                # Return mock results
                return [
                    SearchResult(
                        title=f"Mock Result 1 for {query}",
                        url="https://example.com/1",
                        snippet="This is a mock search result.",
                        source="Mock",
                        domain="example.com",
                        rank=1,
                    ),
                    SearchResult(
                        title=f"Mock Result 2 for {query}",
                        url="https://example.com/2",
                        snippet="This is another mock search result.",
                        source="Mock",
                        domain="example.com",
                        rank=2,
                    ),
                ]

        return MockSearchEngine()
