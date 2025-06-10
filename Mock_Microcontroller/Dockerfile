FROM python:3.13

WORKDIR /app

# Install necessary system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Set locale to avoid warnings/errors
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --verbose -r requirements.txt

# Copy application code
COPY main.py .

CMD ["python", "main.py"]