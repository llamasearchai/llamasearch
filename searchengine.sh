Okay, here is the complete, final, ultimate program plan and coding prompt for the LlamaFind web search engine, designed to avoid the use of Langchain.

I. Project Setup and Structure (as previously defined, including setup and configuration files)

llamafind/
├── llamafind/
│   ├── core/
│   │   ├── engine.py
│   │   └── __init__.py
│   ├── search_engines/
│   │   ├── google.py
│   │   ├── bing.py
│   │   ├── duckduckgo.py
│   │   ├── yahoo.py
│   │   ├── baidu.py
│   │   ├── ecosia.py
│   │   ├── givewater.py
│   │   ├── pinterest.py
│   │   └── __init__.py
│   ├── scraping/
│   │   ├── scraper.py
│   │   └── __init__.py
│   ├── data_models.py
│   ├── llm/
│   │   ├── llm_interface.py
│   │   └── __init__.py
├── llamafind.toml
├── setup.cfg
├── pyproject.toml
├── LICENSE
└── README.md
└── tests/
    ├── __init__.py
    ├── test_core_engine.py
    ├── test_google_search.py
    ├── test_bing_search.py
    ├── test_duckduckgo_search.py
    ├── test_yahoo_search.py
    ├── test_baidu_search.py
    ├── test_ecosia_search.py
    ├── test_givewater_search.py
    ├── test_pinterest_search.py
    ├── test_scraper.py
    ├── test_data_models.py
    ├── test_proxy_manager.py
    ├── test_anti_bot.py
    └── ... (Other Engine Tests)
content_copy
download
Use code with caution.

II. Data Models:

(1) llamafind/data_models.py

from typing import List, Optional
from pydantic import BaseModel, Field

# Search Result Data Model
class SearchResult(BaseModel):
    """
    Represents a single search result from a search engine.

    Attributes:
        title (str): The title of the search result.
        url (str): The URL of the search result.
        snippet (str): A brief description or snippet of the search result.
        engine (str): The name of the search engine (e.g., "google", "bing").
        image_url (Optional[str]): URL of an image associated with the result, if available.
        raw_data (dict): Original data scraped.
    """
    title: str
    url: str
    snippet: str
    engine: str
    image_url: Optional[str] = None
    raw_data: dict = {}

# Scrape Result Data Model
class ScrapeResult(BaseModel):
    """
    Represents the result of scraping a web page.

    Attributes:
        url (str): The URL of the scraped page.
        text_content (str): The extracted text content of the page.
        links (List[str]): List of all extracted links on the page.
        image_urls (List[str]): List of extracted image URLs.
        tables (List[str]): Raw HTML of extracted tables.
        metadata (Dict): Dictionary containing metadata about the scraped page.
    """
    url: str
    text_content: str
    links: list[str]
    image_urls: list[str]
    tables: list[str] # raw html for tables
    metadata: dict = {}


# Proxy Data Model
class Proxy(BaseModel):
    """
    Represents a proxy server.

    Attributes:
        ip_address (str): The IP address or domain name of the proxy.
        port (int): The port number of the proxy.
        protocol (str):  Protocol (e.g., "http", "https", "socks4", "socks5").
        username (Optional[str]): Username for proxy authentication.
        password (Optional[str]): Password for proxy authentication.
        anonymity (str): "transparent", "anonymous", or "elite".
        latency (float): Measured response time, in seconds (optional).
        country (str): Country code (e.g., "US") (optional).
    """
    ip_address: str
    port: int
    protocol: str
    username: Optional[str] = None
    password: Optional[str] = None
    anonymity: str
    latency: Optional[float] = None
    country: Optional[str] = None
content_copy
download
Use code with caution.
Python

III. llamafind/core/engine.py (LlamaFind Core Engine)

import asyncio
import logging
import toml  # For configuration file parsing
from typing import List, Dict, Tuple, Optional
from llamafind.search_engines import (
    google_search,
    bing_search,
    duckduckgo_search,
    yahoo_search,
    baidu_search,
    ecosia_search,
    givewater_search,
    pinterest_search,
)
from llamafind.scraping import scraper
from llamafind.data_models import SearchResult, Proxy, ScrapeResult  # Import Data models
from llamafind.llm.llm_interface import LLMInterface  # Placeholder for MLX LLM Integration
from urllib.parse import urlparse
import re

logger = logging.getLogger(__name__)


# Add logging statements at start of class and each function
class LlamaFindEngine:

    def __init__(self, config_path: str = "llamafind.toml"):
        """
        Initialize the LlamaFindEngine.

        Args:
            config_path (str): Path to the configuration file (default: "llamafind.toml").
        """
        logger.info(f"Initializing LlamaFindEngine with configuration from {config_path}")
        self.config = self._load_config(config_path)
        self.search_engines = self._load_search_engines()
        self.proxy_manager = self._load_proxy_manager()
        self.llm = self._load_llm()  # Load your LLM here.
        logger.debug("Engine Initialized Successfully")

    def _load_config(self, config_path: str) -> dict:
        """Load configuration from a TOML file."""
        try:
            with open(config_path, "r") as f:
                config = toml.load(f)
                logger.debug(f"Configuration loaded from {config_path}: {config}")
                return config
        except FileNotFoundError:
            logger.error(f"Configuration file not found: {config_path}. Using default configurations.")
            return {}  # or use default configurations
        except toml.TomlDecodeError as e:
            logger.error(f"Error decoding configuration file {config_path}: {e}. Using default configurations.")
            return {}

    def _load_search_engines(self) -> Dict[str, callable]:
        """Loads the search engines based on the configuration."""
        engines = {}
        configured_engines = self.config.get("default_search_engines", [])
        if not configured_engines:
            configured_engines = ["google", "duckduckgo", "bing"]  # Default engines if none are configured
            logger.warning(f"No search engines configured in llamafind.toml, using defaults: {configured_engines}")
        for engine_name in configured_engines:
            if engine_name == "google":
                engines["google"] = google_search
            elif engine_name == "bing":
                engines["bing"] = bing_search
            elif engine_name == "duckduckgo":
                engines["duckduckgo"] = duckduckgo_search
            elif engine_name == "yahoo":
                engines["yahoo"] = yahoo_search
            elif engine_name == "baidu":
                engines["baidu"] = baidu_search
            elif engine_name == "ecosia":
                engines["ecosia"] = ecosia_search
            elif engine_name == "givewater":
                engines["givewater"] = givewater_search
            elif engine_name == "pinterest":
                engines["pinterest"] = pinterest_search
            else:
                logger.warning(f"Search engine '{engine_name}' is not supported. Skipping it.")
        if not engines:
            logger.error("No valid search engines configured. Cannot search.")
        return engines

    def _load_proxy_manager(self) -> Optional[Dict[str, Any]]:
        """Loads and configures the proxy manager, returns proxy dictionary for each search"""
        proxy_config = self.config.get("proxy", {})
        proxy_source = proxy_config.get("source")
        proxy = None  # Placeholder, initialize actual implementation in Phase 2

        if proxy_source == "file":
            file_path = proxy_config.get("file_path")
            if file_path:
                try:
                    with open(file_path, "r") as f:
                        proxy_list = [line.strip() for line in f if line.strip()]
                    # Basic proxy format validation (IP:PORT:USERNAME:PASSWORD)
                    validated_proxies = []
                    for proxy_str in proxy_list:
                        if ":" in proxy_str:
                            parts = proxy_str.split(":")
                            if 2 <= len(parts) <= 4:  # Basic check. Handle SOCKS later
                                validated_proxies.append(proxy_str)
                            else:
                                logger.warning(f"Invalid proxy format: {proxy_str}. Skipping.")
                    if validated_proxies:
                        proxy = {"proxies": validated_proxies}
                        logger.debug(f"Loaded {len(validated_proxies)} proxies from {file_path}")
                    else:
                        logger.warning(f"No valid proxies found in {file_path}")
                except FileNotFoundError:
                    logger.warning(f"Proxy file not found: {file_path}")
                except Exception as e:
                    logger.error(f"Error loading proxies from {file_path}: {e}")
            else:
                logger.warning("File path not specified in proxy configuration, not using proxies.")
        elif proxy_source == "api":
            api_url = proxy_config.get("api_url")
            api_key = proxy_config.get("api_key")
            # implement api fetching and parsing for Phase 2
            if api_url and api_key:
                proxy = {"api_url": api_url, "api_key": api_key}
                logger.debug(f"Proxy loaded from api_url: {api_url}")
            else:
                logger.warning("API URL or API key not specified for proxy, not using proxies")
        else:
            logger.warning("No proxy source provided.  Running without proxies.")

        return proxy

    def _load_llm(self) -> Optional[LLMInterface]:
        """Loads and configures the LLM, returns LLM Interface"""
        llm_config = self.config.get("llm", {})
        provider = llm_config.get("provider")
        model = llm_config.get("model")
        api_key = llm_config.get("api_key")
        if not (provider and model and api_key):
            logger.warning("No LLM is configured. LLM features will be disabled.")
            return None

        # Initialize your MLX LLM and return the appropriate instance
        # Replace this with your actual LLM initialization logic.

        llm_interface = LLMInterface(provider=provider, model=model, api_key=api_key, llm_config=llm_config)
        logger.debug(f"Loaded LLM interface: {provider}/{model}")
        return llm_interface

    async def search(self, query: str, num_results: int = 10) -> List[SearchResult]:
        """
        Performs a web search across multiple search engines.

        Args:
            query (str): The search query.
            num_results (int): The number of results to retrieve per search engine (default: 10).

        Returns:
            List[SearchResult]: A list of search results.
        """
        logger.info(f"Searching for: '{query}' across multiple search engines (Results per engine: {num_results})")
        all_results: List[SearchResult] = []
        if not self.search_engines:
            logger.error("No search engines are loaded. Returning empty results.")
            return []

        for engine_name, search_function in self.search_engines.items():
            logger.debug(f"Searching with {engine_name}")
            try:
                results = await search_function(query, num_results, self.proxy_manager)  # Pass proxy manager
                for result in results:
                    result.engine = engine_name
                all_results.extend(results)
                logger.debug(f"Found {len(results)} results for {engine_name}")
            except Exception as e:
                logger.error(f"Error searching with {engine_name}: {e}")

        # LLM-based query refinement (Phase 3)
        if self.llm:
            try:
                refined_query = await self.llm.refine_query(query, all_results)
                if refined_query != query:
                    logger.info(f"Query Refined from '{query}' to '{refined_query}'")
                    # Call search functions again for each engine with the refined query
                    refined_results: List[SearchResult] = []
                    for engine_name, search_function in self.search_engines.items():
                        try:
                            results = await search_function(refined_query, num_results, self.proxy_manager)
                            for result in results:
                                result.engine = engine_name
                            refined_results.extend(results)
                        except Exception as e:
                            logger.error(f"Error searching with refined query with {engine_name}: {e}")
                    all_results = refined_results

            except Exception as e:
                logger.error(f"Error refining query: {e}")

        # Result summarization (Phase 3) - basic summarization: to be defined at a later stage.
        if self.llm:
            try:
                all_results = await self.llm.summarize_results(all_results, query)
            except Exception as e:
                logger.error(f"Error summarization for results: {e}")

        return all_results

    async def scrape_page(self, url: str, dynamic: bool = False) -> ScrapeResult:
        """
        Scrapes a web page, extracting text, links, images, and tables.

        Args:
            url (str): The URL of the page to scrape.
            dynamic (bool): Whether to render dynamic content using Playwright (default: False).

        Returns:
            ScrapeResult: The scraped data.
        """
        logger.info(f"Scraping page: '{url}'")
        try:
            # Initialize scraper based on scraping engine and proxy config
            if dynamic:
                s = scraper.SeleniumScraper(user_agent=scraper.get_random_user_agent())
            else:
                s = scraper.WebScraper(
                    user_agent=scraper.get_random_user_agent(),
                    proxies=self.proxy_manager
                    if self.proxy_manager
                    else {},  # Pass proxy manager, which needs to be updated
                )

            if dynamic:
                raw_html = s.fetch_page(url) #Selenium scraper
                if raw_html is None:
                    return ScrapeResult(url=url, text_content="", links=[], image_urls=[], tables=[], metadata={"error": "Failed to fetch dynamic content"})
                soup = s.get_soup(url) #bs4 scraper
            else:
                # use requests scraper
                try:
                    raw_html = s.fetch_page(url)
                    if raw_html is None:
                        return ScrapeResult(url=url, text_content="", links=[], image_urls=[], tables=[], metadata={"error": "Failed to fetch static content"})
                except Exception as e:
                    return ScrapeResult(url=url, text_content="", links=[], image_urls=[], tables=[], metadata={"error": f"Failed to fetch content: {e}"})

                soup = s.get_soup(url)
                if not soup:
                    return ScrapeResult(url=url, text_content="", links=[], image_urls=[], tables=[], metadata={"error": "Failed to parse content with BeautifulSoup4"})

            text_content = s.get_text(url)
            links = s.get_links(url)
            image_urls = s.get_images(url)
            tables = s.get_tables(url)
            return ScrapeResult(
                url=url,
                text_content=text_content,
                links=links,
                image_urls=image_urls,
                tables=tables,
                metadata={},  # Placeholder for metadata from other scraping engines
            )
        except Exception as e:
            logger.error(f"Error scraping {url}: {e}")
            return ScrapeResult(url=url, text_content="", links=[], image_urls=[], tables=[], metadata={"error": f"Scraping failed: {e}"})
content_copy
download
Use code with caution.
Python

(6) llamafind/search_engines/__init__.py (Search Engine Initialization)

# Placeholder - No code needed here.
content_copy
download
Use code with caution.
Python

