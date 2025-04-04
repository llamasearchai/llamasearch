FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    tesseract-ocr \
    tesseract-ocr-eng \
    ocrmypdf \
    libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create data and downloads directories
RUN mkdir -p data downloads cache

# Expose ports
EXPOSE 8000

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV DOWNLOAD_DIR=/app/downloads
ENV LLAMASEARCH_CACHE_DIR=/app/cache
ENV LLAMASEARCH_DATA_DIR=/app/data

# Define entry point with default as API server
ENTRYPOINT ["python", "-m", "research_code_automation.main"]
CMD ["--api", "--host", "0.0.0.0", "--port", "8000"] 