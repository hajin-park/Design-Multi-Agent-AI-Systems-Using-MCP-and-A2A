FROM python:3.13-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl for the image's CPU architecture (amd64 or arm64).
# MAKDO uses it to read the kubeconfig of the cluster it registers with k8s-ai.
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$(dpkg --print-architecture)/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

WORKDIR /app

# Install MAKDO dependencies (ai-six 0.14.6+ passes environment variables to MCP servers)
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy MAKDO source
COPY src ./src

# Create required directories
RUN mkdir -p /app/config /app/logs /tmp/makdo/memory /tmp/makdo/tools /tmp/makdo/mcp_tools

# Set Python to run unbuffered so logs appear immediately
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Run MAKDO main entry point
CMD ["python", "-m", "src.makdo.main"]