(7) llamafind/search_engines/google.py (Google Search)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def google_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Google search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Google for '{query}' (Results: {num_results})")
    base_url = "https://www.google.com/search"
    params = {"q": query, "num": num_results}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        proxy_manager.get_proxy()
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="g"):
            title_element = result.find("h3")
            link_element = result.find("a")
            snippet_element = result.find("span", class_="st")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="google")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Google search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(8) llamafind/search_engines/bing.py (Bing Search - Repeat structure as google.py)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def bing_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Bing search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Bing for '{query}' (Results: {num_results})")
    base_url = "https://www.bing.com/search"
    params = {"q": query, "count": num_results}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("li", class_="b_algo"):
            title_element = result.find("h2")
            link_element = result.find("a")
            snippet_element = result.find("p")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="bing")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Bing search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(9) llamafind/search_engines/duckduckgo.py (DuckDuckGo Search - Repeat structure as google.py)(10) llamafind/search_engines/yahoo.py (Yahoo Search - Repeat structure as google.py)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def yahoo_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Yahoo search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Yahoo for '{query}' (Results: {num_results})")
    base_url = "https://search.yahoo.com/search"
    params = {"q": query, "n": num_results} # 'n' used instead of num.

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="NewsArticle"): #Updated for yahoo
            title_element = result.find("h3", class_="title")
            link_element = result.find("a", class_="thmb")
            snippet_element = result.find("p", class_="txt")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="yahoo")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Yahoo search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(11) llamafind/search_engines/baidu.py (Baidu Search - Repeat structure as google.py)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def baidu_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Baidu search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Baidu for '{query}' (Results: {num_results})")
    base_url = "https://www.baidu.com/s"
    params = {"wd": query, "rn": num_results} # Use 'rn' instead of num

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="result c-container"):
            title_element = result.find("h3", class_="t")
            link_element = result.find("a")  # Usually the first a tag inside
            snippet_element = result.find("div", class_="c-abstract")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="baidu")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Baidu search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(12) llamafind/search_engines/ecosia.py (Ecosia Search - Repeat structure as google.py)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def ecosia_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs an Ecosia search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Ecosia for '{query}' (Results: {num_results})")
    base_url = "https://www.ecosia.org/search"
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="results-list-container"):
            title_element = result.find("a", class_="result__title-link")
            link_element = result.find("a", class_="result__url")
            snippet_element = result.find("p", class_="result__snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="ecosia")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Ecosia search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(13) llamafind/search_engines/givewater.py (GiveWater Search - Repeat structure as google.py)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def givewater_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a GiveWater search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching GiveWater for '{query}' (Results: {num_results})")
    base_url = "https://search.givewater.com/serp"
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="web-bing__result"):
            title_element = result.find("a")
            link_element = result.find("a")
            snippet_element = result.find("p", class_="b_snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="givewater")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing GiveWater search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(14) llamafind/search_engines/pinterest.py (Pinterest Search - Repeat structure as google.py)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def pinterest_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Pinterest search for the given query.
    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Pinterest for '{query}' (Results: {num_results})")
    base_url = "https://www.pinterest.com/search/pins/" # The base url has been added to the method.
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "X-Requested-With": "XMLHttpRequest",
        "Accept": "application/json",
        # Adding Accept-Language Header
        "Accept-Language": "en-US,en;q=0.9"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("a", class_="thmb"): #Updated for pinterest
            title_element = result.find("img") #Updated for pinterest
            link_element = result.find("a")
            if title_element and link_element:
                title = title_element.get("alt") # Get text from the alt attribute
                url = link_element.get("href")
                results.append(
                    SearchResult(title=title, url=url, engine="pinterest")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Pinterest search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

NOTE: Each search engine module will be implemented in a similar pattern. The main difference is the URL, the parameters, and the parsing logic used.

(15) llamafind/proxy/proxy_manager.py (Proxy Manager)

import asyncio
import logging
import random
from typing import List, Optional, Dict, Any
from llamafind.data_models import Proxy
from llamafind.scraping import scraper

logger = logging.getLogger(__name__)


class ProxyManager:
    """
    Manages a list of proxies and provides proxy selection based on configuration.
    """
    def __init__(self, config: Dict[str, Any]):
        """
        Initializes the ProxyManager.

        Args:
            config (Dict): Configuration dictionary (e.g., from `llamafind.toml`).
        """
        self.config = config
        self.proxies: List[Proxy] = []
        self.load_proxies()

    def load_proxies(self):
        """
        Loads proxies from the configured source.  Supports 'file' and 'api' sources.
        """
        proxy_config = self.config.get("proxy", {})
        proxy_source = proxy_config.get("source")
        if not proxy_source:
            logger.info("No proxy source specified in config. Running without proxies.")
            return

        if proxy_source == "file":
            file_path = proxy_config.get("file_path")
            if not file_path:
                logger.warning("File path not specified for proxy source 'file'.")
                return
            try:
                with open(file_path, "r") as f:
                    proxy_list = [line.strip() for line in f if line.strip()]
                # Validate basic proxy format
                validated_proxies: List[Proxy] = []
                for proxy_str in proxy_list:
                    if ":" in proxy_str:
                        parts = proxy_str.split(":")
                        if 2 <= len(parts) <= 4:  # Basic check. Handle SOCKS later
                            # Create Proxy objects
                            try:
                                proxy_obj = self._parse_proxy(proxy_str)
                                validated_proxies.append(proxy_obj)
                            except Exception as e:
                                logger.error(f"Error while parsing proxy: {proxy_str}, {e}. Skipping.")
                        else:
                            logger.warning(f"Invalid proxy format: {proxy_str}. Skipping.")
                    else:
                        logger.warning(f"Invalid proxy format: {proxy_str}. Skipping.")

                self.proxies = validated_proxies
                if self.proxies:
                    logger.info(f"Loaded {len(self.proxies)} proxies from {file_path}")
                else:
                    logger.warning(f"No valid proxies found in {file_path}")
            except FileNotFoundError:
                logger.warning(f"Proxy file not found: {file_path}")
            except Exception as e:
                logger.error(f"Error loading proxies from {file_path}: {e}")
        elif proxy_source == "api":
            api_url = proxy_config.get("api_url")
            api_key = proxy_config.get("api_key")
            if api_url and api_key:
                # Implement API fetching and parsing here (Phase 2).
                try:
                    # Placeholder for API call. Replace with real API call.
                    # Example using requests (replace with an actual API call)
                    response = requests.get(api_url, headers={"Authorization": f"Bearer {api_key}"}, timeout=10)
                    response.raise_for_status()
                    proxy_list = response.json()  # Assuming the API returns a list of proxy strings/objects
                    validated_proxies = []
                    for proxy_data in proxy_list:  # Adapt the parsing logic to your API
                        if isinstance(proxy_data, str):
                            try:
                                proxy_obj = self._parse_proxy(proxy_data)
                                validated_proxies.append(proxy_obj)
                            except Exception as e:
                                logger.error(f"Error while parsing proxy from API: {proxy_data}, {e}. Skipping.")
                        else:
                             try:
                                 proxy_str = f"{proxy_data['ip_address']}:{proxy_data['port']}"
                                 proxy_obj = self._parse_proxy(proxy_str)
                                 proxy_obj.protocol = proxy_data.get('protocol', 'http')
                                 proxy_obj.username = proxy_data.get('username')
                                 proxy_obj.password = proxy_data.get('password')
                                 validated_proxies.append(proxy_obj)
                             except Exception as e:
                                 logger.error(f"Error while parsing proxy data: {proxy_data}, {e}. Skipping.")

                    self.proxies = validated_proxies
                    if self.proxies:
                        logger.info(f"Loaded {len(self.proxies)} proxies from {api_url}")
                    else:
                        logger.warning(f"No valid proxies found from {api_url}")

                except requests.exceptions.RequestException as e:
                    logger.error(f"API request failed: {e}")
                except Exception as e:
                    logger.error(f"Error loading proxies from API: {e}")
            else:
                logger.warning("API URL or API key not specified for proxy, not using proxies")
        else:
            logger.warning(f"Invalid proxy source: {proxy_source}.  Please specify a valid source in llamafind.toml.")

    def _parse_proxy(self, proxy_str: str) -> Proxy:
        """Parses a proxy string of the form user:password@ip:port or ip:port"""
        match = re.match(r"((?P<username>[^@:]*):(?P<password>[^@:]*)@)?(?P<host>[^:]+):(?P<port>\d+)", proxy_str)
        if not match:
            raise ValueError(f"Invalid proxy string format: {proxy_str}")
        data = match.groupdict()
        return Proxy(
            ip_address=data["host"],
            port=int(data["port"]),
            protocol="http",  # Default protocol.  Can update later.
            username=data.get("username"),
            password=data.get("password"),
            anonymity="anonymous", # Default
        )

    def get_proxy(self) -> Optional[Proxy]:
        """
        Gets a random available proxy or None if no proxies are available.
        """
        if not self.proxies:
            return None
        return random.choice(self.proxies)
content_copy
download
Use code with caution.
Python

(16) llamafind/anti_bot/anti_bot.py (Anti-Bot Logic)

# Placeholder - implement actual anti-bot techniques in Phase 2
from typing import Optional

class AntiBot:
    """Handles anti-bot measures."""

    def __init__(self, user_agent:str = None):
        self.user_agent = user_agent
    def get_user_agent(self) -> str:
        """Get a user agent (implement rotation logic here)."""
        #Implement in Phase 2 (simple-header + simple-useragent)
        return self.user_agent if self.user_agent else "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    def apply_delay(self): # implement
        """Basic Rate Limiting."""
        # Implement basic rate limiting (e.g., time.sleep())
        # in Phase 2.
        pass

    def handle_captcha(self):
        """Placeholder for Captcha handling."""
        # Implement captcha detection and solving in Phase 2
        pass
content_copy
download
Use code with caution.
Python

Phase 3: LLM Integration (Placeholder, LLM-Specific Implementation Will Vary)

(17) llamafind/llm/llm_interface.py (LLM Interface):

# Placeholder - implementation depends on chosen MLX LLM and whether an external API is used.
# from Instructor import Instructor # from openai or other library depending on implementation
import instructor
from pydantic import BaseModel, Field
from typing import Any, Callable, Dict

from instructor.mode import Mode
from instructor.utils import Provider

# Placeholder for now, the actual LLM integration will depend on what LLM library
# you choose to use. This class will need to adapt the generic LLM calls to the chosen library.
class LLMInterface:
    def __init__(self, provider: str, model: str, api_key: str, llm_config: Dict[str,Any]):
        self.provider = Provider(provider)
        self.model = model
        self.api_key = api_key
        self.llm_config = llm_config
        self.client = self._initialize_client()
        self.model_name = model
        self.mode = Mode.JSON

    def _initialize_client(self):
        if self.provider == Provider.OPENAI:
            import openai
            # The OpenAI SDK now works with many different models.
            # To set the LLM you want to use, just set it in the initializer of the
            # client
            # Examples:
            # client = OpenAI(model="gpt-4-turbo")
            # client = OpenAI(model="mistralai/Mixtral-8x7B-Instruct-v0.1") # use custom models from openrouter
            client = openai.OpenAI(api_key=self.api_key)
            instructor_client = instructor.from_openai(client, mode=self.mode) # Pass a model and its features.
            return instructor_client
        if self.provider == Provider.GROQ:
            import groq
            client = groq.Groq(api_key=self.api_key)
            instructor_client = instructor.from_groq(client, mode=self.mode) # Pass a model and its features.
            return instructor_client
        # Add other providers here
        raise ValueError(f"Unsupported LLM provider: {self.provider}")

    def refine_query(self, query: str, search_results: List[SearchResult]) -> str:  # LLM-based Query Refinement
        # Replace this with your LLM-based query refinement implementation (using prompt engineering).
        # This is a placeholder
        return query

    def summarize_results(self, search_results: List[SearchResult], original_query: str) -> List[SearchResult]:  # LLM Summarization
        # Replace this with your LLM-based summarization implementation (using prompt engineering).
        # This is a placeholder
        return search_results

    def classify_result(self, result: SearchResult, categories: list[str]) -> dict:
        """Classifies a search result"""
        # You'll need a custom model
        pass # WIP

    def extract_information(self, scrape_result: ScrapeResult, information_needs: List[str]) -> ScrapeResult:
        """Extracts information from scrape result using the specified data structure"""
        pass # WIP

    def chat(self, prompt:str, response_model: BaseModel, temperature:float=0.1, **kwargs) -> BaseModel:
        # The base method for calling the LLM.  Will also need to implement the batch method.
        messages = [{"role": "user", "content": prompt}]

        response = self.client.chat.completions.create(
            model=self.model_name,
            messages=messages,
            response_model=response_model,
            temperature=temperature,
            **kwargs
        )
        return response


    # Add other helper functions (e.g., model-specific prompt formatting) as needed here.
content_copy
download
Use code with caution.
Python

Phase 4: CLI & API, Testing & Deployment (Emphasis on Code Quality and Security)

(18) llamafind/cli/cli_interface.py (CLI)from __future__ import annotations
import os
import sys
import logging
from typing import List, Optional, Dict, Tuple, Any

import typer
from rich.console import Console
from rich.table import Table
from llamafind.core.engine import LlamaFindEngine
from llamafind.data_models import SearchResult, Proxy
from datetime import datetime
# from llamafind.api.web_api import create_app

app = typer.Typer(help="LlamaFind: Your intelligent web search engine.")
console = Console()


@app.command()
def search(
        query: str = typer.Argument(..., help="The search query."),
        num_results: int = typer.Option(10, "--num-results", "-n", help="Number of results per engine."),
        engines: List[str] = typer.Option(
            [],
            "--engine",
            "-e",
            help="Search engines to use (e.g., google, bing, duckduckgo).",
            case_sensitive=False,
        ),
        config: str = typer.Option("llamafind.toml", "--config", "-c", help="Path to the configuration file."),
        output_format: str = typer.Option("text", "--output-format", "-f", help="Output format (text, json, csv, markdown)."),
        verbose: bool = typer.Option(False, "--verbose", "-v", help="Enable verbose logging."),
):
    """
    Performs a web search using LlamaFind.
    """
    # Configure logging
    log_level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(level=log_level, stream=sys.stderr)
    logger = logging.getLogger(__name__)

    logger.debug(f"Starting search: Query='{query}', Results per engine={num_results}, Engines={engines}, Config='{config}'")

    # Create engine
    engine = LlamaFindEngine(config_path=config)
    if not engine.search_engines:
        typer.echo("Error: No search engines configured.  Check your configuration file.")
        raise typer.Exit(code=1)

    # Execute the search
    try:
        results = await engine.search(query=query, num_results=num_results)
    except Exception as e:
        logger.exception(f"An error occurred during the search: {e}")
        typer.echo(f"Error during search: {e}", err=True)
        raise typer.Exit(code=1)

    # Output results based on the selected format
    if output_format == "text":
        display_text_results(results)
    elif output_format == "json":
        display_json_results(results)
    elif output_format == "csv":
        display_csv_results(results)
    elif output_format == "markdown":
        display_markdown_results(results)
    else:
        typer.echo(f"Error: Unsupported output format: {output_format}", err=True)
        raise typer.Exit(code=1)


def display_text_results(results: List[SearchResult]):
    """Display search results in text format."""
    for i, result in enumerate(results):
        console.print(f"[bold]{i+1}.[/] Engine: [yellow]{result.engine}[/]")
        console.print(f"  Title: [blue]{result.title}[/]")
        console.print(f"  URL: [green]{result.url}[/]")
        console.print(f"  Snippet: {result.snippet}\n")


def display_json_results(results: List[SearchResult]):
    """Display search results in JSON format."""
    import json
    console.print(json.dumps([r.model_dump() for r in results], indent=2))


def display_csv_results(results: List[SearchResult]):
    """Display search results in CSV format (basic implementation)."""
    # Consider more robust CSV formatting with a library
    print("title,url,snippet,engine")
    for result in results:
        print(f'"{result.title}","{result.url}","{result.snippet}","{result.engine}"')


def display_markdown_results(results: List[SearchResult]):
    """Display search results in Markdown format."""
    for result in results:
        print(f"## {result.title}")
        print(f"*   **Engine:** {result.engine}")
        print(f"*   **URL:** {result.url}")
        print(f"*   **Snippet:** {result.snippet}")
        print("")  # Add spacing between results


@app.command()
def list_proxies(config: str = typer.Option("llamafind.toml", "--config", "-c", help="Path to the configuration file.")):
    """List configured proxies."""
    # Configure logging
    log_level = logging.DEBUG
    logging.basicConfig(level=log_level, stream=sys.stderr)
    logger = logging.getLogger(__name__)

    engine = LlamaFindEngine(config_path=config)
    proxy_manager = engine._load_proxy_manager()
    if proxy_manager:
        proxies = proxy_manager
        if proxies and proxies.proxies:
          table = Table(title="Configured Proxies")
          table.add_column("Protocol", style="cyan")
          table.add_column("IP Address", style="magenta")
          table.add_column("Port", style="green")
          table.add_column("Username", style="yellow")
          table.add_column("Anonymity", style="yellow")
          table.add_column("Latency (s)", style="white")
          table.add_column("Country", style="white")

          for proxy in proxies.proxies:
            table.add_row(
                proxy.protocol,
                proxy.ip_address,
                str(proxy.port),
                proxy.username or "N/A",
                proxy.anonymity,
                str(proxy.latency),
                proxy.country or "N/A",
            )
          console.print(table)
        else:
          console.print("No proxies configured.")
    else:
        console.print("No proxy configuration found in llamafind.toml.  Check proxy settings.")

@app.command()
def test_extract_from_config(config: str = typer.Option("llamafind.toml", "--config", "-c", help="Path to the configuration file.")):
    """Test LLM Extract from config"""
    # Configure logging
    log_level = logging.DEBUG
    logging.basicConfig(level=log_level, stream=sys.stderr)
    logger = logging.getLogger(__name__)

    engine = LlamaFindEngine(config_path=config)
    if not engine.llm:
        typer.echo("No LLM is configured. Cannot test LLM extract.", err=True)
        raise typer.Exit(code=1)

    try:
      class TestExtract(BaseModel):
          text: str
      test_extract_prompt="From the text provided, give the result"
      extracted_text: TestExtract = engine.llm.chat(prompt=f"{test_extract_prompt} , {test_extract_prompt}", response_model=TestExtract)
      console.print(f"Extracted Text: {extracted_text.model_dump()}")

    except Exception as e:
        logger.error(f"Error extracting from config: {e}")
        typer.echo(f"Error extracting from config: {e}", err=True)

@app.command()
def version() -> None:
    """
    Show LlamaFind version.
    """
    from llamafind import __version__
    typer.echo(f"LlamaFind version: {__version__}")

# @app.command()
# def serve(
#     host: str = typer.Option("0.0.0.0", "--host", help="Host to bind to"),
#     port: int = typer.Option(8000, "--port", help="Port to listen on"),
# ) -> None:
#     """Runs the API server."""
#     app = create_app()  # Replace with the actual API app instantiation

#     import uvicorn
#     uvicorn.run(app, host=host, port=port)


if __name__ == "__main__":
    app()
content_copy
download
Use code with caution.
Python

(19) llamafind/api/web_api.py (Web API)

from fastapi import FastAPI, HTTPException
from fastapi.params import Depends
from pydantic import BaseModel
import instructor
from llamafind.data_models import SearchResult
from llamafind.core.engine import LlamaFindEngine
import asyncio

from typing import List, Optional, Dict

# Create a FastAPI instance
app = FastAPI(title="LlamaFind Search API")

# Request Models
class SearchRequest(BaseModel):
    query: str
    num_results: int = 10
    engines: Optional[List[str]] = None
    config_path: str = "llamafind.toml"  # Or another default

# Define the `search` endpoint
@app.post("/search", response_model=List[SearchResult])
async def search(request: SearchRequest):
    """
    Performs a web search and returns a list of search results.
    """
    engine = LlamaFindEngine(config_path=request.config_path) # Initialize Engine
    if not engine.search_engines:
      raise HTTPException(status_code=500, detail="No search engines are loaded. Check config file.")
    # Execute the search.  Return the result
    results = await engine.search(query=request.query, num_results=request.num_results)
    return results

# Placeholder for other API endpoints (e.g., /scrape, /proxies) - see earlier versions.
content_copy
download
Use code with caution.
Python

(20) llamafind/deployment/docker/Dockerfile (Dockerfile)

# Use an official Python runtime as a parent image
FROM python:3.10-slim-bullseye

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container
COPY pyproject.toml .
COPY setup.cfg .
COPY README.md .
COPY LICENSE .
COPY llamafind/ ./llamafind/
# Install Poetry (or use pip if you prefer) - needed for installing dependencies from pyproject.toml
RUN pip install poetry

# Install dependencies (including the package itself and its dev dependencies, except for running tests)
RUN poetry install --no-root --only main,dev --no-ansi --no-interaction --no-dev --verbose # removed - dev for now

# Copy application code (or just the relevant source code if you've other things)
COPY llamafind/ ./llamafind/
# Copy the configuration files.
COPY llamafind.toml .

# Expose the port your application runs on (e.g., 8000 for FastAPI)
EXPOSE 8000

# Set environment variables
ENV PYTHONUNBUFFERED=1 # important for logging

# Run the application (e.g., with Uvicorn for FastAPI)
CMD ["uvicorn", "llamafind.api.web_api:app", "--host", "0.0.0.0", "--port", "8000"]
content_copy
download
Use code with caution.
Dockerfile

(21) llamafind/deployment/docker/docker-compose.yml (Docker Compose)

version: "3.8"
services:
  app:
    build:
      context: .
      dockerfile: llamafind/deployment/docker/Dockerfile
    ports:
      - "8000:8000"
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY} # Pass in environment variables
      - ANYSCALE_API_KEY=${ANYSCALE_API_KEY}
      - GROQ_API_KEY=${GROQ_API_KEY}
    volumes:
      - .:/app
      # Optional: Mount the proxy file for loading proxy
      #- ./proxies.txt:/app/proxies.txt
      # Optional: for cache
      #- ./my_cache_directory:/app/my_cache_directory
content_copy
download
Use code with caution.
Yaml

(22) Testing (tests/)

Structure: Create the tests/ directory and populate it with the unit test files:

tests/__init__.py: (empty)

tests/test_core_engine.py: Tests for core engine functionalities (CLI argument parsing, engine orchestration).

tests/test_google_search.py, tests/test_bing_search.py, tests/test_duckduckgo_search.py, tests/test_yahoo_search.py, tests/test_baidu_search.py, tests/test_ecosia_search.py, tests/test_givewater_search.py, tests/test_pinterest_search.py: Tests for each search engine module, including testing the parsing of different types of search results and mock network requests.

tests/test_scraper.py: Tests for scraping utilities, ensuring correct text, link, image, and table extraction, including testing the download functions.

tests/test_data_models.py: Tests for Pydantic models, covering data validation and data structure correctness.

tests/test_proxy_manager.py: Tests for the proxy manager module, including proxy loading, selection, and health checks, including a test to validate the proxy setup in the file.

tests/test_anti_bot.py: Tests for anti-bot functionalities (if applicable in Phase 2).

... (Other Engine Tests)

Test Code Example (sample unit test for core_engine.py):

# tests/test_core_engine.py
import pytest
from unittest.mock import patch
from llamafind.core.engine import LlamaFindEngine
from llamafind.data_models import SearchResult


@pytest.fixture
def mock_search_engines():
    # Mock the search engine functions to return sample results
    def mock_google_search(query, num_results, proxy_manager=None):
        return [SearchResult(title="Google Result 1", url="http://example.com/1", snippet="Snippet 1", engine="google")]
    def mock_bing_search(query, num_results, proxy_manager=None):
        return [SearchResult(title="Bing Result 1", url="http://example.com/2", snippet="Snippet 2", engine="bing")]
    return {"google": mock_google_search, "bing": mock_bing_search}


@pytest.fixture
def engine_with_mock_engines(mock_search_engines):
    # Create an engine with mocked search engines
    with patch(
        "llamafind.core.engine.google_search", side_effect=mock_search_engines["google"]
    ), patch(
        "llamafind.core.engine.bing_search", side_effect=mock_search_engines["bing"]
    ):
        engine = LlamaFindEngine()
        engine.search_engines = mock_search_engines  # replace internal search engine calls
        return engine


def test_engine_search_calls_engines(engine_with_mock_engines):
    engine = engine_with_mock_engines
    results = asyncio.run(engine.search(query="test", num_results=2))
    assert len(results) == 2 # Number of engines called.
    assert results[0].engine == "google" # check engine name
    assert results[1].engine == "bing" # check engine name
content_copy
download
Use code with caution.
Python

(23) Supporting Files

Copy all supporting files from PyPI package descriptions.

Include requirements-doc.txt for documentation dependencies.

Create image/llamafind_banner.png (or replace with the actual banner).

III. Coding Prompts (For AI Code Generation - Module-by-Module)

This section provides a coding prompt suitable for an AI model. The prompt is divided into sections, each corresponding to a module or a significant functionality unit. The coding prompt uses ### <Module Name> to start a new code generation block. The prompt includes detailed instructions, requirements, expected outputs, and test case specifications.

### Project Overview:

We are building a web search engine called LlamaFind, which is designed to retrieve and enrich search results from multiple search engines. The engine will be implemented in Python, using best-in-class libraries. It will have a CLI for user interaction and a REST API for programmatic use. Key components will include multi-engine search, scraping (with Playwright), proxy management, anti-bot measures, and LLM-powered query refinement/result enhancement.

### llamafind/core/engine.py

**Objective:**  Create the core engine module for LlamaFind. This module will handle command-line argument parsing, search orchestration, loading configuration, and overall program flow.

**Dependencies:** `asyncio`, `argparse`, `configparser`, `logging`, `mlx` (placeholder for LLM), `pytest-asyncio`, `typing`, `typing_extensions`, import modules from the other files described above.

**Functionality:**

*   **CLI Argument Parsing:** Implement a `main` function using `argparse`. The arguments should include:
    *   `query`:  Search query (required, positional).
    *   `--engines` (or `-e`):  Comma-separated list of search engines (optional, choices: 'google', 'bing', 'duckduckgo', 'yahoo', 'baidu', 'ecosia', 'givewater', 'pinterest', default: 'google,duckduckgo,bing').
    *   `--config` (or `-c`): Path to the configuration file (optional, default: `llamafind.toml`).
    *   `--output-format`: Output format for CLI results ('text', 'json', 'csv', 'markdown', default: 'text').
    *   `--verbose` or `-v`: Enable debug logging (optional).
*   **Search Orchestration (`search` function):**
    *   The `search` function is asynchronous. It takes a search `query` (string) and the number of `num_results` per engine as input.
    *   It loads search engines based on the configuration, filters based on the specified engines and imports the correct engine based on a dictionary of available search engines.
    *   It uses `asyncio.gather` to concurrently call the search functions for each engine.
    *   Includes logging statements at the start, end, and any error conditions.
    *   Calls the `placeholder_llm_enhance_results` function.
    *   Returns a list of `SearchResult` objects, merged from all search engines.
*   **Configuration Loading:**  Implement a private method (`_load_config`) to load configurations from the `llamafind.toml` file.  If the file isn't found, use default search engines. Handle TOML parsing errors.
*   **Logging:** Set up logging using Python's `logging` module.  Configure logging level (DEBUG, INFO, ERROR) via the `--verbose` CLI flag.

```python
# llamafind/core/engine.py
import asyncio
import logging
import toml  # For configuration file parsing
import argparse
from typing import List, Dict, Tuple, Optional
from llamafind.search_engines import (
    google_search,
    bing_search,
    duckduckgo_search,
    yahoo_search,
    baidu_search,
    ecosia_search,
    givewater_search,
    pinterest_search,
)
from llamafind.scraping import scraper
from llamafind.data_models import SearchResult, Proxy, ScrapeResult  # Import Data models
from llamafind.llm.llm_interface import LLMInterface  # Placeholder for MLX LLM Integration
from urllib.parse import urlparse
import re

logger = logging.getLogger(__name__)

# Add logging statements at start of class and each function
class LlamaFindEngine:

    def __init__(self, config_path: str = "llamafind.toml"):
        """
        Initialize the LlamaFindEngine.

        Args:
            config_path (str): Path to the configuration file (default: "llamafind.toml").
        """
        logger.info(f"Initializing LlamaFindEngine with configuration from {config_path}")
        self.config = self._load_config(config_path)
        self.search_engines = self._load_search_engines()
        self.proxy_manager = self._load_proxy_manager()
        self.llm = self._load_llm()  # Load your LLM here.
        logger.debug("Engine Initialized Successfully")

    def _load_config(self, config_path: str) -> dict:
        """Load configuration from a TOML file."""
        try:
            with open(config_path, "r") as f:
                config = toml.load(f)
                logger.debug(f"Configuration loaded from {config_path}: {config}")
                return config
        except FileNotFoundError:
            logger.error(f"Configuration file not found: {config_path}. Using default configurations.")
            return {}  # or use default configurations
        except toml.TomlDecodeError as e:
            logger.error(f"Error decoding configuration file {config_path}: {e}. Using default configurations.")
            return {}

    def _load_search_engines(self) -> Dict[str, callable]:
        """Loads the search engines based on the configuration."""
        engines = {}
        configured_engines = self.config.get("default_search_engines", [])
        if not configured_engines:
            configured_engines = ["google", "duckduckgo", "bing"]  # Default engines if none are configured
            logger.warning(f"No search engines configured in llamafind.toml, using defaults: {configured_engines}")
        for engine_name in configured_engines:
            if engine_name == "google":
                engines["google"] = google_search
            elif engine_name == "bing":
                engines["bing"] = bing_search
            elif engine_name == "duckduckgo":
                engines["duckduckgo"] = duckduckgo_search
            elif engine_name == "yahoo":
                engines["yahoo"] = yahoo_search
            elif engine_name == "baidu":
                engines["baidu"] = baidu_search
            elif engine_name == "ecosia":
                engines["ecosia"] = ecosia_search
            elif engine_name == "givewater":
                engines["givewater"] = givewater_search
            elif engine_name == "pinterest":
                engines["pinterest"] = pinterest_search
            else:
                logger.warning(f"Search engine '{engine_name}' is not supported. Skipping it.")
        if not engines:
            logger.error("No valid search engines configured. Cannot search.")
        return engines

    def _load_proxy_manager(self) -> Optional[Dict[str, Any]]:
        """Loads and configures the proxy manager, returns proxy dictionary for each search"""
        proxy_config = self.config.get("proxy", {})
        proxy_source = proxy_config.get("source")
        proxy = None  # Placeholder, initialize actual implementation in Phase 2

        if proxy_source == "file":
            file_path = proxy_config.get("file_path")
            if file_path:
                try:
                    with open(file_path, "r") as f:
                        proxy_list = [line.strip() for line in f if line.strip()]
                    # Validate basic proxy format
                    validated_proxies: List[Proxy] = []
                    for proxy_str in proxy_list:
                        if ":" in proxy_str:
                            parts = proxy_str.split(":")
                            if 2 <= len(parts) <= 4:  # Basic check. Handle SOCKS later
                                validated_proxies.append(proxy_str)
                            else:
                                logger.warning(f"Invalid proxy format: {proxy_str}. Skipping.")
                    if validated_proxies:
                        proxy = {"proxies": validated_proxies}
                        logger.debug(f"Loaded {len(validated_proxies)} proxies from {file_path}")
                    else:
                        logger.warning(f"No valid proxies found in {file_path}")
                except FileNotFoundError:
                    logger.warning(f"Proxy file not found: {file_path}")
                except Exception as e:
                    logger.error(f"Error loading proxies from {file_path}: {e}")
            else:
                logger.warning("File path not specified in proxy configuration, not using proxies.")
        elif proxy_source == "api":
            api_url = proxy_config.get("api_url")
            api_key = proxy_config.get("api_key")
            # implement api fetching and parsing for Phase 2
            if api_url and api_key:
                proxy = {"api_url": api_url, "api_key": api_key}
                logger.debug(f"Proxy loaded from api_url: {api_url}")
            else:
                logger.warning("API URL or API key not specified for proxy, not using proxies")
        else:
            logger.warning("No proxy source provided.  Running without proxies.")

        return proxy

    def _load_llm(self) -> Optional[LLMInterface]:
        """Loads and configures the LLM, returns LLM Interface"""
        llm_config = self.config.get("llm", {})
        provider = llm_config.get("provider")
        model = llm_config.get("model")
        api_key = llm_config.get("api_key")
        if not (provider and model and api_key):
            logger.warning("No LLM is configured. LLM features will be disabled.")
            return None

        # Initialize your MLX LLM and return the appropriate instance
        # Replace this with your actual LLM initialization logic.

        llm_interface = LLMInterface(provider=provider, model=model, api_key=api_key, llm_config=llm_config)
        logger.debug(f"Loaded LLM interface: {provider}/{model}")
        return llm_interface

    async def search(self, query: str, num_results: int = 10) -> List[SearchResult]:
        """
        Performs a web search across multiple search engines.

        Args:
            query (str): The search query.
            num_results (int): The number of results to retrieve per search engine (default: 10).

        Returns:
            List[SearchResult]: A list of search results.
        """
        logger.info(f"Searching for: '{query}' across multiple search engines (Results per engine: {num_results})")
        all_results: List[SearchResult] = []
        if not self.search_engines:
            logger.error("No search engines are loaded. Returning empty results.")
            return []

        for engine_name, search_function in self.search_engines.items():
            logger.debug(f"Searching with {engine_name}")
            try:
                results = await search_function(query, num_results, self.proxy_manager)  # Pass proxy manager
                for result in results:
                    result.engine = engine_name
                all_results.extend(results)
                logger.debug(f"Found {len(results)} results for {engine_name}")
            except Exception as e:
                logger.error(f"Error searching with {engine_name}: {e}")

        # LLM-based query refinement (Phase 3)
        if self.llm:
            try:
                refined_query = await self.llm.refine_query(query, all_results)
                if refined_query != query:
                    logger.info(f"Query Refined from '{query}' to '{refined_query}'")
                    # Call search functions again for each engine with the refined query
                    refined_results: List[SearchResult] = []
                    for engine_name, search_function in self.search_engines.items():
                        try:
                            results = await search_function(refined_query, num_results, self.proxy_manager)
                            for result in results:
                                result.engine = engine_name
                            refined_results.extend(results)
                        except Exception as e:
                            logger.error(f"Error searching with refined query with {engine_name}: {e}")
                    all_results = refined_results

            except Exception as e:
                logger.error(f"Error refining query: {e}")

        # Result summarization (Phase 3) - basic summarization: to be defined at a later stage.
        if self.llm:
            try:
                all_results = await self.llm.summarize_results(all_results, query)
            except Exception as e:
                logger.error(f"Error summarization for results: {e}")

        return all_results


# Define the main entry point
def main():
  # Create the parser
  parser = argparse.ArgumentParser(description="LlamaFind: Your Intelligent Web Search Engine")

  # Add the required arguments for the search
  parser.add_argument("query", help="The search query")
  parser.add_argument(
      "-n", "--num-results", type=int, default=10, help="Number of search results per engine"
  )
  parser.add_argument(
      "-e",
      "--engine",
      nargs="+",
      default=["google", "duckduckgo", "bing"],
      choices=["google", "bing", "duckduckgo", "yahoo", "baidu", "ecosia", "givewater", "pinterest"],
      help="Search engines to use (e.g., google, bing, duckduckgo).",
  )
  parser.add_argument(
      "-c", "--config", type=str, default="llamafind.toml", help="Path to the configuration file."
  )
  parser.add_argument(
    "-f", "--output-format", type=str, default="text", help="Output format for CLI results ('text', 'json', 'csv', 'markdown')."
  )
  parser.add_argument(
    "-v", "--verbose", action="store_true", help="Enable verbose logging."
  )

  # Parse the arguments
  args = parser.parse_args()

  # Set up the logging
  log_level = logging.DEBUG if args.verbose else logging.INFO
  logging.basicConfig(level=log_level, stream=sys.stderr)
  logger = logging.getLogger(__name__)

  # Instantiate and run the LlamaFindEngine
  engine = LlamaFindEngine(args.config)
  asyncio.run(engine.search(args.query, args.num_results))

if __name__ == "__main__":
  main()
content_copy
download
Use code with caution.

Unit Tests for core_engine.py:

# tests/test_core_engine.py
import pytest
import asyncio
from unittest.mock import patch, Mock
from llamafind.core.engine import LlamaFindEngine
from llamafind.data_models import SearchResult


# Helper functions
def create_mock_search_engine(results=None):
    """Creates a mock search engine function"""
    if results is None:
        results = [SearchResult(title="Mock Result", url="http://example.com", snippet="Test snippet", engine="mock")]

    async def mock_search(query, num_results, proxy_manager):
        return results
    return mock_search

@pytest.fixture
def engine_with_mock_engines():
    # Create an engine with mocked search engines
    mock_engines = {
        "google": create_mock_search_engine(),
        "bing": create_mock_search_engine(),
    }
    with patch(
        "llamafind.core.engine.google_search", side_effect=mock_engines["google"]
    ), patch(
        "llamafind.core.engine.bing_search", side_effect=mock_engines["bing"]
    ):
        engine = LlamaFindEngine()
        engine.search_engines = mock_engines  # replace internal search engine calls
        return engine


@pytest.mark.asyncio
async def test_engine_search_calls_engines(engine_with_mock_engines):
    engine = engine_with_mock_engines
    results = await engine.search(query="test", num_results=2)
    assert len(results) == 2 # Number of engines called.
    assert results[0].engine == "google" # check engine name
    assert results[1].engine == "bing" # check engine name


@pytest.mark.asyncio
async def test_engine_handles_empty_engine_config():
    # Create engine and search
    engine = LlamaFindEngine(config_path='nonexistent.toml') # invalid config path
    results = await engine.search(query="test", num_results=2) # Run a search.
    assert results == [] # Empty list to be returned if there are no valid search engines


def test_load_config_handles_missing_file():
    engine = LlamaFindEngine(config_path="nonexistent.toml")  # Replace with an invalid config path
    config = engine._load_config("nonexistent.toml")
    assert isinstance(config, dict) and not config, "Should return an empty dict"

def test_load_config_handles_invalid_file():
    # Create a config string with invalid format
    # For example without valid toml structure.
    invalid_config_str = """
    invalid_setting =
    """
    with open("invalid.toml", "w") as f:
        f.write(invalid_config_str)

    engine = LlamaFindEngine(config_path="invalid.toml")
    config = engine._load_config("invalid.toml")
    assert isinstance(config, dict) and not config, "Should return an empty dict on invalid config"

    # Clean up the temporary file.
    import os
    os.remove("invalid.toml")
content_copy
download
Use code with caution.
Python### llamafind/search_engines/__init__.py
```python
# Placeholder - No code needed here.
content_copy
download
Use code with caution.
Python

(1) llamafind/search_engines/google.py (Google Search - Implemented)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def google_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Google search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Google for '{query}' (Results: {num_results})")
    base_url = "https://www.google.com/search"
    params = {"q": query, "num": num_results}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="g"):
            title_element = result.find("h3")
            link_element = result.find("a")
            snippet_element = result.find("span", class_="st")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="google")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Google search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(2) llamafind/search_engines/bing.py (Bing Search - Implemented)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def bing_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Bing search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Bing for '{query}' (Results: {num_results})")
    base_url = "https://www.bing.com/search"
    params = {"q": query, "count": num_results}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("li", class_="b_algo"):
            title_element = result.find("h2")
            link_element = result.find("a")
            snippet_element = result.find("p", class_="b_snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="bing")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Bing search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(3) llamafind/search_engines/duckduckgo.py (DuckDuckGo Search - Implemented)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def duckduckgo_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a DuckDuckGo search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching DuckDuckGo for '{query}' (Results: {num_results})")
    base_url = "https://duckduckgo.com/html"
    params = {"q": query, "max_results": num_results}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="result"):
            title_element = result.find("h2", class_="result__title")
            link_element = result.find("a", class_="result__a")
            snippet_element = result.find("div", class_="result__snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="duckduckgo")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing DuckDuckGo search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(4) llamafind/search_engines/yahoo.py (Yahoo Search - Implemented)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def yahoo_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Yahoo search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Yahoo for '{query}' (Results: {num_results})")
    base_url = "https://search.yahoo.com/search"
    params = {"q": query, "n": num_results} # 'n' used instead of num.

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="NewsArticle"): #Updated for yahoo
            title_element = result.find("h3", class_="title")
            link_element = result.find("a", class_="thmb")
            snippet_element = result.find("p", class_="txt")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="yahoo")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Yahoo search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(5) llamafind/search_engines/baidu.py (Baidu Search - Implemented)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def baidu_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Baidu search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Baidu for '{query}' (Results: {num_results})")
    base_url = "https://www.baidu.com/s"
    params = {"wd": query, "rn": num_results} # Use 'rn' instead of num

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="result c-container"):
            title_element = result.find("h3", class_="t")
            link_element = result.find("a")  # Usually the first a tag inside
            snippet_element = result.find("div", class_="c-abstract")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="baidu")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Baidu search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(6) llamafind/search_engines/ecosia.py (Ecosia Search - Implemented)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def ecosia_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs an Ecosia search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Ecosia for '{query}' (Results: {num_results})")
    base_url = "https://www.ecosia.org/search"
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="result-firstline-container"):
            title_element = result.find("a")
            link_element = result.find("a") # Updated for ecosia
            snippet_element = result.find("p", class_="result-snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="ecosia")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Ecosia search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(7) llamafind/search_engines/givewater.py (GiveWater Search - Implemented)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def givewater_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a GiveWater search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching GiveWater for '{query}' (Results: {num_results})")
    base_url = "https://search.givewater.com/serp"
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="web-bing__result"):
            title_element = result.find("a")
            link_element = result.find("a")
            snippet_element = result.find("p", class_="b_snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="givewater")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing GiveWater search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(8) llamafind/search_engines/pinterest.py (Pinterest Search - Implemented)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def pinterest_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Pinterest search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Pinterest for '{query}' (Results: {num_results})")
    base_url = "https://www.pinterest.com/search/pins/" # The base url has been added to the method.
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "X-Requested-With": "XMLHttpRequest",
        "Accept": "application/json",
        # Adding Accept-Language Header
        "Accept-Language": "en-US,en;q=0.9"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        # Pinterest returns JSON data.
        data = response.json()
        results: List[SearchResult] = []
        for item in data.get('pins', []):
            title = item.get('title')
            url = item.get('url')
            if title and url:
                results.append(SearchResult(title=title, url=url, engine="pinterest", image_url=item.get('images').get('orig').get('url')))
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Pinterest search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(9) llamafind/llm/llm_interface.py (LLM Interface)

