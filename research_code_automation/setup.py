#!/usr/bin/env python3
"""Setup script for Research Code Automation Tool."""

from setuptools import setup, find_packages
import os
import re

# Read the version from __init__.py
with open(os.path.join(os.path.dirname(__file__), "__init__.py"), "r") as f:
    content = f.read()
    match = re.search(r'__version__\s*=\s*[\'"]([^\'"]*)[\'"]', content)
    version = match.group(1) if match else "0.1.0"

# Read the long description from README.md
with open("README.md", "r", encoding="utf-8") as f:
    long_description = f.read()

# Core dependencies
REQUIRES = [
    "fastapi>=0.95.0",
    "uvicorn>=0.22.0",
    "sqlalchemy>=2.0.15",
    "pydantic>=1.10.7",
    "python-dotenv>=1.0.0",
    "httpx>=0.24.0",
    "aiohttp>=3.8.4",
    "aiofiles>=23.1.0",
    "click>=8.1.3",
    "click-help-colors>=0.9.1",
    "rich>=13.4.2",
    "PySimpleGUI>=4.60.4",
    "PyPDF2>=3.0.1",
    "openai>=1.1.0",
    "alembic>=1.11.1",
    "asyncpg>=0.27.0",
    "aiosqlite>=0.18.0",
    "tqdm>=4.65.0",
    "colorama>=0.4.6",
    "structlog>=23.2.0",
    "tenacity>=8.2.0",
    "requests>=2.31.0",
    "beautifulsoup4>=4.12.2",
    "pybtex>=0.24.0",
    "fake-useragent>=1.1.1",
    "flask>=2.2.0",
    "flask-cors>=3.0.10",
    "numpy>=1.24.0",
    "pillow>=9.4.0",
    "prometheus-client>=0.16.0",
    "anthropic>=0.3.0",
    "lru-dict>=1.1.8",
    "torch>=2.0.0",
    "transformers>=4.26.0",
    "librosa>=0.10.0",
    "setuptools>=68.0.0",
]

# Optional dependencies for MLX and advanced models
EXTRAS = {
    "ocr": [
        "pytesseract>=0.3.10",
        "pillow>=9.4.0",
        "pymupdf>=1.21.0",
        "ocrmypdf>=15.1.0",
    ],
    "scraping": [
        "playwright>=1.35.1",
        "beautifulsoup4>=4.12.2",
        "selenium>=4.9.0",
    ],
    "academic": [
        "arxiv>=1.4.2",
        "pymed>=1.4.0",
        "biopython>=1.81",
    ],
    "mlx": [
        "mlx>=0.0.5",
        "mlx-lm>=0.0.3",
        "mlx-vision>=0.0.2",
    ],
    "gpu": [
        "torch>=2.0.0", 
        "torchvision>=0.15.0",
        "torchaudio>=2.0.0",
    ],
    "whisper": [
        "whisper>=1.0.0",
        "ffmpeg-python>=0.2.0",
    ],
    "dev": [
        "pytest>=7.4.0",
        "pytest-asyncio>=0.21.1",
        "black>=23.3.0",
        "isort>=5.12.0",
        "mypy>=1.3.0",
        "flake8>=6.0.0",
        "pylint>=2.17.0",
        "tox>=4.11.0",
    ],
}

# Add a 'complete' option that includes all extras
EXTRAS["complete"] = sum([pkg for sublist in EXTRAS.values() for pkg in sublist], [])
EXTRAS["llamasearch_ultra"] = EXTRAS["mlx"] + [
    "mix-whisper>=0.0.1",
    "mix-hub>=0.0.1", 
    "mix-use>=0.0.1",
    "mix-embeddings>=0.0.1",
    "mix-textgen>=0.0.1",
]

setup(
    name="research_code_automation",
    version=version,
    author="LlamaSearchAI Team",
    author_email="team@llamasearch.ai",
    description="Advanced research automation tool integrated with LlamaSearchAI",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/llamasearchai/research-code-automation",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Science/Research",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Topic :: Scientific/Engineering",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
    ],
    python_requires=">=3.9",
    install_requires=REQUIRES,
    extras_require=EXTRAS,
    entry_points={
        "console_scripts": [
            "research-code-automation=research_code_automation.main:main",
        ],
    },
    include_package_data=True,
    package_data={
        "research_code_automation": ["*.md", "*.txt", "*.yml", "*.yaml"],
    },
) 