# AJD — AI Agents Job Dashboard
# Build: docker build -t ajd .
# Run:   docker run -d -p 5080:5080 -v $PWD/data:/app/data -v $PWD/projects.json:/app/projects.json ajd

FROM python:3.11-slim

# Install system deps (minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first (cache layer)
COPY app/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy application code
COPY app/ /app/app/
COPY install.sh /app/install.sh

# Create data directories
RUN mkdir -p /app/data/snapshots

# Default port (can be overridden with AJD_PORT env)
ENV AJD_PORT=5080
ENV AJD_HOME=/app

# Expose port
EXPOSE 5080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://127.0.0.1:${AJD_PORT}/ || exit 1

# Run the app
CMD ["python3", "app/app.py"]