import asyncio
import logging
from typing import List, Dict, Tuple, Optional, Any
from llamafind.data_models import SearchResult
from instructor.function_calls import Mode
from openai import OpenAI
from pydantic import BaseModel, Field
from typing import Iterable, Union
import instructor

logger = logging.getLogger(__name__)


class LLMInterface:
    """
    Interface for interacting with an LLM and defining function calls.
    """

    def __init__(self, provider: str, model: str, api_key: str, llm_config: Dict[str, Any]):
        """
        Initializes the LLMInterface.

        Args:
            provider (str): The LLM provider (e.g., "openai").
            model (str): The specific LLM model name (e.g., "gpt-4o").
            api_key (str): The API key for the LLM provider.
        """
        self.provider = provider.lower()  # Lowercase to handle different inputs
        self.model = model
        self.api_key = api_key
        self.llm_config = llm_config
        self.client = self._initialize_client()  # Initialize the client during init
        self.mode = Mode.JSON

    def _initialize_client(self):
        """
        Initializes the OpenAI client.
        """
        if self.provider == "openai":
            client = openai.OpenAI(api_key=self.api_key)
            instructor_client = instructor.from_openai(client, mode=self.mode)
            return instructor_client
        elif self.provider == "groq":
            import groq
            client = groq.Groq(api_key=self.api_key)
            instructor_client = instructor.from_groq(client, mode=self.mode)
            return instructor_client

            # Add additional providers here.
        else:
            raise ValueError(f"Unsupported LLM provider: {self.provider}")

    def refine_query(self, query: str, search_results: List[SearchResult]) -> str:
        """
        Placeholder implementation of a query refinement function.

        Args:
            query (str): The original search query.
            search_results (List[SearchResult]): The search results obtained from the initial search.

        Returns:
            str: Refined search query.
        """
        logger.info("Refining query")
        # Replace with actual implementation using the LLM in Phase 3
        return query

    def summarize_results(self, search_results: List[SearchResult], original_query: str) -> List[SearchResult]:
        """
        Placeholder implementation of a summarization function.

        Args:
            search_results (List[SearchResult]): The search results to summarize.
            original_query (str): The original search query.

        Returns:
            List[SearchResult]: The summarized search results.
        """
        logger.info("Summarizing results")
        # Replace with actual LLM-based summarization implementation in Phase 3
        return search_results  # Return the same results for now, modify them later with LLM.

    def classify_result(self, search_result: SearchResult, categories: list[str]) -> dict:
        """Classifies a search result"""
        pass # WIP - for the LLM-based part

    def extract_information(self, scrape_result: ScrapeResult, information_needs: List[str]) -> ScrapeResult:
        """Extracts information from scrape result using the specified data structure"""
        pass  # WIP - for the LLM-based part

    def chat(self, prompt:str, response_model: BaseModel, temperature:float=0.1, **kwargs) -> BaseModel:
        # The base method for calling the LLM.  Will also need to implement the batch method.
        messages = [{"role": "user", "content": prompt}]

        response = self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            response_model=response_model,
            temperature=temperature,
            **kwargs
        )
        return response

    def create(self, messages: List[Dict[str,str]], response_model:BaseModel, temperature:float =0.1) -> Any:
      return self.client.chat.completions.create(
        model=self.model_name,
        messages=messages,
        response_model=response_model,
        temperature=temperature,
      )
content_copy
download
Use code with caution.
Python

III. llamafind/scraping/__init__.py (Scraping Initialization)

# Placeholder - No code needed here.
content_copy
download
Use code with caution.
Python

(10) llamafind/scraping/scraper.py (Scraping)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup
from fake_useragent import UserAgent
import re
from llamafind.data_models import ScrapeResult

logger = logging.getLogger(__name__)


class WebScraper:
    """
    A basic web scraper.
    """

    def __init__(self, user_agent: str = None, proxies: Optional[Dict[str, str]] = None, timeout: int = 15):
        """
        Initialize the WebScraper.

        Args:
            user_agent (str): User-Agent string to use for requests.
            proxies (Optional[Dict[str, str]]): Optional dictionary of proxies to use (see requests library).
            timeout (int): Timeout for requests in seconds.
        """
        self.user_agent = user_agent or self.get_random_user_agent()
        self.proxies = proxies or {}
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": self.user_agent})
        self.timeout = timeout

    def get_random_user_agent(self) -> str:
        """
        Generates a random user agent string.

        Returns:
content_copy
download
Use code with caution.
Pythonstr: A random user agent.
        """
        ua = UserAgent()
        return ua.random

    def fetch_page(self, url: str) -> Optional[str]:
        """
        Fetches the HTML content of a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            Optional[str]: The HTML content as a string, or None if the request fails.
        """
        try:
            logger.debug(f"Fetching URL: {url} using proxy {self.proxies if self.proxies else 'No Proxy'}")
            response = self.session.get(url, timeout=self.timeout, proxies=self.proxies)
            response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
            return response.text
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch {url}: {e}")
            return None

    def get_soup(self, html_content: str) -> Optional[BeautifulSoup]:
        """
        Parses HTML content using BeautifulSoup.

        Args:
            html_content (str): The HTML content as a string.

        Returns:
            Optional[BeautifulSoup]: A BeautifulSoup object, or None if parsing fails.
        """
        try:
            return BeautifulSoup(html_content, "html.parser")
        except Exception as e:
            logger.error(f"Failed to parse HTML: {e}")
            return None

    def get_text(self, url: str) -> str:
        """
        Extracts the full text content of a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            str: The extracted text content.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return ""
        soup = self.get_soup(html_content)
        return soup.get_text(separator=" ", strip=True) if soup else ""

    def get_links(self, url: str) -> List[Dict[str, str]]:
        """
        Extracts all links from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[Dict[str, str]]: A list of dictionaries, where each dictionary represents a link with 'text' and 'href' keys.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        links = []
        if soup:
            for a in soup.find_all("a", href=True):
                text = a.get_text(strip=True)
                href = a["href"]
                absolute_url = self._make_absolute(url, href)
                links.append({"text": text, "href": absolute_url})
        return links

    def get_images(self, url: str) -> List[str]:
        """
        Extracts all image URLs from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[str]: A list of image URLs.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        image_urls = []
        if soup:
            for img in soup.find_all("img", src=True):
                src = img["src"]
                absolute_url = self._make_absolute(url, src)
                image_urls.append(absolute_url)
        return image_urls

    def get_tables(self, url: str) -> List[str]:
        """
        Extracts all tables from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[str]: A list of table strings.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        tables = []
        if soup:
            for table in soup.find_all("table"):
                tables.append(str(table))  # Return raw HTML
        return tables

    def _make_absolute(self, base_url, url):
        """Helper to convert relative URLs to absolute URLs."""
        from urllib.parse import urljoin

        return urljoin(base_url, url)


class SeleniumScraper(WebScraper):
    """
    A web scraper that uses Selenium to render dynamic content.
    """

    def __init__(
            self,
            user_agent: Optional[str] = None,
            proxies: Optional[Dict[str, str]] = None,
            headless: bool = True,
            driver_path: Optional[str] = None,
            timeout: int = 15,
    ):
        from selenium import webdriver
        from selenium.webdriver.firefox.options import Options as FirefoxOptions
        from selenium.webdriver.chrome.options import Options as ChromeOptions
        from selenium.webdriver.chrome.service import Service as ChromeService
        from selenium.webdriver.firefox.service import Service as FirefoxService
        from selenium.webdriver.remote.webdriver import WebDriver
        from webdriver_manager.chrome import ChromeDriverManager
        from webdriver_manager.firefox import GeckoDriverManager

        super().__init__(user_agent, proxies, timeout)
        self.headless = headless
        self.driver_path = driver_path
        self.driver: Optional[WebDriver] = None

        self.driver_type: str = "chromium"  # Or "firefox"

    def fetch_page(self, url: str) -> Optional[str]:
        """
        Fetches the HTML content of a web page using Selenium.

        Args:
            url (str): The URL of the web page.

        Returns:
            Optional[str]: The HTML content as a string, or None if the request fails.
        """
        try:
            self._setup_driver()
            self.driver.get(url)
            self._wait_for_page_load()
            return self.driver.page_source
        except Exception as e:
            logger.error(f"Failed to fetch (Selenium) {url}: {e}")
            return None
        finally:
            self._teardown_driver()

    def get_soup(self, html_content: str) -> Optional[BeautifulSoup]:
        """
        Parses HTML content using BeautifulSoup.

        Args:
            html_content (str): The HTML content as a string.

        Returns:
            Optional[BeautifulSoup]: A BeautifulSoup object, or None if parsing fails.
        """
        if not html_content:
            return None
        try:
            return BeautifulSoup(html_content, "html.parser")
        except Exception as e:
            logger.error(f"Failed to parse HTML (Selenium): {e}")
            return None

    def _setup_driver(self):
        """Set up the Selenium WebDriver (Chromium or Firefox)."""
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options as ChromeOptions
        from selenium.webdriver.chrome.service import Service as ChromeService
        from selenium.webdriver.firefox.options import Options as FirefoxOptions
        from selenium.webdriver.firefox.service import Service as FirefoxService
        from webdriver_manager.chrome import ChromeDriverManager
        from webdriver_manager.firefox import GeckoDriverManager
        from selenium.webdriver.remote.webdriver import WebDriver

        if self.driver:
            return # already set

        if self.driver_type == "chromium":
            chrome_options = ChromeOptions()
            if self.headless:
                chrome_options.add_argument("--headless")  # Run in headless mode
            if self.user_agent:
                chrome_options.add_argument(f"--user-agent={self.user_agent}")
            if self.proxies:
                # Configure proxy for Selenium
                # Only single proxy supported
                proxy = list(self.proxies.values())[0]
                if isinstance(proxy, str):
                  chrome_options.add_argument(f"--proxy-server={proxy}")
                else:
                  logger.error(f"Selenium only supports string based proxies. Got {type(proxy)=}")
            if self.driver_path:
                try:
                    service = ChromeService(executable_path=self.driver_path)
                    self.driver = webdriver.Chrome(service=service, options=chrome_options)
                except Exception as e:
                    logger.error(f"Chrome not found at location: {self.driver_path=}, defaulting to chrome webdriver manager. {e}")
                    self.driver = webdriver.Chrome(ChromeDriverManager().install(), options=chrome_options) # Use webdriver_manager
            else:
                self.driver = webdriver.Chrome(ChromeDriverManager().install(), options=chrome_options) # Use webdriver_manager
        elif self.driver_type == "firefox":
            firefox_options = FirefoxOptions()
            if self.headless:
                firefox_options.add_argument("--headless")  # Run in headless mode
            if self.user_agent:
                firefox_options.add_argument(f"--user-agent={self.user_agent}")
            if self.proxies:
                # Configure proxy for Selenium
                # Only single proxy supported
                proxy = list(self.proxies.values())[0]
                if isinstance(proxy, str):
                  firefox_options.add_argument(f"--proxy-server={proxy}")
                else:
                  logger.error(f"Selenium only supports string based proxies. Got {type(proxy)=}")

            if self.driver_path:
              try:
                service = FirefoxService(executable_path=self.driver_path)
                self.driver = webdriver.Firefox(service=service, options=firefox_options)
              except Exception as e:
                logger.error(f"Firefox not found at location: {self.driver_path=}, defaulting to firefox webdriver manager. {e}")
                self.driver = webdriver.Firefox(executable_path=GeckoDriverManager().install(), options=firefox_options) # Use webdriver_manager
            else:
                self.driver = webdriver.Firefox(executable_path=GeckoDriverManager().install(), options=firefox_options) # Use webdriver_manager
        else:
            raise ValueError(f"Unsupported driver type: {self.driver_type}")
        if self.timeout:
          self.driver.set_page_load_timeout(self.timeout) #Set time out

    def _wait_for_page_load(self):
        """Waits for page to load (can be customized) - Example:
            - waiting for document ready state to be complete
        """
        # can be customized, example:
        from selenium.webdriver.support.ui import WebDriverWait
        from selenium.webdriver.support import expected_conditions as EC
        from selenium.webdriver.common.by import By

        try:
            WebDriverWait(self.driver, self.timeout).until(
                EC.presence_of_element_located((By.TAG_NAME, "body"))  # Example
            )
        except Exception as e:
            logger.error(f"Error while waiting for page to load: {e}")

    def _teardown_driver(self):
        """Tear down the Selenium WebDriver."""
        if self.driver:
            try:
                self.driver.quit()
            except Exception as e:
                logger.error(f"Error closing the Selenium driver: {e}")
            self.driver = None
content_copy
download
Use code with caution.
Python

(1) llamafind/core/engine.py - Continued

import argparse
import asyncio
import logging
import toml  # For configuration file parsing
from typing import List, Dict, Tuple, Optional
from llamafind.search_engines import (
    google_search,
    bing_search,
    duckduckgo_search,
    yahoo_search,
    baidu_search,
    ecosia_search,
    givewater_search,
    pinterest_search,
)
from llamafind.scraping import scraper
from llamafind.data_models import SearchResult, Proxy, ScrapeResult  # Import Data models
from llamafind.llm.llm_interface import LLMInterface  # Placeholder for MLX LLM Integration
from urllib.parse import urlparse
import re

logger = logging.getLogger(__name__)


# Define the main entry point
def main():
  # Create the parser
  parser = argparse.ArgumentParser(description="LlamaFind: Your Intelligent Web Search Engine")

  # Add the required arguments for the search
  parser.add_argument("query", help="The search query")
  parser.add_argument(
      "-n", "--num-results", type=int, default=10, help="Number of search results per engine"
  )
  parser.add_argument(
      "-e",
      "--engine",
      nargs="+",
      default=["google", "duckduckgo", "bing"],
      choices=["google", "bing", "duckduckgo", "yahoo", "baidu", "ecosia", "givewater", "pinterest"],
      help="Search engines to use (e.g., google, bing, duckduckgo).",
  )
  parser.add_argument(
      "-c", "--config", type=str, default="llamafind.toml", help="Path to the configuration file."
  )
  parser.add_argument(
    "-f", "--output-format", type=str, default="text", help="Output format for CLI results ('text', 'json', 'csv', 'markdown')."
  )
  parser.add_argument(
    "-v", "--verbose", action="store_true", help="Enable verbose logging."
  )

  # Parse the arguments
  args = parser.parse_args()

  # Set up the logging
  log_level = logging.DEBUG if args.verbose else logging.INFO
  logging.basicConfig(level=log_level, stream=sys.stderr)
  logger = logging.getLogger(__name__)

  # Instantiate and run the LlamaFindEngine
  engine = LlamaFindEngine(args.config)
  asyncio.run(engine.search(args.query, args.num_results))
content_copy
download
Use code with caution.
Python

Unit Tests for core_engine.py: (as described previously).

# tests/test_core_engine.py
import pytest
import asyncio
from unittest.mock import patch, Mock
from llamafind.core.engine import LlamaFindEngine
from llamafind.data_models import SearchResult


# Helper functions
def create_mock_search_engine(results=None):
    """Creates a mock search engine function"""
    if results is None:
        results = [SearchResult(title="Mock Result", url="http://example.com", snippet="Snippet 1", engine="mock")]

    async def mock_search(query, num_results, proxy_manager=None):
        return results
    return mock_search

@pytest.fixture
def engine_with_mock_engines():
    # Create an engine with mocked search engines
    mock_engines = {
        "google": create_mock_search_engine(),
        "bing": create_mock_search_engine(),
    }
    with patch(
        "llamafind.core.engine.google_search", side_effect=mock_engines["google"]
    ), patch(
        "llamafind.core.engine.bing_search", side_effect=mock_engines["bing"]
    ):
        engine = LlamaFindEngine()
        engine.search_engines = mock_search_engines  # replace internal search engine calls
        return engine


@pytest.mark.asyncio
async def test_engine_search_calls_engines(engine_with_mock_engines):
    engine = engine_with_mock_engines
    results = await engine.search(query="test", num_results=2)
    assert len(results) == 2 # Number of engines called.
    assert results[0].engine == "google" # check engine name
    assert results[1].engine == "bing" # check engine name


@pytest.mark.asyncio
async def test_engine_handles_empty_engine_config():
    # Create engine and search
    engine = LlamaFindEngine(config_path='nonexistent.toml') # invalid config path
    results = await engine.search(query="test", num_results=2) # Run a search.
    assert results == [] # Empty list to be returned if there are no valid search engines


def test_load_config_handles_missing_file():
    engine = LlamaFindEngine(config_path="nonexistent.toml")  # Replace with an invalid config path
    config = engine._load_config("nonexistent.toml")
    assert isinstance(config, dict) and not config, "Should return an empty dict"

def test_load_config_handles_invalid_file():
    # Create a config string with invalid format
    # For example without valid toml structure.
    invalid_config_str = """
    invalid_setting =
    """
    with open("invalid.toml", "w") as f:
        f.write(invalid_config_str)

    engine = LlamaFindEngine(config_path="invalid.toml")
    config = engine._load_config("invalid.toml")
    assert isinstance(config, dict) and not config, "Should return an empty dict on invalid config"

    # Clean up the temporary file.
    import os
    os.remove("invalid.toml")
content_copy
download
Use code with caution.
Python

(18) llamafind/cli/cli_interface.py (CLI - Continued from Original Structure)

from llamafind.core.engine import LlamaFindEngine
from llamafind.data_models import SearchResult
from datetime import datetime
import typer
from typing import List, Optional, Dict

app = typer.Typer(help="LlamaFind: Your intelligent web search engine.")

def display_text_results(results: List[SearchResult]):
    """Display search results in text format."""
    for i, result in enumerate(results):
        typer.echo(f"[bold]{i+1}.[/] Engine: [yellow]{result.engine}[/]")
        typer.echo(f"  Title: [blue]{result.title}[/]")
        typer.echo(f"  URL: [green]{result.url}[/]")
        typer.echo(f"  Snippet: {result.snippet}\n")


def display_json_results(results: List[SearchResult]):
    """Display search results in JSON format."""
    import json
    typer.echo(json.dumps([r.model_dump() for r in results], indent=2))


def display_csv_results(results: List[SearchResult]):
    """Display search results in CSV format (basic implementation)."""
    # Consider more robust CSV formatting with a library
    print("title,url,snippet,engine")
    for result in results:
        print(f'"{result.title}","{result.url}","{result.snippet}","{result.engine}"')


def display_markdown_results(results: List[SearchResult]):
    """Display search results in Markdown format."""
    for result in results:
        print(f"## {result.title}")
        print(f"*   **Engine:** {result.engine}")
        print(f"*   **URL:** {result.url}")
        print(f"*   **Snippet:** {result.snippet}")
        print("")  # Add spacing between results

@app.command()
def search(
        query: str = typer.Argument(..., help="The search query."),
        num_results: int = typer.Option(10, "--num-results", "-n", help="Number of results per engine."),
        engines: List[str] = typer.Option(
            [],
            "--engine",
            "-e",
            help="Search engines to use (e.g., google, bing, duckduckgo).",
            case_sensitive=False,
        ),
        config: str = typer.Option("llamafind.toml", "--config", "-c", help="Path to the configuration file."),
        output_format: str = typer.Option("text", "--output-format", "-f", help="Output format (text, json, csv, markdown)."),
        verbose: bool = typer.Option(False, "--verbose", "-v", help="Enable verbose logging."),
):
    """
    Performs a web search using LlamaFind.
    """
    # Configure logging
    log_level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(level=log_level, stream=sys.stderr)
    logger = logging.getLogger(__name__)

    logger.debug(f"Starting search: Query='{query}', Results per engine={num_results}, Engines={engines}, Config='{config}'")

    # Create engine
    engine = LlamaFindEngine(config_path=config)
    if not engine.search_engines:
        typer.echo("Error: No search engines configured.  Check your configuration file.")
        raise typer.Exit(code=1)

    # Execute the search
    try:
        results = asyncio.run(engine.search(query=query, num_results=num_results))
    except Exception as e:
        logger.exception(f"An error occurred during the search: {e}")
        typer.echo(f"Error during search: {e}", err=True)
        raise typer.Exit(code=1)

    # Output results based on the selected format
    if output_format == "text":
        display_text_results(results)
    elif output_format == "json":
        display_json_results(results)
    elif output_format == "csv":
        display_csv_results(results)
    elif output_format == "markdown":
        display_markdown_results(results)
    else:
        typer.echo(f"Error: Unsupported output format: {output_format}", err=True)
        raise typer.Exit(code=1)


@app.command()
def list_proxies(config: str = typer.Option("llamafind.toml", "--config", "-c", help="Path to the configuration file.")):
    """List configured proxies."""
    # Configure logging
    log_level = logging.DEBUG
    logging.basicConfig(level=log_level, stream=sys.stderr)
    logger = logging.getLogger(__name__)

    engine = LlamaFindEngine(config_path=config)
    proxy_manager = engine._load_proxy_manager()
    if proxy_manager:
        proxies = proxy_manager
        if proxies and proxies.proxies:
          table = Table(title="Configured Proxies")
          table.add_column("Protocol", style="cyan")
          table.add_column("IP Address", style="magenta")
          table.add_column("Port", style="green")
          table.add_column("Username", style="yellow")
          table.add_column("Anonymity", style="yellow")
          table.add_column("Latency (s)", style="white")
          table.add_column("Country", style="white")

          for proxy in proxies.proxies:
            table.add_row(
                proxy.protocol,
                proxy.ip_address,
                str(proxy.port),
                proxy.username or "N/A",
                proxy.anonymity,
                str(proxy.latency),
                proxy.country or "N/A",
            )
          console.print(table)
        else:
          console.print("No proxies configured.")
    else:
        console.print("No proxy configuration found in llamafind.toml.  Check proxy settings.")

@app.command()
def test_extract_from_config(config: str = typer.Option("llamafind.toml", "--config", "-c", help="Path to the configuration file.")):
    """Test LLM Extract from config"""
    # Configure logging
    log_level = logging.DEBUG
    logging.basicConfig(level=log_level, stream=sys.stderr)
    logger = logging.getLogger(__name__)

    engine = LlamaFindEngine(config_path=config)
    if not engine.llm:
        typer.echo("No LLM is configured. Cannot test LLM extract.", err=True)
        raise typer.Exit(code=1)

    try:
      class TestExtract(BaseModel):
          text: str
      test_extract_prompt="From the text provided, give the result"
      extracted_text: TestExtract = engine.llm.chat(prompt=f"{test_extract_prompt} , {test_extract_prompt}", response_model=TestExtract)
      console.print(f"Extracted Text: {extracted_text.model_dump()}")

    except Exception as e:
        logger.error(f"Error extracting from config: {e}")
        typer.echo(f"Error extracting from config: {e}", err=True)

