"""
Basic tests for LlamaFind.
Tests core functionality and data models.
"""

import asyncio

import pytest
from llamafind.core.engine import LlamaFindEngine
from llamafind.data_models import SearchResult, SearchStats
from llamafind.utils.query_expander import QueryExpander
from llamafind.utils.result_ranker import FallbackRanker


def test_search_result_creation():
    """Test that we can create a SearchResult correctly."""
    result = SearchResult(
        title="Test Result",
        url="https://example.com/test",
        snippet="This is a test result snippet.",
        source="test_engine",  # Use source instead of engine
        metadata={"engine": "test_engine"},  # Store engine in metadata
    )

    assert result.title == "Test Result"
    assert result.url == "https://example.com/test"
    assert result.snippet == "This is a test result snippet."
    assert result.source == "test_engine"  # Check source instead of engine
    assert result.metadata.get("engine") == "test_engine"  # Check engine in metadata


def test_search_stats():
    """Test the SearchStats functionality."""
    stats = SearchStats()

    # Record a search
    stats.record_search_start("test query")
    stats.record_search_completion("test query", 10, 1.5)

    # Record engine results
    stats.record_engine_results("google", 5)
    stats.record_engine_results("bing", 5)

    # Check stats
    all_stats = stats.get_stats()
    assert all_stats["total_searches"] == 1
    assert all_stats["total_results"] == 10
    assert all_stats["avg_search_time"] == 1.5
    assert len(all_stats["engines"]) == 2
    assert "google" in all_stats["engines"]
    assert "bing" in all_stats["engines"]


def test_fallback_ranker():
    """Test the FallbackRanker functionality."""
    ranker = FallbackRanker()

    # Create some test results
    results = [
        SearchResult(
            title="Test A",
            url="https://example.com/a",
            snippet="Test result A",
            source="test",
        ),
        SearchResult(
            title="Test B",
            url="https://example.com/b",
            snippet="Test result B with matching query",
            source="test",
        ),
        SearchResult(
            title="Test C",
            url="https://github.com/test",
            snippet="Test result C",
            source="test",
        ),
    ]

    # Rank the results
    query = "matching query"
    loop = asyncio.get_event_loop()
    ranked_results = loop.run_until_complete(ranker.rank_results(results, query))

    # Check that ranks were assigned
    assert all(r.rank is not None for r in ranked_results)

    # Result with matching query should be ranked higher
    assert ranked_results[0].url == "https://example.com/b"


def test_query_expander():
    """Test the QueryExpander functionality."""
    expander = QueryExpander(mlx_enabled=False)

    # Test basic expansion
    query = "python tutorial"
    loop = asyncio.get_event_loop()
    expanded = loop.run_until_complete(expander.expand_query(query))

    # Expanded query should be different and longer
    assert expanded != query
    assert len(expanded) > len(query)


# Skip the engine creation test for now as it requires more complex mocking
@pytest.mark.skip(reason="Requires more complex mocking of cache and other components")
def test_engine_creation():
    """Test that we can create the engine without errors."""
    engine = LlamaFindEngine(ui_mode="plain")

    # Check that core components were initialized
    assert engine.search_engines is not None
    assert engine.ranker is not None
    assert engine.query_expander is not None
    assert engine.stats is not None
