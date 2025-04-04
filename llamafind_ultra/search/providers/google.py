"""
Google Search provider for LlamaFind Ultra.

This module provides search functionality using the Google Custom Search API.
"""

import logging
import time
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Union

import requests

from ..engine import SearchEngine, SearchQuery, SearchResult

logger = logging.getLogger("llamafind.search.google")

class GoogleSearch(SearchEngine):
    """Search engine implementation using Google Custom Search API.
    
    This class provides search capabilities via the Google Custom Search API.
    Documentation: https://developers.google.com/custom-search/v1/overview
    """
    
    def __init__(self, api_key: Optional[str] = None, config: Optional[Dict[str, Any]] = None):
        """Initialize the Google Search engine.
        
        Args:
            api_key: Google API key.
            config: Additional configuration for the search engine.
        """
        super().__init__(api_key, config)
        self.api_base = self.config.get("api_base", "https://customsearch.googleapis.com/customsearch/v1")
        self.cx = self.config.get("cx")  # Search engine ID
        
        if not self.cx:
            logger.warning("Google Custom Search requires a search engine ID (cx)")
    
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
            raise ValueError("Google Custom Search requires an API key")
        
        if not self.cx:
            raise ValueError("Google Custom Search requires a search engine ID (cx)")
        
        search_query = self._create_query(query)
        logger.info(f"Searching Google for: {search_query.query}")
        
        try:
            # Prepare request parameters
            params = {
                "q": search_query.query,
                "key": self.api_key,
                "cx": self.cx,
                "num": min(search_query.num_results, 10)  # Google only supports up to 10 results per request
            }
            
            # Add time period filter if specified
            if search_query.time_period:
                # Convert to Google's format
                if search_query.time_period == "day":
                    params["dateRestrict"] = "d1"
                elif search_query.time_period == "week":
                    params["dateRestrict"] = "w1"
                elif search_query.time_period == "month":
                    params["dateRestrict"] = "m1"
                elif search_query.time_period == "year":
                    params["dateRestrict"] = "y1"
            
            # Add domain filters if specified
            if search_query.include_domains:
                sites = " OR ".join([f"site:{domain}" for domain in search_query.include_domains])
                params["q"] = f"{params['q']} ({sites})"
            
            # Determine search type
            if search_query.search_type == "images":
                params["searchType"] = "image"
            elif search_query.search_type == "news":
                # Add news-specific query terms
                params["q"] = f"{params['q']} news"
            
            # Make the API request
            response = requests.get(
                self.api_base,
                params=params,
                timeout=10
            )
            
            # Check for errors
            response.raise_for_status()
            data = response.json()
            
            # Parse and return results
            return self._parse_results(data, search_query.search_type)
            
        except requests.RequestException as e:
            logger.error(f"Error searching Google: {e}")
            if hasattr(e, "response") and e.response is not None:
                logger.error(f"Response: {e.response.text}")
            raise RuntimeError(f"Error searching Google: {e}")
    
    def _parse_results(self, data: Dict[str, Any], search_type: str) -> List[SearchResult]:
        """Parse search results from the API response.
        
        Args:
            data: API response data.
            search_type: Type of search performed.
            
        Returns:
            List of search results.
        """
        results = []
        
        # Check if there are any items in the response
        if "items" not in data:
            logger.warning("No items found in Google Search response")
            return results
        
        # Parse each result
        for i, item in enumerate(data["items"]):
            try:
                # Common fields
                title = item.get("title", "")
                url = item.get("link", "")
                
                # Description depends on result type
                if search_type == "images":
                    snippet = item.get("image", {}).get("contextLink", "")
                else:
                    snippet = item.get("snippet", "")
                
                # Extract domain
                domain = self._get_domain_from_url(url)
                
                # Parse date if available
                published_date = None
                if "pagemap" in item:
                    pagemap = item["pagemap"]
                    if "metatags" in pagemap and pagemap["metatags"]:
                        metatags = pagemap["metatags"][0]
                        # Try to find a publication date in metatags
                        for key in ["article:published_time", "og:updated_time", "datePublished"]:
                            if key in metatags:
                                try:
                                    published_date = datetime.fromisoformat(metatags[key].replace("Z", "+00:00"))
                                    break
                                except (ValueError, TypeError):
                                    pass
                
                # Create result
                result = SearchResult(
                    title=title,
                    url=url,
                    snippet=snippet,
                    source="Google",
                    published_date=published_date,
                    domain=domain,
                    rank=i + 1,
                    metadata={
                        "display_link": item.get("displayLink", ""),
                        "file_format": item.get("fileFormat", ""),
                        "mime_type": item.get("mime", "")
                    }
                )
                
                results.append(result)
                
            except Exception as e:
                logger.error(f"Error parsing result {i}: {e}")
                continue
        
        return results 