@app.command()
def version() -> None:
    """
    Show LlamaFind version.
    """
    from llamafind import __version__
    typer.echo(f"LlamaFind version: {__version__}")
content_copy
download
Use code with caution.
Python

(23) Test Suite and Dockerization (Test Files & Dockerfile, docker-compose.yml)

Separate Testing Module: Create a new directory, tests/, for tests.

Organize Tests: Within tests/, create separate Python files for testing: test_core_engine.py, test_scraper.py, etc., matching the modules in the main package.

Implement Tests:

For each module:

Test core functionalities (e.g., search engine calls, scraping logic).

Mock external dependencies (e.g., network requests, LLM calls) using unittest.mock.patch or similar.

Test error handling.

Focus on edge cases and boundary conditions.

tests/__init__.py: (empty)

Example Test File:

# tests/test_core_engine.py
import pytest
import asyncio
from unittest.mock import patch, Mock
from llamafind.core.engine import LlamaFindEngine
from llamafind.data_models import SearchResult
from llamafind.search_engines import google_search # import google_search, bing_search, etc... for mocking


# Helper functions
def create_mock_search_engine(results=None):
    """Creates a mock search engine function"""
    if results is None:
        results = [SearchResult(title="Mock Result", url="http://example.com", snippet="Snippet 1", engine="mock")]

    async def mock_search(query, num_results, proxy_manager=None):
        return results
    return mock_search

@pytest.fixture
def engine_with_mock_engines():
    # Create an engine with mocked search engines
    mock_engines = {
        "google": create_mock_search_engine(),
        "bing": create_mock_search_engine(),
        #mock other engines
    }
    with patch(
        "llamafind.core.engine.google_search", side_effect=mock_engines["google"]
    ), patch(
        "llamafind.core.engine.bing_search", side_effect=mock_engines["bing"]
        # patch other engines
    ):
        engine = LlamaFindEngine()
        engine.search_engines = mock_engines  # replace internal search engine calls
        return engine


@pytest.mark.asyncio
async def test_engine_search_calls_engines(engine_with_mock_engines):
    engine = engine_with_mock_engines
    results = await engine.search(query="test", num_results=2)
    assert len(results) == 2 # Number of engines called.
    assert results[0].engine == "google" # check engine name
    assert results[1].engine == "bing" # check engine name


@pytest.mark.asyncio
async def test_engine_handles_empty_engine_config():
    # Create engine and search
    engine = LlamaFindEngine(config_path='nonexistent.toml') # invalid config path
    results = await engine.search(query="test", num_results=2) # Run a search.
    assert results == [] # Empty list to be returned if there are no valid search engines


def test_load_config_handles_missing_file():
    engine = LlamaFindEngine(config_path="nonexistent.toml")  # Replace with an invalid config path
    config = engine._load_config("nonexistent.toml")
    assert isinstance(config, dict) and not config, "Should return an empty dict"

def test_load_config_handles_invalid_file():
    # Create a config string with invalid format
    # For example without valid toml structure.
    invalid_config_str = """
    invalid_setting =
    """
    with open("invalid.toml", "w") as f:
        f.write(invalid_config_str)

    engine = LlamaFindEngine(config_path="invalid.toml")
    config = engine._load_config("invalid.toml")
    assert isinstance(config, dict) and not config, "Should return an empty dict on invalid config"

    # Clean up the temporary file.
    import os
    os.remove("invalid.toml")
content_copy
download
Use code with caution.
Python

Test Code Example (tests/test_data_models.py):

import pytest
from llamafind.data_models import SearchResult, Proxy

def test_search_result_creation():
    result = SearchResult(title="Test Title", url="http://example.com", snippet="Test Snippet", engine="google")
    assert result.title == "Test Title"
    assert result.url == "http://example.com"
    assert result.snippet == "Test Snippet"
    assert result.engine == "google"
    assert result.raw_data == {}


def test_proxy_creation():
  proxy = Proxy(ip_address="127.0.0.1", port=8080, protocol="http", anonymity="anonymous")
  assert proxy.ip_address == "127.0.0.1"
  assert proxy.port == 8080
  assert proxy.protocol == "http"
  assert proxy.anonymity == "anonymous"
content_copy
download
Use code with caution.
Python

llamafind/deployment/docker/Dockerfile:

FROM python:3.10-slim-bullseye

WORKDIR /app

# Install system dependencies for Playwright
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    firefox \
    webkitgtk \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry

# Copy the project files
COPY pyproject.toml poetry.lock ./
COPY llamafind/ ./llamafind/
COPY llamafind.toml ./  # Copy the config

# Install dependencies
RUN poetry config virtualenvs.create false
RUN poetry install --no-root --only main,dev --no-ansi --no-interaction --no-dev #removed --dev as we are not building
# Create a user and group
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set the user
USER appuser

# Set environment variables (replace with your actual values if necessary)
ENV PYTHONUNBUFFERED 1
ENV OPENAI_API_KEY=""
ENV GROQ_API_KEY=""
# command to run the application
CMD ["python", "-m", "llamafind.cli.cli", "search", "python", "-n", "3", "-c", "llamafind.toml"]
content_copy
download
Use code with caution.
Dockerfile

llamafind/deployment/docker/docker-compose.yml:

version: "3.8"
services:
  app:
    build:
      context: .
      dockerfile: llamafind/deployment/docker/Dockerfile
    ports:
      - "8000:8000"
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY} # Pass your API key
      - GROQ_API_KEY=${GROQ_API_KEY}
    volumes:
      - .:/app  # Mount the current directory (for development)
      # - ./proxies.txt:/app/proxies.txt # mount for proxy (if configured)
content_copy
download
Use code with caution.
Yaml

III. Refined Coding Prompt for AI Model (Complete and Final):

### Task: LlamaFind Super Search Engine - Phase 1 Completion
Create and complete the LlamaFind Python web search engine, following the detailed blueprint below. Build the core modules and unit tests. Focus on functional correctness, modular design, clear code, and complete docstrings. Test all core module functionalities, mock dependencies where necessary, and include code samples.

**Blueprint:**

1.  **Project Setup:**  Your project must be named `llamafind` with this directory structure:
    ```
    llamafind/
    ├── llamafind/
    │   ├── core/
    │   │   ├── engine.py
    │   │   └── __init__.py
    │   ├── search_engines/
    │   │   ├── google.py
    │   │   ├── bing.py
    │   │   ├── duckduckgo.py
    │   │   ├── yahoo.py
    │   │   ├── baidu.py
    │   │   ├── ecosia.py
    │   │   ├── givewater.py
    │   │   ├── pinterest.py
    │   │   └── __init__.py
    ├── scraping/
    │   ├── scraper.py
    │   └── __init__.py
    ├── data_models.py
    ├── llm/
    │   └── llm_interface.py
    ├── llamafind.toml
    ├── setup.cfg
    ├── pyproject.toml
    ├── LICENSE
    └── README.md
    └── tests/
        ├── __init__.py
        ├── test_core_engine.py
        ├── test_google_search.py
        ├── test_bing_search.py
        ├── test_duckduckgo_search.py
        ├── test_yahoo_search.py
        ├── test_baidu_search.py
        ├── test_ecosia_search.py
        ├── test_givewater_search.py
        ├── test_pinterest_search.py
        ├── test_scraper.py
        ├── test_data_models.py
        ├── test_proxy_manager.py
        └── ... (Other Engine Tests)
    ```

2.  **Package Management:** Use `pyproject.toml` to declare all dependencies (use the versions listed above, or the latest compatible versions), including:
    ```toml
    [tool.poetry.dependencies]
    python = ">=3.9,<4.0"
    requests = ">=2.32.3"
    beautifulsoup4 = ">=4.12.2"
    pydantic = ">=2.0"
    toml = ">=0.10.2"
    typing-extensions = ">=4.7.1"
    openai = ">=1.52.0"
    langchain = ">=0.1.12" # For LLMInterface
content_copy
download
Use code with caution.diskcache = ">=5.4.0"
    pyyaml = "*" # config file
    ```

3.  **Licensing:** Include a standard MIT License in the `LICENSE` file.
4.  **README:** Create a `README.md` file. This file MUST contain:
    *   A brief project description.
    *   Installation instructions (using `pip install -e .`).
    *   A basic example of how to use the `search` function.
    *   Instructions for running the tests.
5.  **Configuration File:**  Create `llamafind.toml` in the top-level directory.  Include a default configuration for:
    ```toml
    # Configure the search engines, the API keys for these engines, and the LLM you want to use.
    default_search_engines = ["google", "duckduckgo", "bing"]
    ```
6.  **`llamafind/core/engine.py` (Core Engine Module)**
    *   Implement the `LlamaFindEngine` class.
    *   Implement a `main` function to handle CLI arguments using `argparse`.
        *   Arguments: `query`, `--num-results` (default: 10), `--engine` (default: ['google', 'duckduckgo', 'bing']), `--config` (default: `llamafind.toml`), `--output-format` (default: 'text', choices: 'text', 'json', 'csv', 'markdown'), `--verbose` or `-v`.
        *   Implement argument parsing and print help message.
    *   Implement the `search` function (asynchronous):
        *   Takes `query` (str) and `num_results` (int) as input.
        *   Loads search engines based on the configuration. If no engines are configured, default to `google`, `duckduckgo`, and `bing`.
        *   Uses `asyncio.gather` to concurrently call the `search` functions from search engine modules for each engine.
        *   Includes a placeholder for the LLM (call to `_llm.refine_query` and `_llm.summarize_results` – to be implemented in later phases. For now these should just return the input).
        *   Implements basic error handling with try-except blocks, logging errors.
        *   Loads configuration settings from the `llamafind.toml` configuration file.
        *   Return a list of `SearchResult` objects (defined in `llamafind/data_models.py`).
    *   Implement unit tests using `pytest` and `pytest-asyncio` to validate:
        *   CLI argument parsing (mocking for testing).
        *   Configuration loading (mocking).
        *   Basic search engine orchestration (mock the search engine modules for these tests).
        *   Error handling in `search` (mocking).
        *   Testing the proxy setup and loading from file in `_load_proxy_manager()`

7.  **`llamafind/search_engines/` (Search Engine Modules):**
    *   Implement `google.py`, `bing.py`, and `duckduckgo.py` (Yahoo, Baidu, Ecosia, Givewater, Pinterest as well for more results - see their requirements).
    *   In each module, implement an `async` search function (e.g., `google_search`) that takes a `query` (str), `num_results` (int), and `proxy_manager` (optional) as input.
        *   Construct the search engine-specific URL using the query and `num_results` and add a User-Agent Header.
        *   Use `requests.get` with a timeout of 15 seconds to fetch the HTML search results page, and configure proxies from the proxy manager.
        *   Parse the HTML using `BeautifulSoup4` to extract title, URL, and snippet from search results. Use CSS selectors for parsing (inspect browser for the right selectors.)
        *   Structure the extracted data into `SearchResult` objects.
        *   Implement basic error handling (HTTP status code checks, catch `requests` exceptions and log).
        *   Implement unit tests using `pytest` to validate result parsing and data structuring.  Mock network requests for testing.

8.  **`llamafind/scraping/scraper.py` (Generic Web Scraper)**
    *   Implement the `WebScraper` class.
    *   Implement `async` methods:
        *   `fetch_html(url: str) -> str`: Uses `requests.get` to fetch HTML content. Include basic error handling.
        *   `get_soup(html_content: str) -> BeautifulSoup`: Parses HTML content using `BeautifulSoup4`.
        *   `get_text(url: str) -> str`: Extracts text content from HTML, handling whitespace.
        *   `get_links(url: str) -> List[Dict[str, str]]`: Extracts links (href and text) from the HTML. Ensure URLs are absolute using `urllib.parse.urljoin()`.
        *   `get_images(url: str) -> List[str]`: Extracts image URLs from HTML.
        *   `get_tables(url: str) -> List[str]`:  Extracts raw HTML of tables from the HTML.
    *   Implement unit tests using `pytest` to verify each scraping utility function, using mock HTML content.

9.  **`llamafind/data_models.py` (Data Models)**
    *   Implement the `SearchResult`, `ScrapeResult` and `Proxy` Pydantic models.

10. **`llamafind/llm/llm_interface.py` (LLM Interface):**
    *   Implement the `LLMInterface` class
    *   Implement the `chat` method.

**Testing (`tests/`)**

*   Create a separate test file (e.g., `tests/test_core_engine.py`) for each module.
*   **Unit Tests**: Write unit tests for each function and method in each module.
    *   Use `pytest` to run tests.
    *   **Mocking:** Use `unittest.mock.patch` or `pytest-mock` to mock external dependencies (e.g., network requests, LLM calls). Mock network calls in the search engine modules using `requests_mock` if helpful to generate predictable network requests. Mock the LLM calls.
    *   **Coverage**: Aim for 100% code coverage, but at least 70% for all core functionalities.

**Implementation Details:**

*   **Configuration:** Use the `toml` package to load the configuration from `llamafind.toml`.
*   **User-Agent:**  For scraping, use a reasonable default user agent in `WebScraper` if one isn't provided, and provide functionality to set a custom UA. Use `simple-header` for good default user agents.
*   **Async Handling:**  All network operations should be `async`.
*   **Error Handling:** Implement robust error handling with informative error messages and logging. Use custom exceptions as needed.

**Coding Prompt - AI, Start Coding Here:**

```python
### 1. `llamafind/data_models.py`
from typing import List, Optional
from pydantic import BaseModel, Field

# Define the Search Result Data Model
class SearchResult(BaseModel):
    """
    Represents a single search result from a search engine.

    Attributes:
        title (str): The title of the search result.
        url (str): The URL of the search result.
        snippet (str): A brief description or snippet of the search result.
        engine (str): The name of the search engine (e.g., "google", "bing").
        image_url (Optional[str]): URL of an image associated with the result, if available.
        raw_data (dict): Original data scraped.
    """
    title: str = Field(..., description="The title of the search result")
    url: str = Field(..., description="The URL of the search result")
    snippet: str = Field(..., description="A brief description or snippet of the search result")
    engine: str = Field(..., description="The name of the search engine")
    image_url: Optional[str] = Field(None, description="URL of an image associated with the result")
    raw_data: dict = Field({}, description="Original raw data from the scraper")


# Define the Scrape Result Data Model
class ScrapeResult(BaseModel):
    """
    Represents the result of scraping a web page.

    Attributes:
        url (str): The URL of the scraped page.
        text_content (str): The extracted text content of the page.
        links (List[str]): List of all extracted links on the page.
        image_urls (List[str]): List of extracted image URLs.
        tables (List[str]): Raw HTML of extracted tables.
        metadata (Dict): Dictionary containing metadata about the scraped page.
    """
    url: str = Field(..., description="The URL of the scraped page")
    text_content: str = Field(..., description="The text content of the page")
    links: list[str] = Field(..., description="Links found on the page")
    image_urls: list[str] = Field(..., description="Image URLs found on the page")
    tables: list[str] = Field(..., description="Raw HTML of tables found on the page")  # raw html for tables
    metadata: dict = Field({}, description="Metadata about the page")


# Define the Proxy Data Model
class Proxy(BaseModel):
    """
    Represents a proxy server.

    Attributes:
        ip_address (str): The IP address or domain name of the proxy.
        port (int): The port number of the proxy.
        protocol (str):  Protocol (e.g., "http", "https", "socks4", "socks5").
        username (Optional[str]): Username for proxy authentication.
        password (Optional[str]): Password for proxy authentication.
        anonymity (str): "transparent", "anonymous", or "elite".
        latency (float): Measured response time, in seconds (optional).
        country (str): Country code (e.g., "US") (optional).
    """
    ip_address: str = Field(..., description="The IP address or domain name of the proxy")
    port: int = Field(..., description="The port number of the proxy")
    protocol: str = Field(..., description="The proxy protocol")
    username: Optional[str] = Field(None, description="Username for proxy authentication")
    password: Optional[str] = Field(None, description="Password for proxy authentication")
    anonymity: str = Field(description="Proxy anonymity level")
    latency: Optional[float] = Field(None, description="Latency of proxy")
    country: Optional[str] = Field(None, description="Country of proxy")
content_copy
download
Use code with caution.
Python
### 2. `llamafind/llm/llm_interface.py`
#llamafind/llm/llm_interface.py
from __future__ import annotations

import asyncio
import logging
from typing import List, Dict, Tuple, Optional, Any
from llamafind.data_models import SearchResult
from instructor.function_calls import Mode
from openai import OpenAI, AsyncOpenAI
from pydantic import BaseModel, Field
from typing import Iterable, Union

logger = logging.getLogger(__name__)


class LLMInterface:
    """
    Interface for interacting with an LLM and defining function calls.
    """

    def __init__(self, provider: str, model: str, api_key: str, llm_config: Dict[str, Any]):
        """
        Initializes the LLMInterface.

        Args:
            provider (str): The LLM provider (e.g., "openai").
            model (str): The specific LLM model name (e.g., "gpt-4o").
            api_key (str): The API key for the LLM provider.
        """
        self.provider = provider.lower()  # Lowercase to handle different inputs
        self.model = model
        self.api_key = api_key
        self.llm_config = llm_config
        self.client = self._initialize_client()  # Initialize the client during init
        self.model_name = model
        self.mode = Mode.JSON

    def _initialize_client(self):
        """
        Initializes the OpenAI client.
        """
        if self.provider == "openai":
            client = OpenAI(api_key=self.api_key)
            instructor_client = instructor.from_openai(client, mode=self.mode) # Pass a model and its features.
            return instructor_client
        if self.provider == "groq":
            import groq
            client = groq.Groq(api_key=self.api_key)
            instructor_client = instructor.from_groq(client, mode=self.mode) # Pass a model and its features.
            return instructor_client
        # Add other providers here
        raise ValueError(f"Unsupported LLM provider: {self.provider}")

    def refine_query(self, query: str, search_results: List[SearchResult]) -> str:
        """
        Placeholder implementation of a query refinement function.

        Args:
            query (str): The original search query.
            search_results (List[SearchResult]): The search results obtained from the initial search.

        Returns:
            str: Refined search query.
        """
        logger.info("Refining query")
        # Replace with actual implementation using the LLM in Phase 3
        return query

    def summarize_results(self, search_results: List[SearchResult], original_query: str) -> List[SearchResult]:
        """
        Placeholder implementation of a summarization function.

        Args:
            search_results (List[SearchResult]): The search results to summarize.
            original_query (str): The original search query.

        Returns:
            List[SearchResult]: The summarized search results.
        """
        logger.info("Summarizing results")
        # Replace with actual LLM-based summarization implementation in Phase 3
        return search_results  # Return the same results for now, modify them later with LLM.

    def classify_result(self, search_result: SearchResult, categories: list[str]) -> dict:
        """Classifies a search result"""
        pass # WIP - for the LLM-based part

    def extract_information(self, scrape_result: ScrapeResult, information_needs: List[str]) -> ScrapeResult:
        """Extracts information from scrape result using the specified data structure"""
        pass # WIP - for the LLM-based part

    def chat(self, prompt:str, response_model: BaseModel, temperature:float=0.1, **kwargs) -> BaseModel:
        # The base method for calling the LLM.  Will also need to implement the batch method.
        messages = [{"role": "user", "content": prompt}]

        response = self.client.chat.completions.create(
            model=self.model_name,
            messages=messages,
            response_model=response_model,
            temperature=temperature,
            **kwargs
        )
        return response

    def create(self, messages: List[Dict[str,str]], response_model:BaseModel, temperature:float =0.1) -> Any:
      return self.client.chat.completions.create(
        model=self.model_name,
        messages=messages,
        response_model=response_model,
        temperature=temperature,
      )
content_copy
download
Use code with caution.
Python
### 3. `llamafind/scraping/scraper.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup
from fake_useragent import UserAgent
import re
from llamafind.data_models import ScrapeResult

logger = logging.getLogger(__name__)


class WebScraper:
    """
    A basic web scraper.
    """

    def __init__(self, user_agent: str = None, proxies: Optional[Dict[str, str]] = None, timeout: int = 15):
        """
        Initialize the WebScraper.

        Args:
            user_agent (str): User-Agent string to use for requests.
            proxies (Optional[Dict[str, str]]): Optional dictionary of proxies to use (see requests library).
            timeout (int): Timeout for requests in seconds.
        """
        self.user_agent = user_agent or self.get_random_user_agent()
        self.proxies = proxies or {}
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": self.user_agent})
        self.timeout = timeout

    def get_random_user_agent(self) -> str:
        """
        Generates a random user agent string.

        Returns:
            str: A random user agent.
        """
        ua = UserAgent()
        return ua.random

    def fetch_page(self, url: str) -> Optional[str]:
        """
        Fetches the HTML content of a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            Optional[str]: The HTML content as a string, or None if the request fails.
        """
        try:
            logger.debug(f"Fetching URL: {url} using proxy {self.proxies if self.proxies else 'No Proxy'}")
            response = self.session.get(url, timeout=self.timeout, proxies=self.proxies)
            response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
            return response.text
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch {url}: {e}")
            return None

    def get_soup(self, html_content: str) -> Optional[BeautifulSoup]:
        """
        Parses HTML content using BeautifulSoup.

        Args:
            html_content (str): The HTML content as a string.

        Returns:
            Optional[BeautifulSoup]: A BeautifulSoup object, or None if parsing fails.
        """
        try:
            return BeautifulSoup(html_content, "html.parser")
        except Exception as e:
            logger.error(f"Failed to parse HTML: {e}")
            return None

    def get_text(self, url: str) -> str:
        """
        Extracts the full text content of a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            str: The extracted text content.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return ""
        soup = self.get_soup(html_content)
        return soup.get_text(separator=" ", strip=True) if soup else ""

    def get_links(self, url: str) -> List[Dict[str, str]]:
        """
        Extracts all links from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[Dict[str, str]]: A list of dictionaries, where each dictionary represents a link with 'text' and 'href' keys.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        links = []
        if soup:
            for a in soup.find_all("a", href=True):
                text = a.get_text(strip=True)
                href = a["href"]
                absolute_url = self._make_absolute(url, href)
                links.append({"text": text, "href": absolute_url})
        return links

    def get_images(self, url: str) -> List[str]:
        """
        Extracts all image URLs from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[str]: A list of image URLs.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        image_urls = []
        if soup:
            for img in soup.find_all("img", src=True):
                src = img["src"]
                absolute_url = self._make_absolute(url, src)
                image_urls.append(absolute_url)
        return image_urls

    def get_tables(self, url: str) -> List[str]:
        """
        Extracts all tables from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[str]: A list of table strings.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        tables = []
        if soup:
            for table in soup.find_all("table"):
                tables.append(str(table))  # Return raw HTML
        return tables

    def _make_absolute(self, base_url, url):
        """Helper to convert relative URLs to absolute URLs."""
        from urllib.parse import urljoin

        return urljoin(base_url, url)


class SeleniumScraper(WebScraper):
    """
    A web scraper that uses Selenium to render dynamic content.
    """

    def __init__(
            self,
            user_agent: Optional[str] = None,
            proxies: Optional[Dict[str, str]] = None,
            headless: bool = True,
            driver_path: Optional[str] = None,
            timeout: int = 15,
    ):
        from selenium import webdriver
        from selenium.webdriver.firefox.options import Options as FirefoxOptions
        from selenium.webdriver.chrome.options import Options as ChromeOptions
        from selenium.webdriver.chrome.service import Service as ChromeService
        from selenium.webdriver.firefox.service import Service as FirefoxService
        from selenium.webdriver.remote.webdriver import WebDriver
        from webdriver_manager.chrome import ChromeDriverManager
        from webdriver_manager.firefox import GeckoDriverManager

        super().__init__(user_agent, proxies, timeout)
        self.headless = headless
        self.driver_path = driver_path
        self.driver: Optional[WebDriver] = None

        self.driver_type: str = "chromium"  # Or "firefox"

    def fetch_page(self, url: str) -> Optional[str]:
        """
        Fetches the HTML content of a web page using Selenium.

        Args:
            url (str): The URL of the web page.

        Returns:
            Optional[str]: The HTML content as a string, or None if the request fails.
        """
        try:
            self._setup_driver()
            self.driver.get(url)
            self._wait_for_page_load()
            return self.driver.page_source
        except Exception as e:
            logger.error(f"Failed to fetch (Selenium) {url}: {e}")
            return None
        finally:
            self._teardown_driver()

    def get_soup(self, html_content: str) -> Optional[BeautifulSoup]:
        """
        Parses HTML content using BeautifulSoup.

        Args:
            html_content (str): The HTML content as a string.

        Returns:
            Optional[BeautifulSoup]: A BeautifulSoup object, or None if parsing fails.
        """
        if not html_content:
            return None
        try:
            return BeautifulSoup(html_content, "html.parser")
        except Exception as e:
            logger.error(f"Failed to parse HTML (Selenium): {e}")
            return None

    def _setup_driver(self):
        """Set up the Selenium WebDriver (Chromium or Firefox)."""
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options as ChromeOptions
        from selenium.webdriver.chrome.service import Service as ChromeService
        from selenium.webdriver.firefox.options import Options as FirefoxOptions
        from selenium.webdriver.firefox.service import Service as FirefoxService
        from webdriver_manager.chrome import ChromeDriverManager
        from webdriver_manager.firefox import GeckoDriverManager
        from selenium.webdriver.remote.webdriver import WebDriver

        if self.driver:
            return # already set

        if self.driver_type == "chromium":
            chrome_options = ChromeOptions()
            if self.headless:
                chrome_options.add_argument("--headless")  # Run in headless mode
            if self.user_agent:
                chrome_options.add_argument(f"--user-agent={self.user_agent}")
            if self.proxies:
                # Configure proxy for Selenium
                # Only single proxy supported
                proxy = list(self.proxies.values())[0]
                if isinstance(proxy, str):
                  chrome_options.add_argument(f"--proxy-server={proxy}")
                else:
                  logger.error(f"Selenium only supports string based proxies. Got {type(proxy)=}")
            if self.driver_path:
                try:
                    service = ChromeService(executable_path=self.driver_path)
                    self.driver = webdriver.Chrome(service=service, options=chrome_options)
                except Exception as e:
                    logger.error(f"Chrome not found at location: {self.driver_path=}, defaulting to chrome webdriver manager. {e}")
                    self.driver = webdriver.Chrome(ChromeDriverManager().install(), options=chrome_options) # Use webdriver_manager
            else:
                self.driver = webdriver.Chrome(ChromeDriverManager().install(), options=chrome_options) # Use webdriver_manager
        elif self.driver_type == "firefox":
            firefox_options = FirefoxOptions()
            if self.headless:
                firefox_options.add_argument("--headless")  # Run in headless mode
            if self.user_agent:
                firefox_options.add_argument(f"--user-agent={self.user_agent}")
            if self.proxies:
                # Configure proxy for Selenium
                # Only single proxy supported
                proxy = list(self.proxies.values())[0]
                if isinstance(proxy, str):
                  firefox_options.add_argument(f"--proxy-server={proxy}")
                else:
                  logger.error(f"Selenium only supports string based proxies. Got {type(proxy)=}")

            if self.driver_path:
              try:
                service = FirefoxService(executable_path=self.driver_path)
                self.driver = webdriver.Firefox(service=service, options=firefox_options)
              except Exception as e:
                logger.error(f"Firefox not found at location: {self.driver_path=}, defaulting to firefox webdriver manager. {e}")
                self.driver = webdriver.Firefox(executable_path=GeckoDriverManager().install(), options=firefox_options) # Use webdriver_manager
            else:
                self.driver = webdriver.Firefox(executable_path=GeckoDriverManager().install(), options=firefox_options) # Use webdriver_manager
        else:
            raise ValueError(f"Unsupported driver type: {self.driver_type}")
        if self.timeout:
          self.driver.set_page_load_timeout(self.timeout) #Set time out

    def _wait_for_page_load(self):
        """Waits for page to load (can be customized) - Example:
            - waiting for document ready state to be complete
        """
        # can be customized, example:
        from selenium.webdriver.support.ui import WebDriverWait
        from selenium.webdriver.support import expected_conditions as EC
        from selenium.webdriver.common.by import By

        try:
            WebDriverWait(self.driver, self.timeout).until(
                EC.presence_of_element_located((By.TAG_NAME, "body"))  # Example
            )
        except Exception as e:
            logger.error(f"Error while waiting for page to load: {e}")

    def _teardown_driver(self):
        """Tear down the Selenium WebDriver."""
        if self.driver:
            try:
                self.driver.quit()
            except Exception as e:
                logger.error(f"Error closing the Selenium driver: {e}")
            self.driver = None
