"""
Tests for the LlamaFind Ultra agents.

This module provides tests for the agent implementations
to ensure they function as expected.
"""

import unittest
from unittest.mock import MagicMock, patch
import time

from llamafind_ultra.agents import AgentConfig, AgentMessage, AgentResponse
from llamafind_ultra.agents.chat_agent import ChatAgent
from llamafind_ultra.agents.search_agent import SearchAgent
from llamafind_ultra.agents.finance_agent import FinanceAgent
from llamafind_ultra.search.engine import SearchResult

class TestChatAgent(unittest.TestCase):
    """Tests for the ChatAgent class."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.config = AgentConfig(
            name="Test Chat Agent",
            description="Test chat agent",
            agent_type="chat",
            capabilities=["chat", "get_current_time"]
        )
        self.agent = ChatAgent(self.config)
    
    def test_initialization(self):
        """Test agent initialization."""
        self.assertEqual(self.agent.name, "Test Chat Agent")
        self.assertEqual(self.agent.agent_type, "chat")
        self.assertIn("get_current_time", self.agent.get_capabilities())
    
    def test_process_message_time(self):
        """Test processing a message asking for the time."""
        response = self.agent.process_message("What time is it?")
        self.assertIsInstance(response, AgentResponse)
        self.assertIn("current time", response.content.lower())
    
    def test_process_message_weather(self):
        """Test processing a message asking about the weather."""
        response = self.agent.process_message("What's the weather like today?")
        self.assertIsInstance(response, AgentResponse)
        self.assertIn("weather", response.content.lower())
    
    def test_create_task(self):
        """Test creating a task."""
        task_id = self.agent.create_task("Test task")
        self.assertIn(task_id, self.agent.tasks)
        self.assertEqual(self.agent.tasks[task_id]["description"], "Test task")
        self.assertEqual(self.agent.tasks[task_id]["status"], "created")
    
    def test_run_task(self):
        """Test running a task."""
        task_id = self.agent.create_task("Tell me the time")
        result = self.agent.run_task(task_id)
        self.assertEqual(result["status"], "completed")
        self.assertIn("content", result["result"])
        self.assertIn("current time", result["result"]["content"].lower())


class TestSearchAgent(unittest.TestCase):
    """Tests for the SearchAgent class."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.config = AgentConfig(
            name="Test Search Agent",
            description="Test search agent",
            agent_type="search",
            capabilities=["web_search"]
        )
        # Create a mock search engine for testing
        self.agent = SearchAgent(self.config)
        
        # Replace the search engines with a mock
        mock_engine = MagicMock()
        mock_results = [
            SearchResult(
                title="Test Result 1",
                url="https://example.com/1",
                snippet="This is test result 1",
                source="Test"
            ),
            SearchResult(
                title="Test Result 2",
                url="https://example.com/2",
                snippet="This is test result 2",
                source="Test"
            )
        ]
        mock_engine.search.return_value = mock_results
        self.agent.search_engines = {"mock": mock_engine}
    
    def test_initialization(self):
        """Test agent initialization."""
        self.assertEqual(self.agent.name, "Test Search Agent")
        self.assertEqual(self.agent.agent_type, "search")
        self.assertIn("web_search", self.agent.get_capabilities())
    
    def test_process_message(self):
        """Test processing a search message."""
        response = self.agent.process_message("Search for test query")
        self.assertIsInstance(response, AgentResponse)
        self.assertIn("test result", response.content.lower())
        self.assertIn("search_results", response.metadata)
        self.assertEqual(len(response.metadata["search_results"]), 2)
    
    def test_create_task(self):
        """Test creating a search task."""
        task_id = self.agent.create_task("Search for task test")
        self.assertIn(task_id, self.agent.tasks)
        self.assertEqual(self.agent.tasks[task_id]["description"], "Search for task test")
        self.assertEqual(self.agent.tasks[task_id]["status"], "created")
    
    def test_run_task(self):
        """Test running a search task."""
        task_id = self.agent.create_task("Search for task test")
        result = self.agent.run_task(task_id)
        self.assertEqual(result["status"], "completed")
        self.assertIn("content", result["result"])
        self.assertIn("test result", result["result"]["content"].lower())
        self.assertIn("results", result["result"])
        self.assertEqual(len(result["result"]["results"]), 2)


class TestFinanceAgent(unittest.TestCase):
    """Tests for the FinanceAgent class."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.config = AgentConfig(
            name="Test Finance Agent",
            description="Test finance agent",
            agent_type="finance",
            capabilities=["get_stock_info", "get_stock_price"]
        )
        self.agent = FinanceAgent(self.config)
    
    def test_initialization(self):
        """Test agent initialization."""
        self.assertEqual(self.agent.name, "Test Finance Agent")
        self.assertEqual(self.agent.agent_type, "finance")
        self.assertIn("get_stock_price", self.agent.get_capabilities())
    
    def test_process_message_price(self):
        """Test processing a message asking for a stock price."""
        response = self.agent.process_message("What's the price of AAPL?")
        self.assertIsInstance(response, AgentResponse)
        self.assertIn("price", response.content.lower())
        self.assertIn("aapl", response.content.lower())
    
    def test_process_message_info(self):
        """Test processing a message asking for stock info."""
        response = self.agent.process_message("Tell me about MSFT stock")
        self.assertIsInstance(response, AgentResponse)
        self.assertIn("msft", response.content.lower())
        self.assertIn("trading", response.content.lower())
    
    def test_create_task(self):
        """Test creating a finance task."""
        task_id = self.agent.create_task("Get price of GOOG")
        self.assertIn(task_id, self.agent.tasks)
        self.assertEqual(self.agent.tasks[task_id]["description"], "Get price of GOOG")
        self.assertEqual(self.agent.tasks[task_id]["status"], "created")
    
    def test_run_task(self):
        """Test running a finance task."""
        task_id = self.agent.create_task("Get price of GOOG")
        result = self.agent.run_task(task_id)
        self.assertEqual(result["status"], "completed")
        self.assertIn("content", result["result"])
        self.assertIn("goog", result["result"]["content"].lower())
        self.assertIn("data", result["result"])
        self.assertIn("price", result["result"]["data"])


if __name__ == "__main__":
    unittest.main() 