"""
Perplexity Search provider for LlamaFind Ultra.

This module provides search functionality using the Perplexity API.
"""

import logging
import time
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Union

import requests

from ..engine import SearchEngine, SearchQuery, SearchResult

logger = logging.getLogger("llamafind.search.perplexity")

class PerplexitySearch(SearchEngine):
    """Search engine implementation using Perplexity API.
    
    This class provides search capabilities via the Perplexity API.
    Documentation: https://docs.perplexity.ai/
    """
    
    def __init__(self, api_key: Optional[str] = None, config: Optional[Dict[str, Any]] = None):
        """Initialize the Perplexity Search engine.
        
        Args:
            api_key: Perplexity API key.
            config: Additional configuration for the search engine.
        """
        super().__init__(api_key, config)
        self.api_base = self.config.get("api_base", "https://api.perplexity.ai")
        
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
            raise ValueError("Perplexity Search requires an API key")
        
        search_query = self._create_query(query)
        logger.info(f"Searching Perplexity for: {search_query.query}")
        
        try:
            # Determine which endpoint to use based on search type
            endpoint = f"{self.api_base}/search"
            
            # Prepare request parameters
            headers = {
                "Accept": "application/json",
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.api_key}"
            }
            
            # Prepare request data
            data = {
                "query": search_query.query,
                "max_results": search_query.num_results
            }
            
            # Add search options based on query parameters
            if search_query.search_type == "web":
                data["search_mode"] = "web_search"
            elif search_query.search_type == "images":
                data["search_mode"] = "image_search"  
            elif search_query.search_type == "news":
                data["search_mode"] = "news_search"
            
            # Add time filter if specified
            if search_query.time_period:
                if search_query.time_period == "day":
                    data["time_range"] = "day"
                elif search_query.time_period == "week":
                    data["time_range"] = "week"
                elif search_query.time_period == "month":
                    data["time_range"] = "month"
                elif search_query.time_period == "year":
                    data["time_range"] = "year"
            
            # Make the API request
            response = requests.post(
                endpoint,
                headers=headers,
                json=data,
                timeout=30  # Longer timeout as Perplexity can take time
            )
            
            # Check for errors
            response.raise_for_status()
            data = response.json()
            
            # Parse and return results
            return self._parse_results(data, search_query.search_type)
            
        except requests.RequestException as e:
            logger.error(f"Error searching Perplexity: {e}")
            if hasattr(e, "response") and e.response is not None:
                logger.error(f"Response: {e.response.text}")
            raise RuntimeError(f"Error searching Perplexity: {e}")
    
    def _parse_results(self, data: Dict[str, Any], search_type: str) -> List[SearchResult]:
        """Parse search results from the API response.
        
        Args:
            data: API response data.
            search_type: Type of search performed.
            
        Returns:
            List of search results.
        """
        results = []
        
        # Check if there are any results
        if "results" not in data or not data["results"]:
            logger.warning("No results found in Perplexity response")
            return results
        
        # Process each result
        for i, item in enumerate(data["results"]):
            try:
                # Extract common fields
                title = item.get("title", "")
                url = item.get("url", "")
                snippet = item.get("snippet", "")
                
                # Extract domain from URL
                domain = self._get_domain_from_url(url)
                
                # Create result
                result = SearchResult(
                    title=title,
                    url=url,
                    snippet=snippet,
                    source="Perplexity",
                    domain=domain,
                    rank=i + 1,
                    metadata={
                        "highlights": item.get("highlights", []),
                        "created_at": item.get("created_at")
                    }
                )
                
                # Try to parse publication date if available
                if "created_at" in item and item["created_at"]:
                    try:
                        # Attempt to parse the date in various formats
                        date_str = item["created_at"]
                        try:
                            # Try ISO format
                            published_date = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
                        except ValueError:
                            # Try other common formats
                            for fmt in ["%Y-%m-%d", "%Y/%m/%d", "%b %d, %Y"]:
                                try:
                                    published_date = datetime.strptime(date_str, fmt)
                                    break
                                except ValueError:
                                    continue
                            else:
                                published_date = None
                        
                        if published_date:
                            result.published_date = published_date
                    except Exception as date_error:
                        logger.warning(f"Error parsing date: {date_error}")
                
                results.append(result)
                
            except Exception as e:
                logger.error(f"Error parsing result {i}: {e}")
                continue
                
        return results
    
    def _requires_api_key(self) -> bool:
        """Check if this search engine requires an API key.
        
        Returns:
            True since Perplexity always requires an API key.
        """
        return True 