content_copy
download
Use code with caution.
Python
### 4. `llamafind/core/engine.py`
import asyncio
import logging
import toml  # For configuration file parsing
import argparse
from typing import List, Dict, Tuple, Optional
from llamafind.search_engines import (
    google_search,
    bing_search,
    duckduckgo_search,
    yahoo_search,
    baidu_search,
    ecosia_search,
    givewater_search,
    pinterest_search,
)
from llamafind.scraping import scraper
from llamafind.data_models import SearchResult, Proxy, ScrapeResult  # Import Data models
from llamafind.llm.llm_interface import LLMInterface  # Placeholder for MLX LLM Integration
from urllib.parse import urlparse
import re

logger = logging.getLogger(__name__)

# Define the main entry point
def main():
  # Create the parser
  parser = argparse.ArgumentParser(description="LlamaFind: Your Intelligent Web Search Engine")

  # Add the required arguments for the search
  parser.add_argument("query", help="The search query")
  parser.add_argument(
      "-n", "--num-results", type=int, default=10, help="Number of search results per engine"
  )
  parser.add_argument(
      "-e",
      "--engine",
      nargs="+",
      default=["google", "duckduckgo", "bing"],
      choices=["google", "bing", "duckduckgo", "yahoo", "baidu", "ecosia", "givewater", "pinterest"],
      help="Search engines to use (e.g., google, bing, duckduckgo).",
  )
  parser.add_argument(
      "-c", "--config", type=str, default="llamafind.toml", help="Path to the configuration file."
  )
  parser.add_argument(
    "-f", "--output-format", type=str, default="text", help="Output format for CLI results ('text', 'json', 'csv', 'markdown')."
  )
  parser.add_argument(
    "-v", "--verbose", action="store_true", help="Enable verbose logging."
  )

  # Parse the arguments
  args = parser.parse_args()

  # Set up the logging
  log_level = logging.DEBUG if args.verbose else logging.INFO
  logging.basicConfig(level=log_level, stream=sys.stderr)
  logger = logging.getLogger(__name__)

  # Instantiate and run the LlamaFindEngine
  engine = LlamaFindEngine(args.config)
  asyncio.run(engine.search(args.query, args.num_results))
content_copy
download
Use code with caution.
Python
### 5. `llamafind/search_engines/__init__.py`
#from .google import google_search
#from .bing import bing_search
#from .duckduckgo import duckduckgo_search
#from .yahoo import yahoo_search
#from .baidu import baidu_search
#from .ecosia import ecosia_search
#from .givewater import givewater_search
#from .pinterest import pinterest_search

# from . import *  # or explicit imports to prevent namespace pollution
content_copy
download
Use code with caution.
Python
### 6. `llamafind/search_engines/google.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def google_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Google search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Google for '{query}' (Results: {num_results})")
    base_url = "https://www.google.com/search"
    params = {"q": query, "num": num_results}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="g"):
            title_element = result.find("h3")
            link_element = result.find("a")
            snippet_element = result.find("span", class_="st")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="google")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Google search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 7. `llamafind/search_engines/bing.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def bing_search(query: str, num_results
content_copy
download
Use code with caution.
Python: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Bing search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Bing for '{query}' (Results: {num_results})")
    base_url = "https://www.bing.com/search"
    params = {"q": query, "count": num_results}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("li", class_="b_algo"):
            title_element = result.find("h2")
            link_element = result.find("a")
            snippet_element = result.find("p", class_="b_snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="bing")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Bing search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 8. `llamafind/search_engines/duckduckgo.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def duckduckgo_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a DuckDuckGo search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching DuckDuckGo for '{query}' (Results: {num_results})")
    base_url = "https://duckduckgo.com/html"
    params = {"q": query, "max_results": num_results}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="result"):
            title_element = result.find("h2", class_="result__title")
            link_element = result.find("a", class_="result__a")
            snippet_element = result.find("div", class_="result__snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="duckduckgo")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing DuckDuckGo search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 9. `llamafind/search_engines/yahoo.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def yahoo_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Yahoo search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Yahoo for '{query}' (Results: {num_results})")
    base_url = "https://search.yahoo.com/search"
    params = {"q": query, "n": num_results} # 'n' used instead of num.

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="NewsArticle"): #Updated for yahoo
            title_element = result.find("h3", class_="title")
            link_element = result.find("a", class_="thmb")
            snippet_element = result.find("p", class_="txt")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="yahoo")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Yahoo search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 10. `llamafind/search_engines/baidu.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def baidu_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Baidu search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Baidu for '{query}' (Results: {num_results})")
    base_url = "https://www.baidu.com/s"
    params = {"wd": query, "rn": num_results} # Use 'rn' instead of num

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="result c-container"):
            title_element = result.find("h3", class_="t")
            link_element = result.find("a")  # Usually the first a tag inside
            snippet_element = result.find("div", class_="c-abstract")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="baidu")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Baidu search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 11. `llamafind/search_engines/ecosia.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def ecosia_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs an Ecosia search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Ecosia for '{query}' (Results: {num_results})")
    base_url = "https://www.ecosia.org/search"
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="results-list-container"):
            title_element = result.find("a", class_="result__title-link")
            link_element = result.find("a", class_="result__url") #Updated for ecosia
            snippet_element = result.find("p", class_="result__snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="ecosia")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Ecosia search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 12. `llamafind/search_engines/givewater.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def givewater_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a GiveWater search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching GiveWater for '{query}' (Results: {num_results})")
    base_url = "https://search.givewater.com/serp"
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="web-bing__result"):
            title_element = result.find("a")
            link_element = result.find("a")
            snippet_element = result.find("p", class_="b_snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="givewater")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing GiveWater search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 13. `llamafind/search_engines/pinterest.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def pinterest_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Pinterest search for the given query.
    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Pinterest for '{query}' (Results: {num_results})")
    base_url = "https://www.pinterest.com/search/pins/" # The base url has been added to the method.
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "X-Requested-With": "XMLHttpRequest",
        "Accept": "application/json",
        # Adding Accept-Language Header
        "Accept-Language": "en-US,en;q=0.9"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        # Pinterest returns JSON data.
        data = response.json()
        results: List[SearchResult] = []
        for item in data.get('pins', []):
            title = item.get('title')
            url = item.get('url')
            if title and url:
                results.append(SearchResult(title=title, url=url, engine="pinterest", image_url=item.get('images').get('orig').get('url')))
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Pinterest search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(14) llamafind/scraping/scraper.py (WebScraper - Implemented)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup
from fake_useragent import UserAgent
import re
from llamafind.data_models import ScrapeResult

logger = logging.getLogger(__name__)


class WebScraper:
    """
    A basic web scraper.
    """

    def __init__(self, user_agent: str = None, proxies: Optional[Dict[str, str]] = None, timeout: int = 15):
        """
        Initialize the WebScraper.

        Args:
            user_agent (str): User-Agent string to use for requests.
            proxies (Optional[Dict[str, str]]): Optional dictionary of proxies to use (see requests library).
            timeout (int): Timeout for requests in seconds.
        """
        self.user_agent = user_agent or self.get_random_user_agent()
        self.proxies = proxies or {}
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": self.user_agent})
        self.timeout = timeout

    def get_random_user_agent(self) -> str:
        """
        Generates a random user agent string.

        Returns:
            str: A random user agent.
        """
        ua = UserAgent()
        return ua.random

    def fetch_page(self, url: str) -> Optional[str]:
        """
        Fetches the HTML content of a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            Optional[str]: The HTML content as a string, or None if the request fails.
        """
        try:
            logger.debug(f"Fetching URL: {url} using proxy {self.proxies if self.proxies else 'No Proxy'}")
            response = self.session.get(url, timeout=self.timeout, proxies=self.proxies)
            response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
            return response.text
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch {url}: {e}")
            return None

    def get_soup(self, html_content: str) -> Optional[BeautifulSoup]:
        """
        Parses HTML content using BeautifulSoup.

        Args:
            html_content (str): The HTML content as a string.

        Returns:
            Optional[BeautifulSoup]: A BeautifulSoup object, or None if parsing fails.
        """
        try:
            return BeautifulSoup(html_content, "html.parser")
        except Exception as e:
            logger.error(f"Failed to parse HTML: {e}")
            return None

    def get_text(self, url: str) -> str:
        """
        Extracts the full text content of a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            str: The extracted text content.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return ""
        soup = self.get_soup(html_content)
        return soup.get_text(separator=" ", strip=True) if soup else ""

    def get_links(self, url: str) -> List[Dict[str, str]]:
        """
        Extracts all links from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[Dict[str, str]]: A list of dictionaries, where each dictionary represents a link with 'text' and 'href' keys.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        links = []
        if soup:
            for a in soup.find_all("a", href=True):
                text = a.get_text(strip=True)
                href = a["href"]
                absolute_url = self._make_absolute(url, href)
                links.append({"text": text, "href": absolute_url})
        return links

    def get_images(self, url: str) -> List[str]:
        """
        Extracts all image URLs from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[str]: A list of image URLs.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        image_urls = []
        if soup:
            for img in soup.find_all("img", src=True):
                src = img["src"]
                absolute_url = self._make_absolute(url, src)
                image_urls.append(absolute_url)
        return image_urls

    def get_tables(self, url: str) -> List[str]:
        """
        Extracts all tables from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[str]: A list of table strings.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        tables = []
        if soup:
            for table in soup.find_all("table"):
                tables.append(str(table))  # Return raw HTML
        return tables

    def _make_absolute(self, base_url, url):
        """Helper to convert relative URLs to absolute URLs."""
        from urllib.parse import urljoin

        return urljoin(base_url, url)


class SeleniumScraper(WebScraper):
    """
    A web scraper that uses Selenium to render dynamic content.
    """

    def __init__(
            self,
            user_agent: Optional[str] = None,
            proxies: Optional[Dict[str, str]] = None,
            headless: bool = True,
            driver_path: Optional[str] = None,
            timeout: int = 15,
    ):
        from selenium import webdriver
        from selenium.webdriver.firefox.options import Options as FirefoxOptions
        from selenium.webdriver.chrome.options import Options as ChromeOptions
        from selenium.webdriver.chrome.service import Service as ChromeService
        from selenium.webdriver.firefox.service import Service as FirefoxService
        from selenium.webdriver.remote.webdriver import WebDriver
        from webdriver_manager.chrome import ChromeDriverManager
        from webdriver_manager.firefox import GeckoDriverManager

        super().__init__(user_agent, proxies, timeout)
        self.headless = headless
        self.driver_path = driver_path
        self.driver: Optional[WebDriver] = None

        self.driver_type: str = "chromium"  # Or "firefox"

    def fetch_page(self, url: str) -> Optional[str]:
        """
        Fetches the HTML content of a web page using Selenium.

        Args:
            url (str): The URL of the web page.

        Returns:
            Optional[str]: The HTML content as a string, or None if the request fails.
        """
        try:
            self._setup_driver()
            self.driver.get(url)
            self._wait_for_page_load()
            return self.driver.page_source
        except Exception as e:
            logger.error(f"Failed to fetch (Selenium) {url}: {e}")
            return None
        finally:
            self._teardown_driver()

    def get_soup(self, html_content: str) -> Optional[BeautifulSoup]:
        """
        Parses HTML content using BeautifulSoup.

        Args:
            html_content (str): The HTML content as a string.

        Returns:
            Optional[BeautifulSoup]: A BeautifulSoup object, or None if parsing fails.
        """
        if not html_content:
            return None
        try:
            return BeautifulSoup(html_content, "html.parser")
        except Exception as e:
            logger.error(f"Failed to parse HTML (Selenium): {e}")
            return None

    def _setup_driver(self):
        """Set up the Selenium WebDriver (Chromium or Firefox)."""
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options as ChromeOptions
        from selenium.webdriver.chrome.service import Service as ChromeService
        from selenium.webdriver.firefox.options import Options as FirefoxOptions
        from selenium.webdriver.firefox.service import Service as FirefoxService
        from webdriver_manager.chrome import ChromeDriverManager
        from webdriver_manager.firefox import GeckoDriverManager
        from selenium.webdriver.remote.webdriver import WebDriver

        if self.driver:
            return # already set

        if self.driver_type == "chromium":
            chrome_options = ChromeOptions()
            if self.headless:
                chrome_options.add_argument("--headless")  # Run in headless mode
            if self.user_agent:
                chrome_options.add_argument(f"--user-agent={self.user_agent}")
            if self.proxies:
                # Configure proxy for Selenium
                # Only single proxy supported
                proxy = list(self.proxies.values())[0]
                if isinstance(proxy, str):
                  chrome_options.add_argument(f"--proxy-server={proxy}")
                else:
                  logger.error(f"Selenium only supports string based proxies. Got {type(proxy)=}")
            if self.driver_path:
                try:
                    service = ChromeService(executable_path=self.driver_path)
                    self.driver = webdriver.Chrome(service=service, options=chrome_options)
                except Exception as e:
                    logger.error(f"Chrome not found at location: {self.driver_path=}, defaulting to chrome webdriver manager. {e}")
                    self.driver = webdriver.Chrome(ChromeDriverManager().install(), options=chrome_options) # Use webdriver_manager
            else:
                self.driver = webdriver.Chrome
content_copy
download
Use code with caution.
Python### 10. `llamafind/search_engines/duckduckgo.py` (DuckDuckGo Search - Implemented)
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)

