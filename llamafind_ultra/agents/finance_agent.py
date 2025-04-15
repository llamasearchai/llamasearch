"""
Finance agent for LlamaFind Ultra.

This module provides the FinanceAgent class, which handles financial information
and analysis tasks.
"""

import logging
import random
import re
import time
from typing import Any, Dict, List, Optional, Tuple, Union

from ..core.model import Model
from .base import Agent, AgentConfig, AgentMessage, AgentResponse

logger = logging.getLogger("llamafind.agents.finance")


class FinanceAgent(Agent):
    """Agent for handling financial information and analysis.

    This agent can provide stock information, financial analysis,
    and other financial data.
    """

    def __init__(
        self, config: Union[Dict[str, Any], AgentConfig], model: Optional[Model] = None
    ):
        """Initialize the finance agent.

        Args:
            config: Agent configuration.
            model: Model to use for financial analysis. If None, a model will be
                loaded based on the configuration if needed.
        """
        # Set default agent type if not provided
        if isinstance(config, dict) and "agent_type" not in config:
            config["agent_type"] = "finance"
        elif isinstance(config, AgentConfig) and config.agent_type == "base":
            config.agent_type = "finance"

        super().__init__(config, model)

        # Add default capabilities if not provided
        if not self.config.capabilities:
            self.config.capabilities = [
                "get_stock_info",
                "get_stock_price",
                "get_stock_change",
            ]

        # Initialize API clients if available
        self._initialize_api_clients()

        # Initialize tasks storage
        self.tasks = {}

        # Cache for mock stock data
        self.stock_cache = {}

    def process_message(self, message: Union[str, AgentMessage]) -> AgentResponse:
        """Process a message and generate a finance-related response.

        Args:
            message: Message to process.

        Returns:
            Agent response.
        """
        # Create message object if needed
        message_obj = self._create_message(message)
        self._add_to_history(message_obj)

        logger.info(f"Processing finance message: {message_obj.content}")

        try:
            # Extract ticker symbols and financial request type
            query = message_obj.content
            ticker, request_type = self._parse_finance_query(query)

            if ticker and request_type:
                response_content = self._handle_finance_request(ticker, request_type)
            else:
                response_content = (
                    "I'm a finance agent that can provide stock information. "
                    "Please ask me about a specific stock using its ticker symbol. "
                    "For example: 'What's the current price of AAPL?' or 'Tell me about MSFT stock.'"
                )

            # Create and return response
            response = self._create_response(response_content, message_obj)
            self._add_to_history(response)

            return response

        except Exception as e:
            logger.error(f"Error processing finance message: {e}")
            error_response = self._create_response(
                f"Sorry, I encountered an error while processing your finance query: {str(e)}",
                message_obj,
            )
            self._add_to_history(error_response)
            return error_response

    def create_task(self, description: str) -> str:
        """Create a finance task.

        Args:
            description: Description of the finance task.

        Returns:
            Task ID.
        """
        logger.info(f"Creating finance task: {description}")

        # Create a task ID
        task_id = f"finance_task_{int(time.time())}_{len(self.tasks)}"

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
        """Run a finance task.

        Args:
            task_id: ID of the task to run.

        Returns:
            Task result.

        Raises:
            ValueError: If the task is not found.
        """
        logger.info(f"Running finance task: {task_id}")

        # Check if task exists
        if task_id not in self.tasks:
            raise ValueError(f"Task not found: {task_id}")

        # Get the task
        task = self.tasks[task_id]

        # Update task status
        task["status"] = "running"
        task["updated_at"] = time.time()

        try:
            # Parse the finance task
            description = task["description"]
            ticker, request_type = self._parse_finance_query(description)

            if ticker and request_type:
                # Get the financial information
                response_content = self._handle_finance_request(ticker, request_type)

                # Parse the numeric data if available
                price, change, change_percent = self._extract_financial_data(
                    response_content
                )

                # Update task with results
                task["result"] = {
                    "content": response_content,
                    "timestamp": time.time(),
                    "ticker": ticker,
                    "data": {
                        "price": price,
                        "change": change,
                        "change_percent": change_percent,
                    },
                }
            else:
                task["result"] = {
                    "content": "Could not parse a valid financial query from the task description.",
                    "timestamp": time.time(),
                }

            task["status"] = "completed"

        except Exception as e:
            logger.error(f"Error running finance task {task_id}: {e}")
            task["status"] = "failed"
            task["error"] = str(e)

        # Update task timestamp
        task["updated_at"] = time.time()

        return task

    def _initialize_api_clients(self) -> None:
        """Initialize API clients for financial data sources."""
        # This would normally initialize real financial API clients,
        # but we'll use mock data for this implementation
        logger.info("Initializing finance API clients (mock)")
        self.has_api_access = True

    def _parse_finance_query(self, query: str) -> Tuple[Optional[str], Optional[str]]:
        """Parse a financial query to extract the ticker symbol and request type.

        Args:
            query: The user's query.

        Returns:
            Tuple of (ticker, request_type) if found, or (None, None).
        """
        # Extract ticker symbol (usually 1-5 uppercase letters)
        ticker_match = re.search(r"\b([A-Z]{1,5})\b", query)
        ticker = ticker_match.group(1) if ticker_match else None

        # Determine request type
        request_type = None
        if ticker:
            if re.search(r"price|cost|worth|value", query, re.IGNORECASE):
                request_type = "price"
            elif re.search(
                r"change|movement|up|down|increase|decrease", query, re.IGNORECASE
            ):
                request_type = "change"
            else:
                request_type = "info"  # Default to general info

        return ticker, request_type

    def _handle_finance_request(self, ticker: str, request_type: str) -> str:
        """Handle a finance request for a specific ticker and request type.

        Args:
            ticker: Stock ticker symbol.
            request_type: Type of request (price, change, info).

        Returns:
            Response string with the requested information.
        """
        # Get the stock data (mock data for this implementation)
        stock_data = self._get_stock_data(ticker)

        if request_type == "price":
            return f"The current price of {ticker} is ${stock_data['price']:.2f}."

        elif request_type == "change":
            if stock_data["change"] >= 0:
                direction = "up"
            else:
                direction = "down"

            return (
                f"{ticker} is {direction} ${abs(stock_data['change']):.2f} "
                f"({stock_data['change_percent']:.2f}%) today."
            )

        else:  # General info
            if stock_data["change"] >= 0:
                direction = "up"
            else:
                direction = "down"

            return (
                f"{ticker} is currently trading at ${stock_data['price']:.2f}, "
                f"{direction} ${abs(stock_data['change']):.2f} "
                f"({stock_data['change_percent']:.2f}%) from the previous close. "
                f"The trading volume is {stock_data['volume']:,}."
            )

    def _get_stock_data(self, ticker: str) -> Dict[str, float]:
        """Get stock data for a given ticker.

        Args:
            ticker: Stock ticker symbol.

        Returns:
            Dictionary with stock data.
        """
        # Check cache first
        if ticker in self.stock_cache:
            return self.stock_cache[ticker]

        # Generate mock data for demonstration purposes
        # In a real implementation, this would call a financial API
        base_price = hash(ticker) % 1000  # Deterministic base price based on ticker
        if base_price < 10:
            base_price += 10  # Ensure minimum price of $10

        # Add some randomness
        price = base_price + random.uniform(-5, 5)
        if price < 1:
            price = random.uniform(1, 10)  # Ensure positive price

        # Generate other metrics
        prev_close = price * random.uniform(0.9, 1.1)
        change = price - prev_close
        change_percent = (change / prev_close) * 100
        volume = random.randint(100000, 10000000)

        # Store in cache
        stock_data = {
            "price": price,
            "prev_close": prev_close,
            "change": change,
            "change_percent": change_percent,
            "volume": volume,
            "ticker": ticker,
        }
        self.stock_cache[ticker] = stock_data

        return stock_data

    def _extract_financial_data(
        self, response: str
    ) -> Tuple[Optional[float], Optional[float], Optional[float]]:
        """Extract financial data from a response string.

        Args:
            response: Response string containing financial information.

        Returns:
            Tuple of (price, change, change_percent) if available, or None values.
        """
        price = None
        change = None
        change_percent = None

        # Extract price
        price_match = re.search(r"\$(\d+\.\d+)", response)
        if price_match:
            try:
                price = float(price_match.group(1))
            except ValueError:
                pass

        # Extract change
        change_match = re.search(r"up|down\s+\$(\d+\.\d+)", response)
        if change_match:
            try:
                change_value = float(change_match.group(1))
                if "down" in response:
                    change = -change_value
                else:
                    change = change_value
            except ValueError:
                pass

        # Extract change percent
        percent_match = re.search(r"\((\d+\.\d+)%\)", response)
        if percent_match:
            try:
                change_percent = float(percent_match.group(1))
                if change and change < 0:
                    change_percent = -change_percent
            except ValueError:
                pass

        return price, change, change_percent
