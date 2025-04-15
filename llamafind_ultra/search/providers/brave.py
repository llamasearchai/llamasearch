"""
Brave Search provider for LlamaFind Ultra.

This module provides search functionality using the Brave Search API.
"""

import logging
import time
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Union

import requests

from ..engine import SearchEngine, SearchQuery, SearchResult

logger = logging.getLogger("llamafind.search.brave")


class BraveSearch(SearchEngine):
    """Search engine implementation using Brave Search API.

    This class provides search capabilities via the Brave Search API.
    Documentation: https://brave.com/search/api/
    """

    def __init__(
        self, api_key: Optional[str] = None, config: Optional[Dict[str, Any]] = None
    ):
        """Initialize the Brave Search engine.

        Args:
            api_key: Brave Search API key.
            config: Additional configuration for the search engine.
        """
        super().__init__(api_key, config)
        self.api_base = self.config.get(
            "api_base", "https://api.search.brave.com/res/v1"
        )

    def search(self, query: Union[str, SearchQuery]) -> List[SearchResult]:
        """Perform a search with the given query.

        Args:
            query: Search query text or SearchQuery object.

        Returns:
            List of search results.

        Raises:
            RuntimeError: If an error occurs during the search.
        """
        if not self.api_key:
            raise ValueError("Brave Search requires an API key")

        search_query = self._create_query(query)
        logger.info(f"Searching Brave for: {search_query.query}")

        try:
            # Prepare request parameters
            params = {"q": search_query.query, "count": search_query.num_results}

            # Add time period filter if specified
            if search_query.time_period:
                params["freshness"] = search_query.time_period

            # Add domain filters if specified
            if search_query.include_domains:
                params["site"] = " OR ".join(search_query.include_domains)

            # Determine endpoint based on search type
            endpoint = self.api_base
            if search_query.search_type == "news":
                params["news"] = "true"
            elif search_query.search_type == "images":
                endpoint = f"{self.api_base}/images"
            elif search_query.search_type == "videos":
                endpoint = f"{self.api_base}/videos"

            # Make the API request
            headers = {
                "Accept": "application/json",
                "X-Subscription-Token": self.api_key,
            }

            response = requests.get(
                endpoint, params=params, headers=headers, timeout=10
            )

            # Check for errors
            response.raise_for_status()
            data = response.json()

            # Parse and return results
            return self._parse_results(data, search_query.search_type)

        except requests.RequestException as e:
            logger.error(f"Error searching Brave: {e}")
            if hasattr(e, "response") and e.response is not None:
                logger.error(f"Response: {e.response.text}")
            raise RuntimeError(f"Error searching Brave: {e}")

    def _parse_results(
        self, data: Dict[str, Any], search_type: str
    ) -> List[SearchResult]:
        """Parse search results from the API response.

        Args:
            data: API response data.
            search_type: Type of search performed.

        Returns:
            List of search results.
        """
        results = []

        # Get the appropriate result list based on search type
        if search_type == "web" or search_type == "news":
            items = data.get("web", {}).get("results", [])
        elif search_type == "images":
            items = data.get("images", {}).get("results", [])
        elif search_type == "videos":
            items = data.get("videos", {}).get("results", [])
        else:
            items = data.get("web", {}).get("results", [])

        # Parse each result
        for i, item in enumerate(items):
            try:
                # Common fields
                title = item.get("title", "")
                url = item.get("url", "")

                # Description field depends on search type
                if search_type == "web" or search_type == "news":
                    description = item.get("description", "")
                elif search_type == "images":
                    description = item.get("alt", "")
                elif search_type == "videos":
                    description = item.get("description", "")
                else:
                    description = item.get("description", "")

                # Create result
                domain = self._get_domain_from_url(url)

                # Parse date if available
                published_date = None
                if "age" in item:
                    try:
                        # Convert relative age to timestamp (approximate)
                        age_str = item["age"]
                        if "minute" in age_str:
                            minutes = int(age_str.split()[0])
                            published_date = datetime.now().replace(
                                microsecond=0, second=0
                            ) - timedelta(minutes=minutes)
                        elif "hour" in age_str:
                            hours = int(age_str.split()[0])
                            published_date = datetime.now().replace(
                                microsecond=0, second=0, minute=0
                            ) - timedelta(hours=hours)
                        elif "day" in age_str:
                            days = int(age_str.split()[0])
                            published_date = datetime.now().replace(
                                microsecond=0, second=0, minute=0, hour=0
                            ) - timedelta(days=days)
                    except (ValueError, IndexError):
                        pass

                result = SearchResult(
                    title=title,
                    url=url,
                    snippet=description,
                    source="Brave",
                    published_date=published_date,
                    domain=domain,
                    rank=i + 1,
                    metadata={
                        "score": item.get("score", 0),
                        "family_friendly": item.get("family_friendly", True),
                        "language": item.get("language", ""),
                    },
                )

                results.append(result)

            except Exception as e:
                logger.error(f"Error parsing result {i}: {e}")
                continue

        return results