async def duckduckgo_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a DuckDuckGo search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching DuckDuckGo for '{query}' (Results: {num_results})")
    base_url = "https://duckduckgo.com/html"
    params = {"q": query, "max_results": num_results}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="result"):
            title_element = result.find("h2", class_="result__title")
            link_element = result.find("a", class_="result__a")
            snippet_element = result.find("div", class_="result__snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="duckduckgo")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing DuckDuckGo search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(11) llamafind/search_engines/yahoo.py (Yahoo Search - Implemented)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def yahoo_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Yahoo search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Yahoo for '{query}' (Results: {num_results})")
    base_url = "https://search.yahoo.com/search"
    params = {"q": query, "n": num_results} # 'n' used instead of num.

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="NewsArticle"): #Updated for yahoo
            title_element = result.find("h3", class_="title")
            link_element = result.find("a", class_="thmb")
            snippet_element = result.find("p", class_="txt")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="yahoo")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Yahoo search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(12) llamafind/search_engines/baidu.py (Baidu Search - Implemented)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def baidu_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Baidu search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Baidu for '{query}' (Results: {num_results})")
    base_url = "https://www.baidu.com/s"
    params = {"wd": query, "rn": num_results} # Use 'rn' instead of num

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="result c-container"):
            title_element = result.find("h3", class_="t")
            link_element = result.find("a")  # Usually the first a tag inside
            snippet_element = result.find("div", class_="c-abstract")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="baidu")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Baidu search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(13) llamafind/search_engines/ecosia.py (Ecosia Search - Implemented)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def ecosia_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs an Ecosia search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Ecosia for '{query}' (Results: {num_results})")
    base_url = "https://www.ecosia.org/search"
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="results-list-container"):
            title_element = result.find("a", class_="result__title-link")
            link_element = result.find("a", class_="result__url") #Updated for ecosia
            snippet_element = result.find("p", class_="result-snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="ecosia")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Ecosia search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(14) llamafind/search_engines/givewater.py (GiveWater Search - Implemented)

import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def givewater_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a GiveWater search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching GiveWater for '{query}' (Results: {num_results})")
    base_url = "https://search.givewater.com/serp"
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="web-bing__result"):
            title_element = result.find("a")
            link_element = result.find("a")
            snippet_element = result.find("p", class_="b_snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="givewater")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing GiveWater search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(15) llamafind/search_engines/pinterest.py (Pinterest Search - Implemented)import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def pinterest_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Pinterest search for the given query.
    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Pinterest for '{query}' (Results: {num_results})")
    base_url = "https://www.pinterest.com/search/pins/" # The base url has been added to the method.
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "X-Requested-With": "XMLHttpRequest",
        "Accept": "application/json",
        # Adding Accept-Language Header
        "Accept-Language": "en-US,en;q=0.9"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        # Pinterest returns JSON data.
        data = response.json()
        results: List[SearchResult] = []
        for item in data.get('pins', []):
            title = item.get('title')
            url = item.get('url')
            if title and url:
                results.append(SearchResult(title=title, url=url, engine="pinterest", image_url=item.get('images').get('orig').get('url')))
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Pinterest search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(19) llamafind/llm/llm_interface.py (LLM Interface)

import asyncio
import logging
from typing import List, Dict, Tuple, Optional, Any
from llamafind.data_models import SearchResult
from instructor.function_calls import Mode
from openai import OpenAI, AsyncOpenAI
from pydantic import BaseModel, Field
from typing import Iterable, Union
import instructor

logger = logging.getLogger(__name__)

class LLMInterface:
    """
    Interface for interacting with an LLM and defining function calls.
    """

    def __init__(self, provider: str, model: str, api_key: str, llm_config: Dict[str, Any]):
        """
        Initializes the LLMInterface.

        Args:
            provider (str): The LLM provider (e.g., "openai").
            model (str): The specific LLM model name (e.g., "gpt-4o").
            api_key (str): The API key for the LLM provider.
        """
        self.provider = Provider(provider)
        self.model = model
        self.api_key = api_key
        self.llm_config = llm_config
        self.client = self._initialize_client()  # Initialize the client during init
        self.model_name = model
        self.mode = Mode.JSON

    def _initialize_client(self):
        """
        Initializes the OpenAI client.
        """
        if self.provider == Provider.OPENAI:
            client = OpenAI(api_key=self.api_key)
            instructor_client = instructor.from_openai(client, mode=self.mode) # Pass a model and its features.
            return instructor_client
        if self.provider == Provider.GROQ:
            import groq
            client = groq.Groq(api_key=self.api_key)
            instructor_client = instructor.from_groq(client, mode=self.mode) # Pass a model and its features.
            return instructor_client
        # Add other providers here
        raise ValueError(f"Unsupported LLM provider: {self.provider}")

    def refine_query(self, query: str, search_results: List[SearchResult]) -> str:
        """
        Placeholder implementation of a query refinement function.

        Args:
            query (str): The original search query.
            search_results (List[SearchResult]): The search results obtained from the initial search.

        Returns:
            str: Refined search query.
        """
        logger.info("Refining query")
        # Replace with actual implementation using the LLM in Phase 3
        return query

    def summarize_results(self, search_results: List[SearchResult], original_query: str) -> List[SearchResult]:
        """
        Placeholder implementation of a summarization function.

        Args:
            search_results (List[SearchResult]): The search results to summarize.
            original_query (str): The original search query.

        Returns:
            List[SearchResult]: The summarized search results.
        """
        logger.info("Summarizing results")
        # Replace with actual LLM-based summarization implementation in Phase 3
        return search_results  # Return the same results for now, modify them later with LLM.

    def classify_result(self, search_result: SearchResult, categories: list[str]) -> dict:
        """Classifies a search result"""
        pass # WIP - for the LLM-based part

    def extract_information(self, scrape_result: ScrapeResult, information_needs: List[str]) -> ScrapeResult:
        """Extracts information from scrape result using the specified data structure"""
        pass # WIP - for the LLM-based part

    def chat(self, prompt:str, response_model: BaseModel, temperature:float=0.1, **kwargs) -> BaseModel:
        # The base method for calling the LLM.  Will also need to implement the batch method.
        messages = [{"role": "user", "content": prompt}]

        response = self.client.chat.completions.create(
            model=self.model_name,
            messages=messages,
            response_model=response_model,
            temperature=temperature,
            **kwargs
        )
        return response

    def create(self, messages: List[Dict[str,str]], response_model:BaseModel, temperature:float =0.1) -> Any:
      return self.client.chat.completions.create(
        model=self.model_name,
        messages=messages,
        response_model=response_model,
        temperature=temperature,
      )
content_copy
download
Use code with caution.
Python

Coding Prompt - AI, continue, but now generate files for the above modules and unit tests, following instructions to implement them.

### TASK CONTINUATION
Continue generating the code for the `llamafind` web search engine, starting now to implement the following modules in the order provided, generating full and working code for each of these files based on the code-generation instructions.

**Coding Instructions Summary (Applies to All Following Modules):**

1.  **Structure:** Generate a valid Python file with a name corresponding to each module (as above: `llamafind/core/engine.py`, etc.).
2.  **Dependencies:** Import all required libraries (e.g., `asyncio`, `requests`, `BeautifulSoup4`, `pydantic`). Include import statements.
3.  **Docstrings:** Provide complete and informative docstrings for classes, functions, and methods, including descriptions, arguments, and return values.
4.  **Error Handling:** Include basic error handling (try-except blocks).
5.  **Logging:** Include logging statements using the provided `logger` object to track key events and potential issues at debug and error levels (logging.debug, logging.error).
6.  **Code Quality:**  Write clean, readable, and well-commented code.
7.  **Test Code:** Generate the accompanying unit test file, name it with `test_` prefix and corresponding to module name (e.g., `tests/test_core_engine.py`).
8.  **Mocking:**  Use `unittest.mock.patch` or `pytest-mock` to mock external dependencies such as `requests.get` or LLM calls in the test suite so the tests run isolated and fast.
9.  **Test Coverage:** Ensure test coverage for all core functions and methods, including edge cases.
10. **Runnable Code:** Generate code which will be easy to integrate into the existing files, and where applicable, define the functions as async.
11.  **Refer to Previous Instructions**: Follow the instructions on general code generation provided earlier.
12. **Ensure to implement correct logging** make logging calls.

### 1. `llamafind/core/engine.py`
```python
# llamafind/core/engine.py
import asyncio
import logging
import toml  # For configuration file parsing
import argparse
from typing import List, Dict, Tuple, Optional
from llamafind.search_engines import (
    google_search,
    bing_search,
    duckduckgo_search,
    yahoo_search,
    baidu_search,
    ecosia_search,
    givewater_search,
    pinterest_search,
)
from llamafind.scraping import scraper
from llamafind.data_models import SearchResult, Proxy, ScrapeResult  # Import Data models
from llamafind.llm.llm_interface import LLMInterface  # Placeholder for MLX LLM Integration
from urllib.parse import urlparse
import re

logger = logging.getLogger(__name__)

# Define the main entry point
def main():
  # Create the parser
  parser = argparse.ArgumentParser(description="LlamaFind: Your Intelligent Web Search Engine")

  # Add the required arguments for the search
  parser.add_argument("query", help="The search query")
  parser.add_argument(
      "-n", "--num-results", type=int, default=10, help="Number of search results per engine"
  )
  parser.add_argument(
      "-e",
      "--engine",
      nargs="+",
      default=["google", "duckduckgo", "bing"],
      choices=["google", "bing", "duckduckgo", "yahoo", "baidu", "ecosia", "givewater", "pinterest"],
      help="Search engines to use (e.g., google, bing, duckduckgo).",
  )
  parser.add_argument(
      "-c", "--config", type=str, default="llamafind.toml", help="Path to the configuration file."
  )
  parser.add_argument(
    "-f", "--output-format", type=str, default="text", help="Output format for CLI results ('text', 'json', 'csv', 'markdown')."
  )
  parser.add_argument(
    "-v", "--verbose", action="store_true", help="Enable verbose logging."
  )

  # Parse the arguments
  args = parser.parse_args()

  # Set up the logging
  log_level = logging.DEBUG if args.verbose else logging.INFO
  logging.basicConfig(level=log_level, stream=sys.stderr)
  logger = logging.getLogger(__name__)

  # Instantiate and run the LlamaFindEngine
  engine = LlamaFindEngine(args.config)
  asyncio.run(engine.search(args.query, args.num_results))

class LlamaFindEngine:
    """
    The core engine of the LlamaFind search engine, responsible for orchestrating searches across multiple engines,
    query refinement (using an LLM), and result formatting.
    """

    def __init__(self, config_path: str = "llamafind.toml"):
        """
        Initialize the LlamaFindEngine.

        Args:
            config_path (str): Path to the configuration file (default: "llamafind.toml").
        """
        logger.info(f"Initializing LlamaFindEngine with configuration from {config_path}")
        self.config = self._load_config(config_path)
        self.search_engines = self._load_search_engines()
        self.proxy_manager = self._load_proxy_manager()
        self.llm = self._load_llm()  # Load your LLM here.
        logger.debug("Engine Initialized Successfully")

    def _load_config(self, config_path: str) -> dict:
        """Load configuration from a TOML file."""
        try:
            with open(config_path, "r") as f:
                config = toml.load(f)
                logger.debug(f"Configuration loaded from {config_path}: {config}")
                return config
        except FileNotFoundError:
            logger.error(f"Configuration file not found: {config_path}. Using default configurations.")
            return {}  # or use default configurations
        except toml.TomlDecodeError as e:
            logger.error(f"Error decoding configuration file {config_path}: {e}. Using default configurations.")
            return {}

    def _load_search_engines(self) -> Dict[str, callable]:
        """Loads the search engines based on the configuration."""
        engines = {}
        configured_engines = self.config.get("default_search_engines", [])
        if not configured_engines:
            configured_engines = ["google", "duckduckgo", "bing"]  # Default engines if none are configured
            logger.warning(f"No search engines configured in llamafind.toml, using defaults: {configured_engines}")
        for engine_name in configured_engines:
            if engine_name == "google":
                engines["google"] = google_search
            elif engine_name == "bing":
                engines["bing"] = bing_search
            elif engine_name == "duckduckgo":
                engines["duckduckgo"] = duckduckgo_search
            elif engine_name == "yahoo":
                engines["yahoo"] = yahoo_search
            elif engine_name == "baidu":
                engines["baidu"] = baidu_search
            elif engine_name == "ecosia":
                engines["ecosia"] = ecosia_search
            elif engine_name == "givewater":
                engines["givewater"] = givewater_search
            elif engine_name == "pinterest":
                engines["pinterest"] = pinterest_search
            else:
                logger.warning(f"Search engine '{engine_name}' is not supported. Skipping it.")
        if not engines:
            logger.error("No valid search engines configured. Cannot search.")
        return engines

    def _load_proxy_manager(self) -> Optional[Dict[str, Any]]:
        """Loads and configures the proxy manager, returns proxy dictionary for each search"""
        proxy_config = self.config.get("proxy", {})
        proxy_source = proxy_config.get("source")
        proxy = None  # Placeholder, initialize actual implementation in Phase 2

        if proxy_source == "file":
            file_path = proxy_config.get("file_path")
            if file_path:
                try:
                    with open(file_path, "r") as f:
                        proxy_list = [line.strip() for line in f if line.strip()]
                    # Basic proxy format validation (IP:PORT:USERNAME:PASSWORD)
                    validated_proxies: List[Proxy] = []
                    for proxy_str in proxy_list:
                        if ":" in proxy_str:
                            parts = proxy_str.split(":")
                            if 2 <= len(parts) <= 4:  # Basic check. Handle SOCKS later
                                try:
                                    proxy_obj = self._parse_proxy(proxy_str)
                                    validated_proxies.append(proxy_obj)
                                except ValueError as e:
                                    logger.error(f"Error while parsing proxy: {proxy_str}, {e}. Skipping.")
                            else:
                                logger.warning(f"Invalid proxy format: {proxy_str}. Skipping.")
                    if validated_proxies:
                        proxy = {"proxies": validated_proxies}
                        logger.debug(f"Loaded {len(validated_proxies)} proxies from {file_path}")
                    else:
                        logger.warning(f"No valid proxies found in {file_path}")
                except FileNotFoundError:
                    logger.warning(f"Proxy file not found: {file_path}")
                except Exception as e:
                    logger.error(f"Error loading proxies from {file_path}: {e}")
            else:
                logger.warning("File path not specified in proxy configuration, not using proxies.")
        elif proxy_source == "api":
            api_url = proxy_config.get("api_url")
            api_key = proxy_config.get("api_key")
            # implement api fetching and parsing for Phase 2
            if api_url and api_key:
                proxy = {"api_url": api_url, "api_key": api_key}
                logger.debug(f"Proxy loaded from api_url: {api_url}")
            else:
                logger.warning("API URL or API key not specified for proxy, not using proxies")
        else:
            logger.warning("No proxy source provided.  Running without proxies.")

        return proxy

    def _load_llm(self) -> Optional[LLMInterface]:
        """Loads and configures the LLM, returns LLM Interface"""
        llm_config = self.config.get("llm", {})
        provider = llm_config.get("provider")
        model = llm_config.get("model")
        api_key = llm_config.get("api_key")
        if not (provider and model and api_key):
            logger.warning("No LLM is configured. LLM features will be disabled.")
            return None

        # Initialize your MLX LLM and return the appropriate instance
        # Replace this with your actual LLM initialization logic.

        llm_interface = LLMInterface(provider=provider, model=model, api_key=api_key, llm_config=llm_config)
        logger.debug(f"Loaded LLM interface: {provider}/{model}")
        return llm_interface

    async def search(self, query: str, num_results: int = 10) -> List[SearchResult]:
        """
        Performs a web search across multiple search engines.

        Args:
            query (str): The search query.
            num_results (int): The number of results to retrieve per search engine (default: 10).

        Returns:
            List[SearchResult]: A list of search results.
        """
        logger.info(f"Searching for: '{query}' across multiple search engines (Results per engine: {num_results})")
        all_results: List[SearchResult] = []
        if not self.search_engines:
            logger.error("No search engines are loaded. Returning empty results.")
            return []

        for engine_name, search_function in self.search_engines.items():
            logger.debug(f"Searching with {engine_name}")
            try:
                results = await search_function(query, num_results, self.proxy_manager)  # Pass proxy manager
                for result in results:
                    result.engine = engine_name
                all_results.extend(results)
                logger.debug(f"Found {len(results)} results for {engine_name}")
            except Exception as e:
                logger.error(f"Error searching with {engine_name}: {e}")

        # LLM-based query refinement (Phase 3)
        if self.llm:
            try:
                refined_query = await self.llm.refine_query(query, all_results)
                if refined_query != query:
                    logger.info(f"Query Refined from '{query}' to '{refined_query}'")
                    # Call search functions again for each engine with the refined query
                    refined_results: List[SearchResult] = []
                    for engine_name, search_function in self.search_engines.items():
                        try:
                            results = await search_function(refined_query, num_results, self.proxy_manager)
                            for result in results:
                                result.engine = engine_name
                            refined_results.extend(results)
                        except Exception as e:
                            logger.error(f"Error searching with refined query with {engine_name}: {e}")
                    all_results = refined_results

            except Exception as e:
                logger.error(f"Error refining query: {e}")

        # Result summarization (Phase 3) - basic summarization: to be defined at a later stage.
        if self.llm:
            try:
                all_results = await self.llm.summarize_results(all_results, query)
            except Exception as e:
                logger.error(f"Error summarization for results: {e}")

        return all_results

    def _parse_proxy(self, proxy_str: str) -> Proxy:
        """Parses a proxy string of the form user:password@ip:port or ip:port"""
        match = re.match(r"((?P<username>[^@:]*):(?P<password>[^@:]*)@)?(?P<host>[^:]+):(?P<port>\d+)", proxy_str)
        if not match:
            raise ValueError(f"Invalid proxy string format: {proxy_str}")
        data = match.groupdict()
        return Proxy(
            ip_address=data["host"],
            port=int(data["port"]),
            protocol="http",  # Default protocol.  Can update later.
            username=data.get("username"),
            password=data.get("password"),
            anonymity="anonymous", # Default
        )
content_copy
download
Use code with caution.
Python
### 4. `llamafind/search_engines/__init__.py`
from .google import google_search
from .bing import bing_search
from .duckduckgo import duckduckgo_search
from .yahoo import yahoo_search
from .baidu import baidu_search
from .ecosia import ecosia_search
from .givewater import givewater_search
from .pinterest import pinterest_search
content_copy
download
Use code with caution.
Python
### 5. `llamafind/search_engines/google.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def google_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Google search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Google for '{query}' (Results: {num_results})")
    base_url = "https://www.google.com/search"
    params = {"q": query, "num": num_results}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="g"):
            title_element = result.find("h3")
            link_element = result.find("a")
            snippet_element = result.find("span", class_="st")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="google")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Google search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 6. `llamafind/search_engines/bing.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def bing_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Bing search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Bing for '{query}' (Results: {num_results})")
    base_url = "https://www.bing.com/search"
    params = {"q": query, "count": num_results}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("li", class_="b_algo"):
            title_element = result.find("h2")
            link_element = result.find("a")
            snippet_element = result.find("p", class_="b_snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="bing")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Bing search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 7. `llamafind/search_engines/duckduckgo.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def duckduckgo_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a DuckDuckGo search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching DuckDuckGo for '{query}' (Results: {num_results})")
    base_url = "https://duckduckgo.com/html"
    params = {"q": query, "max_results": num_results}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="result"):
            title_element = result.find("h2", class_="result__title")
            link_element = result.find("a", class_="result__a")
            snippet_element = result.find("div", class_="result__snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="duckduckgo")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing DuckDuckGo search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 8. `llamafind/search_engines/yahoo.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def yahoo_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Yahoo search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Yahoo for '{query}' (Results: {num
content_copy
download
Use code with caution.
Python_results})")
    base_url = "https://search.yahoo.com/search"
    params = {"q": query, "n": num_results} # 'n' used instead of num.

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="NewsArticle"): #Updated for yahoo
            title_element = result.find("h3", class_="title")
            link_element = result.find("a", class_="thmb")
            snippet_element = result.find("p", class_="txt")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="yahoo")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Yahoo search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 9. `llamafind/search_engines/baidu.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def baidu_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Baidu search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Baidu for '{query}' (Results: {num_results})")
    base_url = "https://www.baidu.com/s"
    params = {"wd": query, "rn": num_results} # Use 'rn' instead of num

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="result c-container"):
            title_element = result.find("h3", class_="t")
            link_element = result.find("a")  # Usually the first a tag inside
            snippet_element = result.find("div", class_="c-abstract")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="baidu")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Baidu search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 10. `llamafind/search_engines/ecosia.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def ecosia_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs an Ecosia search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Ecosia for '{query}' (Results: {num_results})")
    base_url = "https://www.ecosia.org/search"
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="results-list-container"):
            title_element = result.find("a", class_="result__title-link")
            link_element = result.find("a", class_="result__url") #Updated for ecosia
            snippet_element = result.find("p", class_="result-snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="ecosia")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Ecosia search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 11. `llamafind/search_engines/givewater.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def givewater_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a GiveWater search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching GiveWater for '{query}' (Results: {num_results})")
    base_url = "https://search.givewater.com/serp"
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="web-bing__result"):
            title_element = result.find("a")
            link_element = result.find("a")
            snippet_element = result.find("p", class_="b_snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="givewater")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing GiveWater search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 12. `llamafind/search_engines/pinterest.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def pinterest_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Pinterest search for the given query.
    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Pinterest for '{query}' (Results: {num_results})")
    base_url = "https://www.pinterest.com/search/pins/" # The base url has been added to the method.
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "X-Requested-With": "XMLHttpRequest",
        "Accept": "application/json",
        # Adding Accept-Language Header
        "Accept-Language": "en-US,en;q=0.9"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        # Pinterest returns JSON data.
        data = response.json()
        results: List[SearchResult] = []
        for item in data.get('pins', []):
            title = item.get('title')
            url = item.get('url')
            if title and url:
                results.append(SearchResult(title=title, url=url, engine="pinterest", image_url=item.get('images').get('orig').get('url')))
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Pinterest search results: {e}")
        return []
content_copy
download
Use code with caution.
Python

(13) llamafind/scraping/scraper.py (WebScraper - Implemented)import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup
from fake_useragent import UserAgent
import re
from llamafind.data_models import ScrapeResult

logger = logging.getLogger(__name__)


class WebScraper:
    """
    A basic web scraper.
    """

    def __init__(self, user_agent: str = None, proxies: Optional[Dict[str, str]] = None, timeout: int = 15):
        """
        Initialize the WebScraper.

        Args:
            user_agent (str): User-Agent string to use for requests.
            proxies (Optional[Dict[str, str]]): Optional dictionary of proxies to use (see requests library).
            timeout (int): Timeout for requests in seconds.
        """
        self.user_agent = user_agent or self.get_random_user_agent()
        self.proxies = proxies or {}
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": self.user_agent})
        self.timeout = timeout

    def get_random_user_agent(self) -> str:
        """
        Generates a random user agent string.

        Returns:
            str: A random user agent.
        """
        ua = UserAgent()
        return ua.random

    def fetch_page(self, url: str) -> Optional[str]:
        """
        Fetches the HTML content of a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            Optional[str]: The HTML content as a string, or None if the request fails.
        """
        try:
            logger.debug(f"Fetching URL: {url} using proxy {self.proxies if self.proxies else 'No Proxy'}")
            response = self.session.get(url, timeout=self.timeout, proxies=self.proxies)
            response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
            return response.text
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch {url}: {e}")
            return None

    def get_soup(self, html_content: str) -> Optional[BeautifulSoup]:
        """
        Parses HTML content using BeautifulSoup.

        Args:
            html_content (str): The HTML content as a string.

        Returns:
            Optional[BeautifulSoup]: A BeautifulSoup object, or None if parsing fails.
        """
        try:
            return BeautifulSoup(html_content, "html.parser")
        except Exception as e:
            logger.error(f"Failed to parse HTML: {e}")
            return None

    def get_text(self, url: str) -> str:
        """
        Extracts the full text content of a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            str: The extracted text content.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return ""
        soup = self.get_soup(html_content)
        return soup.get_text(separator=" ", strip=True) if soup else ""

    def get_links(self, url: str) -> List[Dict[str, str]]:
        """
        Extracts all links from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[Dict[str, str]]: A list of dictionaries, where each dictionary represents a link with 'text' and 'href' keys.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        links = []
        if soup:
            for a in soup.find_all("a", href=True):
                text = a.get_text(strip=True)
                href = a["href"]
                absolute_url = self._make_absolute(url, href)
                links.append({"text": text, "href": absolute_url})
        return links

    def get_images(self, url: str) -> List[str]:
        """
        Extracts all image URLs from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[str]: A list of image URLs.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        image_urls = []
        if soup:
            for img in soup.find_all("img", src=True):
                src = img["src"]
                absolute_url = self._make_absolute(url, src)
                image_urls.append(absolute_url)
        return image_urls

    def get_tables(self, url: str) -> List[str]:
        """
        Extracts all tables from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[str]: A list of table strings.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        tables = []
        if soup:
            for table in soup.find_all("table"):
                tables.append(str(table))  # Return raw HTML
        return tables

    def _make_absolute(self, base_url, url):
        """Helper to convert relative URLs to absolute URLs."""
        from urllib.parse import urljoin

        return urljoin(base_url, url)


class SeleniumScraper(WebScraper):
    """
    A web scraper that uses Selenium to render dynamic content.
    """

    def __init__(
            self,
            user_agent: Optional[str] = None,
            proxies: Optional[Dict[str, str]] = None,
            headless: bool = True,
            driver_path: Optional[str] = None,
            timeout: int = 15,
    ):
        from selenium import webdriver
        from selenium.webdriver.firefox.options import Options as FirefoxOptions
        from selenium.webdriver.chrome.options import Options as ChromeOptions
        from selenium.webdriver.chrome.service import Service as ChromeService
        from selenium.webdriver.firefox.service import Service as FirefoxService
        from selenium.webdriver.remote.webdriver import WebDriver
        from webdriver_manager.chrome import ChromeDriverManager
        from webdriver_manager.firefox import GeckoDriverManager

        super().__init__(user_agent, proxies, timeout)
        self.headless = headless
        self.driver_path = driver_path
        self.driver: Optional[WebDriver] = None

        self.driver_type: str = "chromium"  # Or "firefox"

    def fetch_page(self, url: str) -> Optional[str]:
        """
        Fetches the HTML content of a web page using Selenium.

        Args:
            url (str): The URL of the web page.

        Returns:
            Optional[str]: The HTML content as a string, or None if the request fails.
        """
        try:
            self._setup_driver()
            self.driver.get(url)
            self._wait_for_page_load()
            return self.driver.page_source
        except Exception as e:
            logger.error(f"Failed to fetch (Selenium) {url}: {e}")
            return None
        finally:
            self._teardown_driver()

    def get_soup(self, html_content: str) -> Optional[BeautifulSoup]:
        """
        Parses HTML content using BeautifulSoup.

        Args:
            html_content (str): The HTML content as a string.

        Returns:
            Optional[BeautifulSoup]: A BeautifulSoup object, or None if parsing fails.
        """
        if not html_content:
            return None
        try:
            return BeautifulSoup(html_content, "html.parser")
        except Exception as e:
            logger.error(f"Failed to parse HTML (Selenium): {e}")
            return None

    def _setup_driver(self):
        """Set up the Selenium WebDriver (Chromium or Firefox)."""
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options as ChromeOptions
        from selenium.webdriver.chrome.service import Service as ChromeService
        from selenium.webdriver.firefox.options import Options as FirefoxOptions
        from selenium.webdriver.firefox.service import Service as FirefoxService
        from webdriver_manager.chrome import ChromeDriverManager
        from webdriver_manager.firefox import GeckoDriverManager
        from selenium.webdriver.remote.webdriver import WebDriver

        if self.driver:
            return # already set

        if self.driver_type == "chromium":
            chrome_options = ChromeOptions()
            if self.headless:
                chrome_options.add_argument("--headless")  # Run in headless mode
            if self.user_agent:
                chrome_options.add_argument(f"--user-agent={self.user_agent}")
            if self.proxies:
                # Configure proxy for Selenium
                # Only single proxy supported
                proxy = list(self.proxies.values())[0]
                if isinstance(proxy, str):
                  chrome_options.add_argument(f"--proxy-server={proxy}")
                else:
                  logger.error(f"Selenium only supports string based proxies. Got {type(proxy)=}")
            if self.driver_path:
                try:
                    service = ChromeService(executable_path=self.driver_path)
                    self.driver = webdriver.Chrome(service=service, options=chrome_options)
                except Exception as e:
                    logger.error(f"Chrome not found at location: {self.driver_path=}, defaulting to chrome webdriver manager. {e}")
                    self.driver = webdriver.Chrome(ChromeDriverManager().install(), options=chrome_options) # Use webdriver_manager
            else:
                self.driver = webdriver.Chrome(ChromeDriverManager().install(), options=chrome_options) # Use webdriver_manager
        elif self.driver_type == "firefox":
            firefox_options = FirefoxOptions()
            if self.headless:
                firefox_options.add_argument("--headless")  # Run in headless mode
            if self.user_agent:
                firefox_options.add_argument(f"--user-agent={self.user_agent}")
            if self.proxies:
                # Configure proxy for Selenium
                # Only single proxy supported
                proxy = list(self.proxies.values())[0]
                if isinstance(proxy, str):
                  firefox_options.add_argument(f"--proxy-server={proxy}")
                else:
                  logger.error(f"Selenium only supports string based proxies. Got {type(proxy)=}")

            if self.driver_path:
              try:
                service = FirefoxService(executable_path=self.driver_path)
                self.driver = webdriver.Firefox(service=service, options=firefox_options)
              except Exception as e:
                logger.error(f"Firefox not found at location: {self.driver_path=}, defaulting to firefox webdriver manager. {e}")
                self.driver = webdriver.Firefox(executable_path=GeckoDriverManager().install(), options=firefox_options) # Use webdriver_manager
            else:
                self.driver = webdriver.Firefox(executable_path=GeckoDriverManager().install(), options=firefox_options) # Use webdriver_manager
        else:
            raise ValueError(f"Unsupported driver type: {self.driver_type}")
        if self.timeout:
          self.driver.set_page_load_timeout(self.timeout) #Set time out

    def _wait_for_page_load(self):
        """Waits for page to load (can be customized) - Example:
            - waiting for document ready state to be complete
        """
        # can be customized, example:
        from selenium.webdriver.support.ui import WebDriverWait
        from selenium.webdriver.support import expected_conditions as EC
        from selenium.webdriver.common.by import By

        try:
            WebDriverWait(self.driver, self.timeout).until(
                EC.presence_of_element_located((By.TAG_NAME, "body"))  # Example
            )
        except Exception as e:
            logger.error(f"Error while waiting for page to load: {e}")

    def _teardown_driver(self):
        """Tear down the Selenium WebDriver."""
        if self.driver:
            try:
                self.driver.quit()
            except Exception as e:
                logger.error(f"Error closing the Selenium driver: {e}")
            self.driver = None
content_copy
download
Use code with caution.
Python
### 14. `llamafind/data_models.py` (Data Models - Implemented)
from typing import List, Optional, Dict
from pydantic import BaseModel, Field

# Search Result Data Model
class SearchResult(BaseModel):
    """
    Represents a single search result from a search engine.

    Attributes:
        title (str): The title of the search result.
        url (str): The URL of the search result.
        snippet (str): A brief description or snippet of the search result.
        engine (str): The name of the search engine (e.g., "google", "bing").
        image_url (Optional[str]): URL of an image associated with the result, if available.
        raw_data (dict): Original data scraped.
    """
    title: str = Field(..., description="The title of the search result")
    url: str = Field(..., description="The URL of the search result")
    snippet: str = Field(..., description="A brief description or snippet of the search result")
    engine: str = Field(..., description="The name of the search engine")
    image_url: Optional[str] = Field(None, description="URL of an image associated with the result")
    raw_data: dict = Field({}, description="Original raw data from the scraper")


# Scrape Result Data Model
class ScrapeResult(BaseModel):
    """
    Represents the result of scraping a web page.

    Attributes:
        url (str): The URL of the scraped page.
        text_content (str): The extracted text content of the page.
        links (List[str]): List of all extracted links on the page.
        image_urls (List[str]): List of extracted image URLs.
        tables (List[str]): Raw HTML of extracted tables.
        metadata (Dict): Dictionary containing metadata about the scraped page.
    """
    url: str = Field(..., description="The URL of the scraped page")
    text_content: str = Field(..., description="The text content of the page")
    links: list[str] = Field(..., description="Links found on the page")
    image_urls: list[str] = Field(..., description="Image URLs found on the page")
    tables: list[str] = Field(..., description="Raw HTML of tables found on the page")  # raw html for tables
    metadata: dict = Field({}, description="Metadata about the page")


# Proxy Data Model
class Proxy(BaseModel):
    """
    Represents a proxy server.

    Attributes:
        ip_address (str): The IP address or domain name of the proxy.
        port (int): The port number of the proxy.
        protocol (str):  Protocol (e.g., "http", "https", "socks4", "socks5").
        username (Optional[str]): Username for proxy authentication.
        password (Optional[str]): Password for proxy authentication.
        anonymity (str): "transparent", "anonymous", or "elite".
        latency (float): Measured response time, in seconds (optional).
        country (str): Country code (e.g., "US") (optional).
    """
    ip_address: str = Field(..., description="The IP address or domain name of the proxy")
    port: int = Field(..., description="The port number of the proxy")
    protocol: str = Field(..., description="The proxy protocol")
    username: Optional[str] = Field(None, description="Username for proxy authentication")
    password: Optional[str] = Field(None, description="Password for proxy authentication")
    anonymity: str = Field(description="Proxy anonymity level")
    latency: Optional[float] = Field(None, description="Latency of proxy")
    country: Optional[str] = Field(None, description="Country of proxy")
content_copy
download
Use code with caution.
Python
### 15. `llamafind/llm/llm_interface.py` (LLM Interface - Implemented)
#llamafind/llm/llm_interface.py
from __future__ import annotations

import asyncio
import logging
from typing import List, Dict, Tuple, Optional, Any
from llamafind.data_models import SearchResult
from instructor.function_calls import Mode
from openai import OpenAI, AsyncOpenAI
from pydantic import BaseModel, Field
from typing import Iterable, Union

logger = logging.getLogger(__name__)


class LLMInterface:
    """
    Interface for interacting with an LLM and defining function calls.
    """

    def __init__(self, provider: str, model: str, api_key: str, llm_config: Dict[str, Any]):
        """
        Initializes the LLMInterface.

        Args:
            provider (str): The LLM provider (e.g., "openai").
            model (str): The specific LLM model name (e.g., "gpt-4o").
            api_key (str): The API key for the LLM provider.
        """
        self.provider = Provider(provider)
        self.model = model
        self.api_key = api_key
        self.llm_config = llm_config
        self.client = self._initialize_client()  # Initialize the client during init
        self.model_name = model
        self.mode = Mode.JSON

    def _initialize_client(self):
        """
        Initializes the OpenAI client.
        """
        if self.provider == Provider.OPENAI:
            client = OpenAI(api_key=self.api_key)
            instructor_client = instructor.from_openai(client, mode=self.mode) # Pass a model and its features.
            return instructor_client
        if self.provider == Provider.GROQ:
            import groq
            client = groq.Groq(api_key=self.api_key)
            instructor_client = instructor.from_groq(client, mode=self.mode) # Pass a model and its features.
            return instructor_client
        # Add other providers here
        raise ValueError(f"Unsupported LLM provider: {self.provider}")

    def refine_query(self, query: str, search_results: List[SearchResult]) -> str:
        """
        Placeholder implementation of a query refinement function.

        Args:
            query (str): The original search query.
            search_results (List[SearchResult]): The search results obtained from the initial search.

        Returns:
            str: Refined search query.
        """
        logger.info("Refining query")
        # Replace with actual implementation using the LLM in Phase 3
        return query

    def summarize_results(self, search_results: List[SearchResult], original_query: str) -> List[SearchResult]:
        """
        Placeholder implementation of a summarization function.

        Args:
            search_results (List[SearchResult]): The search results to summarize.
            original_query (str): The original search query.

        Returns:
            List[SearchResult]: The summarized search results.
        """
        logger.info("Summarizing results")
        # Replace with actual LLM-based summarization implementation in Phase 3
        return search_results  # Return the same results for now, modify them later with LLM.

    def classify_result(self, search_result: SearchResult, categories: list[str]) -> dict:
        """Classifies a search result"""
        pass # WIP - for the LLM-based part

    def extract_information(self, scrape_result: ScrapeResult, information_needs: List[str]) -> ScrapeResult:
        """Extracts information from scrape result using the specified data structure"""
        pass # WIP - for the LLM-based part

    def chat(self, prompt:str, response_model: BaseModel, temperature:float=0.1, **kwargs) -> BaseModel:
        # The base method for calling the LLM.  Will also need to implement the batch method.
        messages = [{"role": "user", "content": prompt}]

        response = self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            response_model=response_model,
            temperature=temperature,
            **kwargs
        )
        return response

    def create(self, messages: List[Dict[str,str]], response_model:BaseModel, temperature:float =0.1) -> Any:
      return self.client.chat.completions.create(
        model=self.model_name,
        messages=messages,
        response_model=response_model,
        temperature=temperature,
      )
