FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the package files
COPY setup.py .
COPY README.md .
COPY llamafind_ultra ./llamafind_ultra

# Install the package
RUN pip install -e .

# Create config directory
RUN mkdir -p /app/config

# Expose the port
EXPOSE 8000

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Run the API server
CMD ["python", "-m", "llamafind_ultra.server.app", "--host", "0.0.0.0", "--port", "8000"] 