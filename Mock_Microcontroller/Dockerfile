FROM python:3.11

WORKDIR /mock

# Set locale to avoid warnings/errors
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# Install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY main.py .

CMD ["python", "main.py"]