content_copy
download
Use code with caution.
Python
### Unit Tests
# tests/test_llm_interface.py
# Here we define test for the LLMInterface module.

# Import required libraries
import pytest
from unittest.mock import patch
from llamafind.llm.llm_interface import LLMInterface, Provider
from llamafind.data_models import SearchResult
from pydantic import BaseModel
from openai import OpenAI
from typing import List

@pytest.fixture
def mock_openai_client():
    # Mock the OpenAI client
    class MockOpenAIClient:
        class MockChatCompletion:
            def create(self, **kwargs):
                # Simulate a successful OpenAI API call
                class MockResponse:
                  def model_dump_json(self, **kwargs):
                      return '{"result": "Mocked LLM response"}'
                return MockResponse()

        chat = MockChatCompletion()

    return MockOpenAIClient()


@pytest.fixture
def llm_interface_openai(mock_openai_client):
    """
    Fixture to create an LLMInterface instance with the mocked OpenAI client.
    """
    # Pass the necessary mocks to the init method to make sure the LLM is loaded successfully.
    return LLMInterface(
        provider="openai",
        model="gpt-3.5-turbo",
        api_key="test_api_key",  # Replace with your API key (or mock it)
        llm_config={"test": "test"},
    )

def test_llm_interface_initialization(llm_interface_openai):
    """Test LLMInterface initialization."""
    assert isinstance(llm_interface_openai, LLMInterface)
    assert llm_interface_openai.provider == Provider.OPENAI
    assert llm_interface_openai.model == "gpt-3.5-turbo"

def test_llm_interface_refine_query(llm_interface_openai):
    """Test the query refinement method"""
    initial_query = "test query"
    search_results = [SearchResult(title="Test Result", url="http://example.com", snippet="test snippet", engine="google")]
    refined_query = llm_interface_openai.refine_query(initial_query, search_results)
    assert refined_query == initial_query  # Placeholder implementation
    # TODO: Add integration tests to test this methods.

def test_llm_interface_summarize_results(llm_interface_openai):
    """Test summarization method"""
    search_results = [SearchResult(title="Test Result", url="http://example.com", snippet="test snippet", engine="google")]
    original_query = "test query"
    summarized_results = llm_interface_openai.summarize_results(search_results, original_query)
    assert summarized_results == search_results  # Placeholder implementation
    # TODO: Add integration tests to test this methods.

# Test cases for the base methods.
def test_chat_completion(llm_interface_openai, mock_openai_client):
    """Test chat completion"""
    class TestModel(BaseModel):
        result: str
    # inject mock
    llm_interface_openai.client = mock_openai_client # use a client that was injected
    messages = [{"role": "user", "content": "Extract 'test' from this text."}]
    response = llm_interface_openai.chat(prompt = "Extract 'test' from this text", response_model=TestModel, temperature=0.1)
    assert response.result == "Mocked LLM response" #Check mock value.
content_copy
download
Use code with caution.
Python
### 17. `llamafind/proxy/proxy_manager.py` (Proxy Manager)**

```python
# llamafind/proxy/proxy_manager.py
import asyncio
import logging
import random
from typing import List, Optional, Dict, Any

import requests

from llamafind.data_models import Proxy
from llamafind.scraping import scraper

logger = logging.getLogger(__name__)


class ProxyManager:
    """
    Manages a list of proxies and provides proxy selection based on configuration.
    """
    def __init__(self, config: Dict[str, Any]):
        """
        Initializes the ProxyManager.

        Args:
            config (Dict): Configuration dictionary (e.g., from `llamafind.toml`).
        """
        self.config = config
        self.proxies: List[Proxy] = []
        self.load_proxies()

    def load_proxies(self):
        """
        Loads proxies from the configured source.  Supports 'file' and 'api' sources.
        """
        proxy_config = self.config.get("proxy", {})
        proxy_source = proxy_config.get("source")
        if not proxy_source:
            logger.info("No proxy source specified in config. Running without proxies.")
            return

        if proxy_source == "file":
            file_path = proxy_config.get("file_path")
            if not file_path:
                logger.warning("File path not specified for proxy source 'file'.")
                return
            try:
                with open(file_path, "r") as f:
                    proxy_list = [line.strip() for line in f if line.strip()]
                # Validate basic proxy format
                validated_proxies: List[Proxy] = []
                for proxy_str in proxy_list:
                    if ":" in proxy_str:
                        parts = proxy_str.split(":")
                        if 2 <= len(parts) <= 4:  # Basic check. Handle SOCKS later
                            # Create Proxy objects
                            try:
                                proxy_obj = self._parse_proxy(proxy_str)
                                validated_proxies.append(proxy_obj)
                            except Exception as e:
                                logger.error(f"Error while parsing proxy: {proxy_str}, {e}. Skipping.")
                        else:
                            logger.warning(f"Invalid proxy format: {proxy_str}. Skipping.")
                    else:
                        logger.warning(f"Invalid proxy format: {proxy_str}. Skipping.")

                self.proxies = validated_proxies
                if self.proxies:
                    logger.info(f"Loaded {len(self.proxies)} proxies from {file_path}")
                else:
                    logger.warning(f"No valid proxies found in {file_path}")
            except FileNotFoundError:
                logger.warning(f"Proxy file not found: {file_path}")
            except Exception as e:
                logger.error(f"Error loading proxies from {file_path}: {e}")
        elif proxy_source == "api":
            api_url = proxy_config.get("api_url")
            api_key = proxy_config.get("api_key")
            if api_url and api_key:
                # Implement API fetching and parsing here (Phase 2).
                try:
                    # Placeholder for API call. Replace with real API call.
                    # Example using requests (replace with an actual API call)
                    response = requests.get(api_url, headers={"Authorization": f"Bearer {api_key}"}, timeout=10)
                    response.raise_for_status()
                    proxy_list = response.json()  # Assuming the API returns a list of proxy strings/objects
                    validated_proxies = []
                    for proxy_data in proxy_list:  # Adapt the parsing logic to your API
                        if isinstance(proxy_data, str):
                            try:
                                proxy_obj = self._parse_proxy(proxy_data)
                                validated_proxies.append(proxy_obj)
                            except Exception as e:
                                logger.error(f"Error while parsing proxy from API: {proxy_data}, {e}. Skipping.")
                        else:
                             try:
                                 proxy_str = f"{proxy_data['ip_address']}:{proxy_data['port']}"
                                 proxy_obj = self._parse_proxy(proxy_str)
                                 proxy_obj.protocol = proxy_data.get('protocol', 'http')
                                 proxy_obj.username = proxy_data.get('username')
                                 proxy_obj.password = proxy_data.get('password')
                                 validated_proxies.append(proxy_obj)
                             except Exception as e:
                                 logger.error(f"Error while parsing proxy data: {proxy_data}, {e}. Skipping.")

                    self.proxies = validated_proxies
                    if self.proxies:
                        logger.info(f"Loaded {len(self.proxies)} proxies from {api_url}")
                    else:
                        logger.warning(f"No valid proxies found from {api_url}")

                except requests.exceptions.RequestException as e:
                    logger.error(f"API request failed: {e}")
                except Exception as e:
                    logger.error(f"Error loading proxies from API: {e}")
            else:
                logger.warning("API URL or API key not specified for proxy, not using proxies")
        else:
            logger.warning(f"Invalid proxy source: {proxy_source}.  Please specify a valid source in llamafind.toml.")

    def _parse_proxy(self, proxy_str: str) -> Proxy:
        """Parses a proxy string of the form user:password@ip:port or ip:port"""
        match = re.match(r"((?P<username>[^@:]*):(?P<password>[^@:]*)@)?(?P<host>[^:]+):(?P<port>\d+)", proxy_str)
        if not match:
            raise ValueError(f"Invalid proxy string format: {proxy_str}")
        data = match.groupdict()
        return Proxy(
            ip_address=data["host"],
            port=int(data["port"]),
            protocol="http",  # Default protocol.  Can update later.
            username=data.get("username"),
            password=data.get("password"),
            anonymity="anonymous", # Default
        )

    def get_proxy(self) -> Optional[Proxy]:
        """
        Gets a random available proxy or None if no proxies are available.
        """
        if not self.proxies:
            return None
        return random.choice(self.proxies)
content_copy
download
Use code with caution.
Python
### 18. `llamafind/cli/cli_interface.py` (CLI - Implemented)**
#llamafind/cli/cli_interface.py
from __future__ import annotations

import os
import sys
import logging
from typing import List, Optional, Dict, Tuple, Any

import typer
from rich.console import Console
from rich.table import Table
from llamafind.core.engine import LlamaFindEngine
from llamafind.data_models import SearchResult, Proxy
from datetime import datetime
# from llamafind.api.web_api import create_app

app = typer.Typer(help="LlamaFind: Your intelligent web search engine.")
console = Console()


def display_text_results(results: List[SearchResult]):
    """Display search results in text format."""
    for i, result in enumerate(results):
        console.print(f"[bold]{i+1}.[/] Engine: [yellow]{result.engine}[/]")
        console.print(f"  Title: [blue]{result.title}[/]")
        console.print(f"  URL: [green]{result.url}[/]")
        console.print(f"  Snippet: {result.snippet}\n")


def display_json_results(results: List[SearchResult]):
    """Display search results in JSON format."""
    import json
    console.print(json.dumps([r.model_dump() for r in results], indent=2))


def display_csv_results(results: List[SearchResult]):
    """Display search results in CSV format (basic implementation)."""
    # Consider more robust CSV formatting with a library
    print("title,url,snippet,engine")
    for result in results:
        print(f'"{result.title}","{result.url}","{result.snippet}","{result.engine}"')


def display_markdown_results(results: List[SearchResult]):
    """Display search results in Markdown format."""
    for result in results:
        print(f"## {result.title}")
        print(f"*   **Engine:** {result.engine}")
        print(f"*   **URL:** {result.url}")
        print(f"*   **Snippet:** {result.snippet}")
        print("")  # Add spacing between results

@app.command()
def search(
        query: str = typer.Argument(..., help="The search query."),
        num_results: int = typer.Option(10, "--num-results", "-n", help="Number of results per engine."),
        engines: List[str] = typer.Option(
            [],
            "--engine",
            "-e",
            help="Search engines to use (e.g., google, bing, duckduckgo).",
            case_sensitive=False,
        ),
        config: str = typer.Option("llamafind.toml", "--config", "-c", help="Path to the configuration file."),
        output_format: str = typer.Option("text", "--output-format", "-f", help="Output format (text, json, csv, markdown)."),
        verbose: bool = typer.Option(False, "--verbose", "-v", help="Enable verbose logging."),
):
    """
    Performs a web search using LlamaFind.
    """
    # Configure logging
    log_level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(level=log_level, stream=sys.stderr)
    logger = logging.getLogger(__name__)

    logger.debug(f"Starting search: Query='{query}', Results per engine={num_results}, Engines={engines}, Config='{config}'")

    # Create engine
    engine = LlamaFindEngine(config_path=config)
    if not engine.search_engines:
        typer.echo("Error: No search engines configured.  Check your configuration file.")
content_copy
download
Use code with caution.
Pythonraise typer.Exit(code=1)

    # Execute the search
    try:
        results = asyncio.run(engine.search(query=query, num_results=num_results))
    except Exception as e:
        logger.exception(f"An error occurred during the search: {e}")
        typer.echo(f"Error during search: {e}", err=True)
        raise typer.Exit(code=1)

    # Output results based on the selected format
    if output_format == "text":
        display_text_results(results)
    elif output_format == "json":
        display_json_results(results)
    elif output_format == "csv":
        display_csv_results(results)
    elif output_format == "markdown":
        display_markdown_results(results)
    else:
        typer.echo(f"Error: Unsupported output format: {output_format}", err=True)
        raise typer.Exit(code=1)


def display_text_results(results: List[SearchResult]):
    """Display search results in text format."""
    for i, result in enumerate(results):
        console.print(f"[bold]{i+1}.[/] Engine: [yellow]{result.engine}[/]")
        console.print(f"  Title: [blue]{result.title}[/]")
        console.print(f"  URL: [green]{result.url}[/]")
        console.print(f"  Snippet: {result.snippet}\n")


def display_json_results(results: List[SearchResult]):
    """Display search results in JSON format."""
    import json
    console.print(json.dumps([r.model_dump() for r in results], indent=2))


def display_csv_results(results: List[SearchResult]):
    """Display search results in CSV format (basic implementation)."""
    # Consider more robust CSV formatting with a library
    print("title,url,snippet,engine")
    for result in results:
        print(f'"{result.title}","{result.url}","{result.snippet}","{result.engine}"')


def display_markdown_results(results: List[SearchResult]):
    """Display search results in Markdown format."""
    for result in results:
        print(f"## {result.title}")
        print(f"*   **Engine:** {result.engine}")
        print(f"*   **URL:** {result.url}")
        print(f"*   **Snippet:** {result.snippet}")
        print("")  # Add spacing between results


@app.command()
def list_proxies(config: str = typer.Option("llamafind.toml", "--config", "-c", help="Path to the configuration file.")):
    """List configured proxies."""
    # Configure logging
    log_level = logging.DEBUG
    logging.basicConfig(level=log_level, stream=sys.stderr)
    logger = logging.getLogger(__name__)

    engine = LlamaFindEngine(config_path=config)
    proxy_manager = engine._load_proxy_manager()
    if proxy_manager:
        proxies = proxy_manager
        if proxies and proxies.proxies:
          table = Table(title="Configured Proxies")
          table.add_column("Protocol", style="cyan")
          table.add_column("IP Address", style="magenta")
          table.add_column("Port", style="green")
          table.add_column("Username", style="yellow")
          table.add_column("Anonymity", style="yellow")
          table.add_column("Latency (s)", style="white")
          table.add_column("Country", style="white")

          for proxy in proxies.proxies:
            table.add_row(
                proxy.protocol,
                proxy.ip_address,
                str(proxy.port),
                proxy.username or "N/A",
                proxy.anonymity,
                str(proxy.latency),
                proxy.country or "N/A",
            )
          console.print(table)
        else:
          console.print("No proxies configured.")
    else:
        console.print("No proxy configuration found in llamafind.toml.  Check proxy settings.")

@app.command()
def test_extract_from_config(config: str = typer.Option("llamafind.toml", "--config", "-c", help="Path to the configuration file.")):
    """Test LLM Extract from config"""
    # Configure logging
    log_level = logging.DEBUG
    logging.basicConfig(level=log_level, stream=sys.stderr)
    logger = logging.getLogger(__name__)

    engine = LlamaFindEngine(config_path=config)
    if not engine.llm:
        typer.echo("No LLM is configured. Cannot test LLM extract.", err=True)
        raise typer.Exit(code=1)

    try:
      class TestExtract(BaseModel):
          text: str
      test_extract_prompt="From the text provided, give the result"
      extracted_text: TestExtract = engine.llm.chat(prompt = "Extract 'test' from this text", response_model=TestExtract, temperature=0.1)
      console.print(f"Extracted Text: {extracted_text.model_dump()}")

    except Exception as e:
        logger.error(f"Error extracting from config: {e}")
        typer.echo(f"Error extracting from config: {e}", err=True)

@app.command()
def version() -> None:
    """
    Show LlamaFind version.
    """
    from llamafind import __version__
    typer.echo(f"LlamaFind version: {__version__}")

# @app.command()
# def serve(
#     host: str = typer.Option("0.0.0.0", "--host", help="Host to bind to"),
#     port: int = typer.Option(8000, "--port", help="Port to listen on"),
# ) -> None:
#     """Runs the API server."""
#     app = create_app()  # Replace with the actual API app instantiation

#     import uvicorn
#     uvicorn.run(app, host=host, port=port)


if __name__ == "__main__":
    app()
content_copy
download
Use code with caution.
Python

(24) Testing Suite (tests/)

tests/__init__.py: (Empty)

Test Modules:

test_core_engine.py (Implemented - see above example code)

test_google_search.py:

Tests the google_search function in llamafind/search_engines/google.py.

Mocks requests.get to simulate network calls.

Tests that the function correctly parses and extracts search results (title, URL, snippet).

Tests error handling (e.g., when requests fail).

test_bing_search.py: (same tests for bing)

test_duckduckgo_search.py: (same tests for duckduckgo)

test_yahoo_search.py: (same tests for yahoo)

test_baidu_search.py: (same tests for baidu)

test_ecosia_search.py: (same tests for ecosia)

test_givewater_search.py: (same tests for givewater)

test_pinterest_search.py: (same tests for pinterest)

test_scraper.py:

Tests for WebScraper functions, including:

fetch_html: Mock network calls.

get_text: Test text extraction.

get_links: Test link extraction, making sure to handle relative URLs correctly.

get_images: Test image URL extraction.

get_tables: Test table extraction (output raw HTML strings).

tests/test_data_models.py: (Implemented - see example code above)

tests/test_proxy_manager.py:

Tests for ProxyManager class.

Tests proxy loading from both file and API sources.

Tests proxy selection and rotation.

Test that the proxy string can be parsed into Proxy objects and they contain the information.

(Future Enhancements): Test proxy health checking (using simulated request/response times).

tests/test_anti_bot.py: (Create separate tests per anti-bot function).

Test that the anti-bot techniques from that are implemented will work, such as generating headers.

Test captcha detection and reporting.

(25) Test Code (Example - tests/test_google_search.py)

# tests/test_google_search.py
import pytest
from unittest.mock import patch, Mock
from llamafind.search_engines import google_search
from llamafind.data_models import SearchResult


@pytest.fixture
def mock_requests_get():
    """
    Creates a mock for the requests.get function.
    """
    mock_response = Mock()
    mock_response.status_code = 200
    mock_response.content = """
        <html>
        <body>
            <div class="g">
                <h3 class="LC20lb MBeu0 dKkQJ">
                    <a href="https://example.com/1">Test Title 1</a>
                </h3>
                <div class="TbwUpd BCy">
                    <span class="st">Test Snippet 1</span>
                </div>
            </div>
            <div class="g">
                <h3 class="LC20lb MBeu0 dKkQJ">
                    <a href="https://example.com/2">Test Title 2</a>
                </h3>
                <div class="TbwUpd BCy">
                    <span class="st">Test Snippet 2</span>
                </div>
            </div>
        </body>
        </html>
        """
    with patch("requests.get", return_value=mock_response) as mock_get:
        yield mock_get


def test_google_search_success(mock_requests_get):
    """Test that google_search returns correct results."""
    results = asyncio.run(google_search("test query", num_results=2))
    assert len(results) == 2
    assert results[0] == SearchResult(
        title="Test Title 1", url="https://example.com/1", snippet="Test Snippet 1", engine="google", raw_data={}
    )
    assert results[1] == SearchResult(
        title="Test Title 2", url="https://example.com/2", snippet="Test Snippet 2", engine="google", raw_data={}
    )

def test_google_search_failure(mock_requests_get):
    """Test that google_search handles request failures."""
    mock_requests_get.side_effect = Exception("Network error")
    results = asyncio.run(google_search("test query", num_results=2))
    assert results == []
content_copy
download
Use code with caution.
Python

(26) setup.py (or pyproject.toml)

# setup.py (Alternative - use if not using poetry, though poetry is recommended)
from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="llamafind",
    version="1.0.0",
    author="Your Name",
    author_email="your.email@example.com",
    description="Your Intelligent Web Search Engine",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/your-github-repo/llamafind",  # Replace with your repo
    packages=find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Programming Language :: Python :: 3.13",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.9",
    install_requires=[ #List all Dependencies
        "requests>=2.32.3",
        "beautifulsoup4>=4.12.2",
        "pydantic>=2.0",
        "toml>=0.10.2",
        "typing-extensions>=4.7.1",
        "openai>=1.52.0",
        "langchain>=0.1.12", # If you use langchain.
        "diskcache>=5.4.0",
        "pyyaml>=6.0",
        "pytest-asyncio",
        "fake-useragent",
        "playwright",
    ],
    entry_points={
        "console_scripts": [
            "llamafind = llamafind.core.engine:main",  # point to the main function
        ],
    },
)
content_copy
download
Use code with caution.
Python
# pyproject.toml (Recommended - if you are using poetry)
[tool.poetry]
name = "llamafind"
version = "1.0.0"
description = "Your Intelligent Web Search Engine"
authors = ["Your Name <your.email@example.com>"]
readme = "README.md"
repository = "https://github.com/your-github-repo/llamafind" # Replace with your repo

[tool.poetry.dependencies]
python = ">=3.9,<4.0"
requests = ">=2.32.3"
beautifulsoup4 = ">=4.12.2"
pydantic = ">=2.0"
toml = ">=0.10.2"
typing-extensions = ">=4.7.1"
openai = ">=1.52.0"
langchain = ">=0.1.12" # If you use langchain.
diskcache = ">=5.4.0"
pyyaml = "*" # config file
pytest-asyncio = "*"
fake-useragent = "*"
playwright = "*" #For Selenium Scraper

[tool.poetry.group.dev.dependencies]
pytest = ">=8.0"
pytest-cov = "*"
pytest-asyncio = "*"
pytest-mock = "*"
ruff = "*"
black = "*"
# add other dev dependencies here.

[tool.poetry.scripts]
llamafind = "llamafind.core.engine:main" #This line defines the command line entry point

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
content_copy
download
Use code with caution.
Toml

III. Coding Prompt for AI Model (Module-by-Module Continued)

### 1. `llamafind/proxy/proxy_manager.py`

**Objective:**  Implement a class to manage proxies, including loading, selection, and health checks.

**Dependencies:** `random`, `typing`, `logging`, `llamafind.data_models`

**Functionality:**

*   Implement the `ProxyManager` class.
*   Initialize:
    *   Takes a configuration dictionary (`config: Dict[str, Any]`) in the constructor.
    *   Loads proxies from a configured source (`file` or `api`) during initialization.
*   Load Proxies (`load_proxies` method):
    *   Loads proxies from a file (specified in the config as `proxy.file_path`) or by invoking an API, based on the `proxy.source` setting in the config.
    *   If the source is a file:
        *   Reads the file (each line assumed to be a proxy string in `IP:PORT`, `USERNAME:PASSWORD@IP:PORT` or similar format).
        *   Validates the proxy string format using a regular expression (e.g., `re.match(r"((?P<username>[^@:]*):(?P<password>[^@:]*)@)?(?P<host>[^:]+):(?P<port>\d+)", proxy_str)`).
        *   Creates `Proxy` objects (from `llamafind/data_models.py`) from valid proxy strings, including splitting user/pass from IP/port when it is available.
        *   Logs warnings for invalid proxy formats.
    *   If the source is an API, fetch a list of proxies from the specified API endpoint (placeholder: the actual implementation will depend on the API).
        *   Authenticate to the API using the API key from the configuration.
        *   Parse the API response and extract proxy information, creating `Proxy` objects.
        *   Handle potential errors during API calls and proxy parsing, logging errors and skipping invalid proxies.
    *   If no proxy source is configured, logs a warning.
*   Get Proxy (`get_proxy` method):
    *   Return a random available `Proxy` object from the `proxies` list.  Returns `None` if no proxies are available.
    *   Implement unit tests to:
        *   Test successful loading of proxies from a file with valid proxy formats.
        *   Test loading of proxies from a file with invalid proxy formats (ensure errors are logged and invalid entries are skipped).
        *   Test handling of a missing proxy file (ensure error logging).
        *   Test successful proxy selection.
        *   Test that `get_proxy()` returns `None` when there are no proxies.
    *   *   Add a method that enables basic proxy testing like the following:

        ```python
        async def test_proxy(self, proxy: Proxy):
          try:
              async with aiohttp.ClientSession() as session: #Use AsyncHTTP client to make requests.
                  connector = ProxyConnector.from_url(
                      f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}"
                      if proxy.username
                      else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}"
                  )
                  async with session.get("http://example.com", connector=connector, timeout=5) as resp:
                      return resp.status == 200 #Check if the status code is 200, if so, this means the proxy is alive.
          except Exception as e:
              print(f"Proxy {proxy} failed: {e}")
              return False
