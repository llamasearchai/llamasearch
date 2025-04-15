"""
Tests for the LlamaFind Ultra search providers.

This module provides tests for the search provider implementations
to ensure they function as expected.
"""

import json
import unittest
from datetime import datetime
from unittest.mock import MagicMock, patch

import requests

from llamafind_ultra.search.engine import SearchQuery, SearchResult
from llamafind_ultra.search.providers.brave import BraveSearch
from llamafind_ultra.search.providers.google import GoogleSearch
from llamafind_ultra.search.providers.perplexity import PerplexitySearch


class TestBraveSearch(unittest.TestCase):
    """Tests for the BraveSearch provider."""

    def setUp(self):
        """Set up test fixtures."""
        self.api_key = "test_api_key"
        self.search_provider = BraveSearch(api_key=self.api_key)

        # Sample Brave Search API response
        self.sample_response = {
            "web": {
                "results": [
                    {
                        "title": "Test Result 1",
                        "url": "https://example.com/1",
                        "description": "This is test result 1",
                        "language": "en",
                        "family_friendly": True,
                        "score": 1.0,
                        "age": "2 days ago",
                    },
                    {
                        "title": "Test Result 2",
                        "url": "https://example.com/2",
                        "description": "This is test result 2",
                        "language": "en",
                        "family_friendly": True,
                        "score": 0.9,
                    },
                ]
            }
        }

    @patch("requests.get")
    def test_search(self, mock_get):
        """Test the search method."""
        # Set up the mock response
        mock_response = MagicMock()
        mock_response.json.return_value = self.sample_response
        mock_response.raise_for_status = MagicMock()
        mock_get.return_value = mock_response

        # Perform search
        query = "test query"
        results = self.search_provider.search(query)

        # Verify request was made correctly
        mock_get.assert_called_once()
        call_args = mock_get.call_args[1]
        self.assertEqual(call_args["params"]["q"], query)
        self.assertEqual(call_args["headers"]["X-Subscription-Token"], self.api_key)

        # Verify results
        self.assertEqual(len(results), 2)
        self.assertEqual(results[0].title, "Test Result 1")
        self.assertEqual(results[0].url, "https://example.com/1")
        self.assertEqual(results[0].snippet, "This is test result 1")
        self.assertEqual(results[0].source, "Brave")
        self.assertEqual(results[0].domain, "example.com")

    @patch("requests.get")
    def test_search_with_error(self, mock_get):
        """Test error handling in the search method."""
        # Set up the mock to raise an exception
        mock_get.side_effect = requests.RequestException("Test error")

        # Verify exception handling
        with self.assertRaises(RuntimeError):
            self.search_provider.search("test query")


class TestGoogleSearch(unittest.TestCase):
    """Tests for the GoogleSearch provider."""

    def setUp(self):
        """Set up test fixtures."""
        self.api_key = "test_api_key"
        self.cx = "test_search_engine_id"
        self.config = {"cx": self.cx}
        self.search_provider = GoogleSearch(api_key=self.api_key, config=self.config)

        # Sample Google Search API response
        self.sample_response = {
            "items": [
                {
                    "title": "Test Result 1",
                    "link": "https://example.com/1",
                    "snippet": "This is test result 1",
                    "displayLink": "example.com",
                    "pagemap": {
                        "metatags": [{"article:published_time": "2023-01-01T12:00:00Z"}]
                    },
                },
                {
                    "title": "Test Result 2",
                    "link": "https://example.com/2",
                    "snippet": "This is test result 2",
                    "displayLink": "example.com",
                },
            ]
        }

    @patch("requests.get")
    def test_search(self, mock_get):
        """Test the search method."""
        # Set up the mock response
        mock_response = MagicMock()
        mock_response.json.return_value = self.sample_response
        mock_response.raise_for_status = MagicMock()
        mock_get.return_value = mock_response

        # Perform search
        query = "test query"
        results = self.search_provider.search(query)

        # Verify request was made correctly
        mock_get.assert_called_once()
        call_args = mock_get.call_args[1]
        self.assertEqual(call_args["params"]["q"], query)
        self.assertEqual(call_args["params"]["key"], self.api_key)
        self.assertEqual(call_args["params"]["cx"], self.cx)

        # Verify results
        self.assertEqual(len(results), 2)
        self.assertEqual(results[0].title, "Test Result 1")
        self.assertEqual(results[0].url, "https://example.com/1")
        self.assertEqual(results[0].snippet, "This is test result 1")
        self.assertEqual(results[0].source, "Google")
        self.assertEqual(results[0].domain, "example.com")

        # Verify date parsing
        self.assertIsInstance(results[0].published_date, datetime)

    @patch("requests.get")
    def test_search_with_error(self, mock_get):
        """Test error handling in the search method."""
        # Set up the mock to raise an exception
        mock_get.side_effect = requests.RequestException("Test error")

        # Verify exception handling
        with self.assertRaises(RuntimeError):
            self.search_provider.search("test query")


class TestPerplexitySearch(unittest.TestCase):
    """Tests for the PerplexitySearch provider."""

    def setUp(self):
        """Set up test fixtures."""
        self.api_key = "test_api_key"
        self.search_provider = PerplexitySearch(api_key=self.api_key)

        # Sample Perplexity Search API response
        self.sample_response = {
            "results": [
                {
                    "title": "Test Result 1",
                    "url": "https://example.com/1",
                    "snippet": "This is test result 1",
                    "created_at": "2023-01-01T12:00:00Z",
                    "highlights": ["test", "result"],
                },
                {
                    "title": "Test Result 2",
                    "url": "https://example.com/2",
                    "snippet": "This is test result 2",
                    "created_at": "2023-02-15",
                },
            ]
        }

    @patch("requests.post")
    def test_search(self, mock_post):
        """Test the search method."""
        # Set up the mock response
        mock_response = MagicMock()
        mock_response.json.return_value = self.sample_response
        mock_response.raise_for_status = MagicMock()
        mock_post.return_value = mock_response

        # Perform search
        query = "test query"
        results = self.search_provider.search(query)

        # Verify request was made correctly
        mock_post.assert_called_once()
        call_args = mock_post.call_args[1]
        self.assertEqual(call_args["json"]["query"], query)
        self.assertEqual(
            call_args["headers"]["Authorization"], f"Bearer {self.api_key}"
        )

        # Verify results
        self.assertEqual(len(results), 2)
        self.assertEqual(results[0].title, "Test Result 1")
        self.assertEqual(results[0].url, "https://example.com/1")
        self.assertEqual(results[0].snippet, "This is test result 1")
        self.assertEqual(results[0].source, "Perplexity")
        self.assertEqual(results[0].domain, "example.com")

        # Verify date parsing
        self.assertIsInstance(results[0].published_date, datetime)

    @patch("requests.post")
    def test_search_with_error(self, mock_post):
        """Test error handling in the search method."""
        # Set up the mock to raise an exception
        mock_post.side_effect = requests.RequestException("Test error")

        # Verify exception handling
        with self.assertRaises(RuntimeError):
            self.search_provider.search("test query")


if __name__ == "__main__":
    unittest.main()
