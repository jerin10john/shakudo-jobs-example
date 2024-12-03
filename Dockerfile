# Use the official lightweight Python image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy application files (create a basic app in the container)
RUN echo 'from http.server import SimpleHTTPRequestHandler, HTTPServer\n' \
    'import sys\n\n' \
    'port = 8080\n' \
    'print("Serving on port", port)\n' \
    'HTTPServer(("0.0.0.0", port), SimpleHTTPRequestHandler).serve_forever()\n' \
    > app.py

# Set the command to run the server
CMD ["python", "app.py"]
