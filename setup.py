#!/usr/bin/env python3
"""
LlamaSearchAI Package Installer

This script installs the LlamaSearchAI package.
"""

import os
import re
from setuptools import setup, find_packages

# Read version from package __init__.py
with open(os.path.join("llamafind_ultra", "__init__.py"), "r") as f:
    version_match = re.search(r"__version__\s*=\s*['\"]([^'\"]*)['\"]", f.read())
    version = version_match.group(1) if version_match else "0.1.0"

# Read requirements
with open("requirements.txt", "r") as f:
    requirements = [line.strip() for line in f if line.strip() and not line.startswith("#")]

# Define optional dependencies
extras_require = {
    "api": [
        "fastapi>=0.100.0",
        "uvicorn>=0.23.0", 
        "starlette>=0.27.0",
        "websockets>=11.0.0"
    ],
    "dev": [
        "pytest>=7.4.0",
        "black>=23.3.0",
        "isort>=5.12.0",
        "flake8>=6.0.0"
    ],
    "vector": [
        "faiss-cpu>=1.7.4"
    ],
    "mlx": [
        "mlx>=0.0.8"
    ]
}

# All extras
extras_require["all"] = [pkg for group in extras_require.values() for pkg in group]

setup(
    name="llamafind_ultra-llamasearch",
    version="1.0.0",
    description="Advanced search platform with AI research capabilities",
    author="LlamaSearch AI",
    author_email="nikjois@llamasearch.ai",
    packages=find_packages(),
    python_requires=">=3.9",
    install_requires=[
        "fastapi>=0.110.0",
        "uvicorn>=0.27.0",
        "pydantic>=2.6.0",
        "httpx>=0.26.0",
        "python-dotenv>=1.0.0",
        "toml>=0.10.2",
        "prometheus-client>=0.17.0",
        "tenacity>=8.2.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.4.0",
            "black>=23.7.0",
            "isort>=5.12.0",
            "mypy>=1.5.0",
        ],
        "ai": [
            "openai>=1.10.0",
            "anthropic>=0.7.0",
        ],
        "search": [
            "perplexity>=0.1.0",
            "tavily-python>=0.2.0",
            "brave-search>=0.1.3",
        ],
    },
    entry_points={
        "console_scripts": [
            "llamasearch=llamafind_ultra.server.app:run_server",
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    package_dir={"": "src"},
    packages=find_packages(where="src"),
) 
# Updated in commit 5 - 2025-04-04 16:59:28

# Updated in commit 13 - 2025-04-04 16:59:32

# Updated in commit 21 - 2025-04-04 16:59:35

# Updated in commit 29 - 2025-04-04 16:59:38

# Updated in commit 5 - 2025-04-05 14:24:21

# Updated in commit 13 - 2025-04-05 14:24:21

# Updated in commit 21 - 2025-04-05 14:24:21

# Updated in commit 29 - 2025-04-05 14:24:22

# Updated in commit 5 - 2025-04-05 15:00:15

# Updated in commit 13 - 2025-04-05 15:00:15

# Updated in commit 21 - 2025-04-05 15:00:15

# Updated in commit 29 - 2025-04-05 15:00:15

# Updated in commit 5 - 2025-04-05 15:09:45

# Updated in commit 13 - 2025-04-05 15:09:46

# Updated in commit 21 - 2025-04-05 15:09:46

# Updated in commit 29 - 2025-04-05 15:09:46