content_copy
download
Use code with caution.### 16. `llamafind/search_engines/duckduckgo.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def duckduckgo_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a DuckDuckGo search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching DuckDuckGo for '{query}' (Results: {num_results})")
    base_url = "https://duckduckgo.com/html"
    params = {"q": query, "max_results": num_results}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="result"):
            title_element = result.find("h2", class_="result__title")
            link_element = result.find("a", class_="result__a")
            snippet_element = result.find("div", class_="result__snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="duckduckgo")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing DuckDuckGo search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 17. `llamafind/search_engines/yahoo.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def yahoo_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Yahoo search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Yahoo for '{query}' (Results: {num_results})")
    base_url = "https://search.yahoo.com/search"
    params = {"q": query, "n": num_results} # 'n' used instead of num.

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="NewsArticle"): #Updated for yahoo
            title_element = result.find("h3", class_="title")
            link_element = result.find("a", class_="thmb")
            snippet_element = result.find("p", class_="txt")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="yahoo")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Yahoo search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 18. `llamafind/search_engines/baidu.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def baidu_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Baidu search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Baidu for '{query}' (Results: {num_results})")
    base_url = "https://www.baidu.com/s"
    params = {"wd": query, "rn": num_results} # Use 'rn' instead of num

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="result c-container"):
            title_element = result.find("h3", class_="t")
            link_element = result.find("a")  # Usually the first a tag inside
            snippet_element = result.find("div", class_="c-abstract")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="baidu")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Baidu search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 19. `llamafind/search_engines/ecosia.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def ecosia_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs an Ecosia search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Ecosia for '{query}' (Results: {num_results})")
    base_url = "https://www.ecosia.org/search"
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="results-list-container"):
            title_element = result.find("a", class_="result__title-link")
            link_element = result.find("a", class_="result__url") #Updated for ecosia
            snippet_element = result.find("p", class_="result-snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="ecosia")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Ecosia search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 20. `llamafind/search_engines/givewater.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def givewater_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a GiveWater search for the given query.

    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching GiveWater for '{query}' (Results: {num_results})")
    base_url = "https://search.givewater.com/serp"
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        soup = BeautifulSoup(response.content, "html.parser")
        results: List[SearchResult] = []
        for result in soup.find_all("div", class_="web-bing__result"):
            title_element = result.find("a")
            link_element = result.find("a")
            snippet_element = result.find("p", class_="b_snippet")
            if title_element and link_element:
                title = title_element.text
                url = link_element.get("href")
                snippet = snippet_element.text if snippet_element else ""
                results.append(
                    SearchResult(title=title, url=url, snippet=snippet, engine="givewater")
                )
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing GiveWater search results: {e}")
        return []
content_copy
download
Use code with caution.
Python
### 21. `llamafind/search_engines/pinterest.py`
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup

from llamafind.data_models import SearchResult, Proxy
from llamafind.proxy.proxy_manager import ProxyManager

logger = logging.getLogger(__name__)


async def pinterest_search(query: str, num_results: int = 10, proxy_manager: Optional[ProxyManager] = None) -> List[SearchResult]:
    """
    Performs a Pinterest search for the given query.
    Args:
        query (str): The search query.
        num_results (int): The number of search results to retrieve (default: 10).
        proxy_manager (Optional[ProxyManager]): To manage the proxy rotation
    Returns:
        List[SearchResult]: A list of search results.
    """
    logger.debug(f"Searching Pinterest for '{query}' (Results: {num_results})")
    base_url = "https://www.pinterest.com/search/pins/" # The base url has been added to the method.
    params = {"q": query}

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "X-Requested-With": "XMLHttpRequest",
        "Accept": "application/json",
        # Adding Accept-Language Header
        "Accept-Language": "en-US,en;q=0.9"
    }
    proxies: Optional[Dict[str, str]] = None
    if proxy_manager:
        try:
            proxy = proxy_manager.get_proxy()
            if proxy and isinstance(proxy, Proxy):
                proxies = {
                    "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                    "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
                }
                logger.debug(f"Using proxy: {proxies}")
        except Exception as e:
            logger.error(f"Error while getting a proxy: {e}")

    try:
        response = requests.get(base_url, params=params, headers=headers, proxies=proxies, timeout=15)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        # Pinterest returns JSON data.
        data = response.json()
        results: List[SearchResult] = []
        for item in data.get('pins', []):
            title = item.get('title')
            url = item.get('url')
            if title and url:
                results.append(SearchResult(title=title, url=url, engine="pinterest", image_url=item.get('images').get('orig').get('url')))
        return results
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {e}")
        return []
    except Exception as e:
        logger.error(f"Error parsing Pinterest search results: {e}")
        return []
content_copy
download
Use code with caution.
Python### 22. `llamafind/scraping/__init__.py`
from .scraper import WebScraper, SeleniumScraper

__all__ = [
    "WebScraper",
    "SeleniumScraper"
]
content_copy
download
Use code with caution.
Python
### 23. `llamafind/scraping/scraper.py` (SeleniumScraper Implemented)
import asyncio
import logging
from typing import List, Optional, Dict

import requests
from bs4 import BeautifulSoup
from fake_useragent import UserAgent
import re
from llamafind.data_models import ScrapeResult, SearchResult
from llamafind.proxy.proxy_manager import ProxyManager
import time  # For rate limiting Selenium requests

logger = logging.getLogger(__name__)


class WebScraper:
    """
    A basic web scraper using requests and BeautifulSoup4.
    """

    def __init__(self, user_agent: str = None, proxies: Optional[Dict[str, str]] = None, timeout: int = 15):
        """
        Initialize the WebScraper.

        Args:
            user_agent (str): User-Agent string to use for requests.
            proxies (Optional[Dict[str, str]]): Optional dictionary of proxies to use (see requests library).
            timeout (int): Timeout for requests in seconds.
        """
        self.user_agent = user_agent or self.get_random_user_agent()
        self.proxies = proxies or {}
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": self.user_agent})
        self.timeout = timeout

    def get_random_user_agent(self) -> str:
        """
        Generates a random user agent string.

        Returns:
            str: A random user agent.
        """
        ua = UserAgent()
        return ua.random

    def fetch_page(self, url: str) -> Optional[str]:
        """
        Fetches the HTML content of a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            Optional[str]: The HTML content as a string, or None if the request fails.
        """
        try:
            logger.debug(f"Fetching URL: {url} using proxy {self.proxies if self.proxies else 'No Proxy'}")
            response = self.session.get(url, timeout=self.timeout, proxies=self.proxies)
            response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
            return response.text
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch {url}: {e}")
            return None

    def get_soup(self, html_content: str) -> Optional[BeautifulSoup]:
        """
        Parses HTML content using BeautifulSoup.

        Args:
            html_content (str): The HTML content as a string.

        Returns:
            Optional[BeautifulSoup]: A BeautifulSoup object, or None if parsing fails.
        """
        if not html_content:
            return None
        try:
            return BeautifulSoup(html_content, "html.parser")
        except Exception as e:
            logger.error(f"Failed to parse HTML: {e}")
            return None

    def get_text(self, url: str) -> str:
        """
        Extracts the full text content of a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            str: The extracted text content.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return ""
        soup = self.get_soup(html_content)
        return soup.get_text(separator=" ", strip=True) if soup else ""

    def get_links(self, url: str) -> List[Dict[str, str]]:
        """
        Extracts all links from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[Dict[str, str]]: A list of dictionaries, where each dictionary represents a link with 'text' and 'href' keys.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        links = []
        if soup:
            for a in soup.find_all("a", href=True):
                text = a.get_text(strip=True)
                href = a["href"]
                absolute_url = self._make_absolute(url, href)
                links.append({"text": text, "href": absolute_url})
        return links

    def get_images(self, url: str) -> List[str]:
        """
        Extracts all image URLs from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[str]: A list of image URLs.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        image_urls = []
        if soup:
            for img in soup.find_all("img", src=True):
                src = img["src"]
                absolute_url = self._make_absolute(url, src)
                image_urls.append(absolute_url)
        return image_urls

    def get_tables(self, url: str) -> List[str]:
        """
        Extracts all tables from a web page.

        Args:
            url (str): The URL of the web page.

        Returns:
            List[str]: A list of table strings.
        """
        html_content = self.fetch_page(url)
        if not html_content:
            return []

        soup = self.get_soup(html_content)
        tables = []
        if soup:
            for table in soup.find_all("table"):
                tables.append(str(table))  # Return raw HTML
        return tables

    def _make_absolute(self, base_url, url):
        """Helper to convert relative URLs to absolute URLs."""
        from urllib.parse import urljoin

        return urljoin(base_url, url)


class SeleniumScraper(WebScraper):
    """
    A web scraper that uses Selenium to render dynamic content.
    """

    def __init__(
            self,
            user_agent: Optional[str] = None,
            proxies: Optional[Dict[str, str]] = None,
            headless: bool = True,
            driver_path: Optional[str] = None,
            timeout: int = 15,
            request_delay: float = 0.1 # Added request delay.
    ):
        from selenium import webdriver
        from selenium.webdriver.firefox.options import Options as FirefoxOptions
        from selenium.webdriver.chrome.options import Options as ChromeOptions
        from selenium.webdriver.chrome.service import Service as ChromeService
        from selenium.webdriver.firefox.service import Service as FirefoxService
        from selenium.webdriver.remote.webdriver import WebDriver
        from webdriver_manager.chrome import ChromeDriverManager
        from webdriver_manager.firefox import GeckoDriverManager
        from selenium.webdriver.remote.webdriver import WebDriver

        super().__init__(user_agent, proxies, timeout)
        self.headless = headless
        self.driver_path = driver_path
        self.driver: Optional[WebDriver] = None
        self.request_delay = request_delay # Added request delay

        self.driver_type: str = "chromium"  # Or "firefox"

    def _setup_driver(self):
        """Set up the Selenium WebDriver (Chromium or Firefox)."""
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options as ChromeOptions
        from selenium.webdriver.chrome.service import Service as ChromeService
        from selenium.webdriver.firefox.options import Options as FirefoxOptions
        from selenium.webdriver.firefox.service import Service as FirefoxService
        from selenium.webdriver.remote.webdriver import WebDriver
        from webdriver_manager.chrome import ChromeDriverManager
        from webdriver_manager.firefox import GeckoDriverManager

        if self.driver:
            return # already set

        if self.driver_type == "chromium":
            chrome_options = ChromeOptions()
            if self.headless:
                chrome_options.add_argument("--headless")  # Run in headless mode
            if self.user_agent:
                chrome_options.add_argument(f"--user-agent={self.user_agent}")
            if self.proxies:
                # Configure proxy for Selenium
                # Only single proxy supported
                proxy = list(self.proxies.values())[0]
                if isinstance(proxy, str):
                  chrome_options.add_argument(f"--proxy-server={proxy}")
                else:
                  logger.error(f"Selenium only supports string based proxies. Got {type(proxy)=}")
            if self.driver_path:
                try:
                    service = ChromeService(executable_path=self.driver_path)
                    self.driver = webdriver.Chrome(service=service, options=chrome_options)
                except Exception as e:
                    logger.error(f"Chrome not found at location: {self.driver_path=}, defaulting to chrome webdriver manager. {e}")
                    self.driver = webdriver.Chrome(ChromeDriverManager().install(), options=chrome_options) # Use webdriver_manager
            else:
                self.driver = webdriver.Chrome(ChromeDriverManager().install(), options=chrome_options) # Use webdriver_manager
        elif self.driver_type == "firefox":
            firefox_options = FirefoxOptions()
            if self.headless:
                firefox_options.add_argument("--headless")  # Run in headless mode
            if self.user_agent:
                firefox_options.add_argument(f"--user-agent={self.user_agent}")
            if self.proxies:
                # Configure proxy for Selenium
                # Only single proxy supported
                proxy = list(self.proxies.values())[0]
                if isinstance(proxy, str):
                  firefox_options.add_argument(f"--proxy-server={proxy}")
                else:
                  logger.error(f"Selenium only supports string based proxies. Got {type(proxy)=}")

            if self.driver_path:
              try:
                service = FirefoxService(executable_path=self.driver_path)
                self.driver = webdriver.Firefox(service=service, options=firefox_options)
              except Exception as e:
                logger.error(f"Firefox not found at location: {self.driver_path=}, defaulting to firefox webdriver manager. {e}")
                self.driver = webdriver.Firefox(executable_path=GeckoDriverManager().install(), options=firefox_options) # Use webdriver_manager
            else:
                self.driver = webdriver.Firefox(executable_path=GeckoDriverManager().install(), options=firefox_options) # Use webdriver_manager
        else:
            raise ValueError(f"Unsupported driver type: {self.driver_type}")
        if self.timeout:
          self.driver.set_page_load_timeout(self.timeout) #Set time out

    def fetch_page(self, url: str) -> Optional[str]:
        """
        Fetches the HTML content of a web page using Selenium.

        Args:
            url (str): The URL of the web page.

        Returns:
            Optional[str]: The HTML content as a string, or None if the request fails.
        """
        try:
            self._setup_driver()
            self.driver.get(url)
            self._wait_for_page_load()
            time.sleep(self.request_delay) # Added request delay
            return self.driver.page_source
        except Exception as e:
            logger.error(f"Failed to fetch (Selenium) {url}: {e}")
            return None
        finally:
            self._teardown_driver()
content_copy
download
Use code with caution.
Python
### 10. `llamafind/proxy/proxy_manager.py`
# llamafind/proxy/proxy_manager.py
import asyncio
import logging
import random
from typing import List, Optional, Dict, Any
from llamafind.data_models import Proxy
from llamafind.scraping import scraper
import requests

logger = logging.getLogger(__name__)


class ProxyManager:
    """
    Manages a list of proxies and provides proxy selection based on configuration.
    """
    def __init__(self, config: Dict[str, Any]):
        """
        Initializes the ProxyManager.

        Args:
            config (Dict): Configuration dictionary (e.g., from `llamafind.toml`).
        """
        self.config = config
        self.proxies: List[Proxy] = []
        self.load_proxies()

    def load_proxies(self):
        """
        Loads proxies from the configured source.  Supports 'file' and 'api' sources.
        """
        proxy_config = self.config.get("proxy", {})
        proxy_source = proxy_config.get("source")
        if not proxy_source:
            logger.info("No proxy source specified in config. Running without proxies.")
            return

        if proxy_source == "file":
            file_path = proxy_config.get("file_path")
            if not file_path:
                logger.warning("File path not specified for proxy source 'file'.")
                return
            try:
                with open(file_path, "r") as f:
                    proxy_list = [line.strip() for line in f if line.strip()]
                # Validate basic proxy format
                validated_proxies: List[Proxy] = []
                for proxy_str in proxy_list:
                    if ":" in proxy_str:
                        parts = proxy_str.split(":")
                        if 2 <= len(parts) <= 4:  # Basic check. Handle SOCKS later
                            # Create Proxy objects
                            try:
                                proxy_obj = self._parse_proxy(proxy_str)
                                validated_proxies.append(proxy_obj)
                            except Exception as e:
                                logger.error(f"Error while parsing proxy: {proxy_str}, {e}. Skipping.")
                        else:
                            logger.warning(f"Invalid proxy format: {proxy_str}. Skipping.")
                    else:
                        logger.warning(f"Invalid proxy format: {proxy_str}. Skipping.")

                self.proxies = validated_proxies
                if self.proxies:
                    logger.info(f"Loaded {len(self.proxies)} proxies from {file_path}")
                else:
                    logger.warning(f"No valid proxies found in {file_path}")
            except FileNotFoundError:
                logger.warning(f"Proxy file not found: {file_path}")
            except Exception as e:
                logger.error(f"Error loading proxies from {file_path}: {e}")
        elif proxy_source == "api":
            api_url = proxy_config.get("api_url")
            api_key = proxy_config.get("api_key")
            if api_url and api_key:
                # Implement API fetching and parsing here (Phase 2).
                try:
                    # Placeholder for API call. Replace with real API call.
                    # Example using requests (replace with an actual API call)
                    response = requests.get(api_url, headers={"Authorization": f"Bearer {api_key}"}, timeout=10)
                    response.raise_for_status()
                    proxy_list = response.json()  # Assuming the API returns a list of proxy strings/objects
                    validated_proxies = []
                    for proxy_data in proxy_list:  # Adapt the parsing logic to your API
                        if isinstance(proxy_data, str):
                            try:
                                proxy_obj = self._parse_proxy(proxy_data)
                                validated_proxies.append(proxy_obj)
                            except Exception as e:
                                logger.error(f"Error while parsing proxy from API: {proxy_data}, {e}. Skipping.")
                        else:
                             try:
                                 proxy_str = f"{proxy_data['ip_address']}:{proxy_data['port']}"
                                 proxy_obj = self._parse_proxy(proxy_str)
                                 proxy_obj.protocol = proxy_data.get('protocol', 'http')
                                 proxy_obj.username = proxy_data.get('username')
                                 proxy_obj.password = proxy_data.get('password')
                                 validated_proxies.append(proxy_obj)
                             except Exception as e:
                                 logger.error(f"Error while parsing proxy data: {proxy_data}, {e}. Skipping.")

                    self.proxies = validated_proxies
                    if self.proxies:
                        logger.info(f"Loaded {len(self.proxies)} proxies from {api_url}")
                    else:
                        logger.warning(f"No valid proxies found from {api_url}")

                except requests.exceptions.RequestException as e:
                    logger.error(f"API request failed: {e}")
                except Exception as e:
                    logger.error(f"Error loading proxies from API: {e}")
            else:
                logger.warning("API URL or API key not specified for proxy, not using proxies")
        else:
            logger.warning(f"Invalid proxy source: {proxy_source}.  Please specify a valid source in llamafind.toml.")

    def _parse_proxy(self, proxy_str: str) -> Proxy:
        """Parses a proxy string of the form user:password@ip:port or ip:port"""
        match = re.match(r"((?P<username>[^@:]*):(?P<password>[^@:]*)@)?(?P<host>[^:]+):(?P<port>\d+)", proxy_str)
        if not match:
            raise ValueError(f"Invalid proxy string format: {proxy_str}")
        data = match.groupdict()
        return Proxy(
            ip_address=data["host"],
            port=int(data["port"]),
            protocol="http",  # Default protocol.  Can update later.
            username=data.get("username"),
            password=data.get("password"),
            anonymity="anonymous", # Default
        )

    def get_proxy(self) -> Optional[Proxy]:
        """
        Gets a random available proxy or None if no proxies are available.
        """
        if not self.proxies:
            return None
        return random.choice(self.proxies)

    def test_proxy(self, proxy: Proxy) -> bool:
      try:
          # create session
          s = requests.Session()
          s.headers.update({"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"})

          proxies = {
              "http": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
              "https": f"{proxy.protocol}://{proxy.username}:{proxy.password}@{proxy.ip_address}:{proxy.port}" if proxy.username else f"{proxy.protocol}://{proxy.ip_address}:{proxy.port}",
          }

          response = s.get("https://www.google.com", proxies=proxies, timeout=5) #test with Google for speed.
          return response.status_code == 200 #Check if the status code is 200, if so, this means the proxy is alive.
      except Exception as e:
          print(f"Proxy {proxy} failed: {e}")
          return False
content_copy
download
Use code with caution.
Python
### 24. `llamafind/anti_bot/anti_bot.py` (Anti-Bot Logic - Implemented)
# llamafind/anti_bot/anti_bot.py
# Placeholder - implement actual anti-bot techniques in Phase 2
from typing import Optional

class AntiBot:
    """Handles anti-bot measures."""

    def __init__(self, user_agent:str = None):
        self.user_agent = user_agent
    def get_user_agent(self) -> str:
        """Get a user agent (implement rotation logic here)."""
        # Implement in Phase 2 (simple-header + simple-useragent)
        return self.user_agent if self.user_agent else "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    def apply_delay(self): # implement
        """Basic Rate Limiting."""
        # Implement basic rate limiting (e.g., time.sleep())
        # in Phase 2.
        pass

    def handle_captcha(self):
        """Placeholder for Captcha handling."""
        # Implement captcha detection and solving in Phase 2
        pass
content_copy
download
Use code with caution.
Python
### 25. `llamafind/cli/cli_interface.py` (CLI - Implemented)**
#llamafind/cli/cli_interface.py
from __future__ import annotations
import os
import sys
import logging
from typing import List, Optional, Dict, Tuple, Any

import typer
from rich.console import Console
from rich.table import Table
from llamafind.core.engine import LlamaFindEngine
from llamafind.data_models import SearchResult, Proxy
from datetime import datetime
# from llamafind.api.web_api import create_app

app = typer.Typer(help="LlamaFind: Your intelligent web search engine.")
console = Console()


def display_text_results(results: List[SearchResult]):
    """Display search results in text format."""
    for i, result in enumerate(results):
        console.print(f"[bold]{i+1}.[/] Engine: [yellow]{result.engine}[/]")
        console.print(f"  Title: [blue]{result.title}[/]")
        console.print(f"  URL: [green]{result.url}[/]")
        console.print(f"  Snippet: {result.snippet}\n")


def display_json_results(results: List[SearchResult]):
    """Display search results in JSON format."""
    import json
    console.print(json.dumps([r.model_dump() for r in results], indent=2))


def display_csv_results(results: List[SearchResult]):
    """Display search results in CSV format (basic implementation)."""
    # Consider more robust CSV formatting with a library
    print("title,url,snippet,engine")
    for result in results:
        print(f'"{result.title}","{result.url}","{result.snippet}","{result.engine}"')


def display_markdown_results(results: List[SearchResult]):
    """Display search results in Markdown format."""
    for result in results:
        print(f"## {result.title}")
        print(f"*   **Engine:** {result.engine}")
        print(f"*   **URL:** {result.url}")
        print(f"*   **Snippet:** {result.snippet}")
        print("")  # Add spacing between results

@app.command()
def search(
        query: str = typer.Argument(..., help="The search query."),
        num_results: int = typer.Option(10, "--num-results", "-n", help="Number of results per engine."),
        engines: List[str] = typer.Option(
            [],
            "--engine",
            "-e",
            help="Search engines to use (e.g., google, bing, duckduckgo).",
            case_sensitive=False,
        ),
        config: str = typer.Option("llamafind.toml", "--config", "-c", help="Path to the configuration file."),
        output_format: str = typer.Option("text", "--output-format", "-f", help="Output format (text, json, csv, markdown)."),
        verbose: bool = typer.Option(False, "--verbose", "-v", help="Enable verbose logging."),
):
    """
    Performs a web search using LlamaFind.
    """
    # Configure logging
    log_level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(level=log_level, stream=sys.stderr)
    logger = logging.getLogger(__name__)

    logger.debug(f"Starting search: Query='{query}', Results per engine={num_results}, Engines={engines}, Config='{config}'")

    # Create engine
    engine = LlamaFindEngine(config_path=config)
    if not engine.search_engines:
        typer.echo("Error: No search engines configured.  Check your configuration file.")
        raise typer.Exit(code=1)

    # Execute the search
    try:
        results = asyncio.run(engine.search(query=query, num_results=num_results))
    except Exception as e:
        logger.exception(f"An error occurred during the search: {e}")
        typer.echo(f"Error during search: {e}", err=True)
        raise typer.Exit(code=1)

    # Output results based on the selected format
    if output_format == "text":
        display_text_results(results)
    elif output_format == "json":
        display_json_results(results)
    elif output_format == "csv":
        display_csv_results(results)
    elif output_format == "markdown":
        display_markdown_results(results)
    else:
        typer.echo(f"Error: Unsupported output format: {output_format}", err=True)
        raise typer.Exit(code=1)


@app.command()
def list_proxies(config: str = typer.Option("llamafind.toml", "--config", "-c", help="Path to the configuration file.")):
    """List configured proxies."""
    # Configure logging
    log_level = logging.DEBUG
    logging.basicConfig(level=log_level, stream=sys.stderr)
    logger = logging.getLogger(__name__)

    engine = LlamaFindEngine(config_path=config)
    proxy_manager = engine._load_proxy_manager()
    if proxy_manager:
        proxies = proxy_manager
        if proxies and proxies.proxies:
          table = Table(title="Configured Proxies")
          table.add_column("Protocol", style="cyan")
          table.add_column("IP Address", style="magenta")
          table.add_column("Port", style="green")
          table.add_column("Username", style="yellow")
          table.add_column("Anonymity", style="yellow")
          table.add_column("Latency (s)", style="white")
          table.add_column("Country", style="white")

          for proxy in proxies.proxies:
            table.add_row(
                proxy.protocol,
                proxy.ip_address,
                str(proxy.port),
                proxy.username or "N/A",
                proxy.anonymity,
                str(proxy.latency),
                proxy.country or "N/A",
            )
          console.print(table)
        else:
          console.print("No proxies configured.")
    else:
        console.print("No proxy configuration found in llamafind.toml.  Check proxy settings.")

@app.command()
def test_extract_from_config(config: str = typer.Option("llamafind.toml", "--config", "-c", help="Path to the configuration file.")):
    """Test LLM Extract from config"""
    # Configure logging
    log_level = logging.DEBUG
    logging.basicConfig(level=log_level, stream=sys.stderr)
    logger = logging.getLogger(__name__)

    engine = LlamaFindEngine(config_path=config)
    if not engine.llm:
        typer.echo("No LLM is configured. Cannot test LLM extract.", err=True)
        raise typer.Exit(code=1)

    try:
      class TestExtract(BaseModel):
          text: str
      test_extract_prompt="From the text provided, give the result"
      extracted_text: TestExtract = engine.llm.chat(prompt = "Extract 'test' from this text", response_model=TestExtract, temperature=0.1)
      console.print(f"Extracted Text: {extracted_text.model_dump()}")

    except Exception as e:
        logger.error(f"Error extracting from config: {e}")
        typer.echo(f"Error extracting from config: {e}", err=True)

@app.command()
def version() -> None:
    """
    Show LlamaFind version.
    """
    from llamafind import __version__
    typer.echo(f"LlamaFind version: {__version__}")

# @app.command()
# def serve(
#     host: str = typer.Option("0.0.0.0", "--host", help="Host to bind to"),
#     port: int = typer.Option(8000, "--port", help="Port to listen on"),
# ) -> None:
#     """Runs the API server."""
#     app = create_app()  # Replace with the actual API app instantiation

#     import uvicorn
#     uvicorn.run(app, host=host, port=port)


if __name__ == "__main__":
    app()
content_copy
download
Use code with caution.
Python

Coding Prompt - AI: Begin Coding and Testing!

With all code files ready, the AI model should now:

Create a basic setup.py file to ensure the package can be installed.

Make sure that the example runs by running python -m llamafind search python -n 2.

Create a test suite for each module (as defined). Use pytest for running tests and for mocking of API calls or internal methods.

Test the modules and make sure they're working.

Important Considerations and Next Steps:

API Key Handling: (IMPORTANT - Not implemented in the files, but crucial for actual use)

If you're using the OpenAI API, ensure the API key is never hardcoded in the source code. Use environment variables (e.g., OPENAI_API_KEY) or a secure configuration mechanism. The example llamafind.toml shows this.

Error Handling and Retries: Implement robust error handling throughout the code. Implement retries to handle network issues and temporary API errors.

Rate Limiting: Enforce rate limiting in the scraper and LLM interaction to avoid being blocked by providers, and to adhere to API usage policies (crucial for production use - instructor.Mode.TOOLS and primp will help).

Ethical Scraping: Ensure the program is used ethically by respecting robots.txt files and terms of service of target websites. Include a disclaimer/ethical code of conduct in the project.

With these instructions, you should be able to make the code runnable, test it, and start building a functional web search engine. Good luck!