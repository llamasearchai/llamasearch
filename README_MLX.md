# LlamaFind with MLX-Accelerated Ranking

This document provides instructions on how to run LlamaFind with MLX-accelerated ranking.

## Overview

LlamaFind now includes MLX-accelerated ranking for all search engines, including:

- Web search engines (Google, Bing, DuckDuckGo)
- Hybrid search engine (combining results from multiple sources)
- Travel search engines (Flights, Hotels, Packages)

The MLX-accelerated ranking provides faster and more accurate search results by leveraging machine learning to rank results based on relevance, freshness, authority, and diversity.

## Prerequisites

- Python 3.8 or higher
- MLX (optional, but recommended for best performance)

### Installing MLX

MLX is an optional dependency that provides accelerated ranking. To install MLX:

```bash
pip install mlx
```

If MLX is not available, LlamaFind will automatically fall back to a simpler ranking algorithm.

## Running Tests

To verify that MLX-accelerated ranking is working correctly, you can run the test script:

```bash
python test_llamafind.py
```

This will test all search engines with MLX-accelerated ranking and generate a report.

### Test Options

- `--no-mlx`: Disable MLX acceleration and use the fallback ranker
- `--web`: Start the web server after running tests

Example:

```bash
python test_llamafind.py --web
```

## Running the Web Server

To start the LlamaFind web server:

```bash
python run_llamafind.py
```

This will start the web server on http://0.0.0.0:8000 by default.

### Web Server Options

- `--host`: Host to bind to (default: 0.0.0.0)
- `--port`: Port to bind to (default: 8000)
- `--reload`: Enable auto-reload for development
- `--no-mlx`: Disable MLX acceleration

Example:

```bash
python run_llamafind.py --host 127.0.0.1 --port 8080 --reload
```

## MLX Ranking Configuration

The MLX ranker can be configured with different weights for various ranking factors:

### Web Search

- Relevance: 60%
- Authority: 15%
- Freshness: 10%
- Diversity: 15%

### Flight Search

- Relevance: 50%
- Price: 30%
- Airline: 10%
- Freshness: 10%

### Hotel Search

- Relevance: 40%
- Price: 30%
- Rating: 20%
- Freshness: 10%

### Package Search

- Relevance: 30%
- Price: 30%
- Discount: 30%
- Freshness: 10%

## Troubleshooting

### MLX Not Available

If you see a warning that MLX is not available, it means that the MLX package is not installed or not compatible with your system. LlamaFind will automatically fall back to a simpler ranking algorithm.

To install MLX:

```bash
pip install mlx
```

### Web Server Not Starting

If the web server fails to start, check the following:

1. Make sure you're running the script from the LlamaFind project directory
2. Check that all dependencies are installed
3. Check the log file (`llamafind_web.log`) for error messages

## Performance Considerations

- MLX-accelerated ranking is significantly faster than the fallback ranker, especially for large result sets
- The first search may be slower due to initialization overhead
- Caching is enabled by default to improve performance for repeated searches 