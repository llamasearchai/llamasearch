"""
Search engine base classes for LlamaFind Ultra.

This module provides base classes for search functionality, including 
the SearchEngine abstract base class, SearchQuery for representing search queries,
and SearchResult for representing search results.
"""

import logging
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Optional, Union

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("llamafind.search")

@dataclass
class SearchQuery:
    """Representation of a search query.
    
    Attributes:
        query: The search query text.
        filters: Optional filters for the search.
        num_results: Number of results to return.
        include_domains: List of domains to include in search results.
        exclude_domains: List of domains to exclude from search results.
        time_period: Time period for search results (e.g., "day", "week", "month", "year").
        search_type: Type of search (e.g., "web", "news", "images").
    """
    
    query: str
    filters: Dict[str, Any] = field(default_factory=dict)
    num_results: int = 10
    include_domains: List[str] = field(default_factory=list)
    exclude_domains: List[str] = field(default_factory=list)
    time_period: Optional[str] = None
    search_type: str = "web"
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert the query to a dictionary.
        
        Returns:
            Dictionary representation of the query.
        """
        return {k: v for k, v in self.__dict__.items() if not k.startswith("_")}


@dataclass
class SearchResult:
    """Representation of a search result.
    
    Attributes:
        title: Title of the result.
        url: URL of the result.
        snippet: Text snippet or description of the result.
        source: Source of the result (search engine name).
        published_date: Publication date of the result, if available.
        domain: Domain of the result.
        rank: Rank of the result in the search results.
        metadata: Additional metadata about the result.
    """
    
    title: str
    url: str
    snippet: str
    source: str
    published_date: Optional[datetime] = None
    domain: Optional[str] = None
    rank: Optional[int] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert the result to a dictionary.
        
        Returns:
            Dictionary representation of the result.
        """
        result = {k: v for k, v in self.__dict__.items() if not k.startswith("_")}
        # Convert datetime to string
        if result.get("published_date"):
            result["published_date"] = result["published_date"].isoformat()
        return result


class SearchEngine(ABC):
    """Base class for search engines.
    
    This is an abstract base class that defines the interface for all search
    engines in LlamaFind Ultra. Concrete implementations should inherit from
    this class and implement its abstract methods.
    """
    
    def __init__(self, api_key: Optional[str] = None, config: Optional[Dict[str, Any]] = None):
        """Initialize the search engine.
        
        Args:
            api_key: API key for the search engine.
            config: Additional configuration for the search engine.
        """
        self.api_key = api_key
        self.config = config or {}
        self.name = self.__class__.__name__
        self.logger = logging.getLogger(f"llamafind.search.{self.name}")
        
        # Validate API key if needed
        if self._requires_api_key() and not api_key:
            self.logger.warning(f"{self.name} requires an API key, but none was provided")
    
    @abstractmethod
    def search(self, query: Union[str, SearchQuery]) -> List[SearchResult]:
        """Perform a search with the given query.
        
        Args:
            query: Search query text or SearchQuery object.
            
        Returns:
            List of search results.
        """
        pass
    
    def _requires_api_key(self) -> bool:
        """Check if this search engine requires an API key.
        
        Returns:
            True if an API key is required, False otherwise.
        """
        return True
    
    def _create_query(self, query: Union[str, SearchQuery]) -> SearchQuery:
        """Create a SearchQuery object from a string query if needed.
        
        Args:
            query: Search query text or SearchQuery object.
            
        Returns:
            SearchQuery object.
        """
        if isinstance(query, str):
            return SearchQuery(query=query)
        return query
    
    def _get_domain_from_url(self, url: str) -> str:
        """Extract the domain from a URL.
        
        Args:
            url: URL to extract domain from.
            
        Returns:
            Domain name.
        """
        try:
            from urllib.parse import urlparse
            return urlparse(url).netloc
        except Exception as e:
            self.logger.error(f"Error extracting domain from URL {url}: {e}")
            return "" 