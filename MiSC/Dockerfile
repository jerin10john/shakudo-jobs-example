# Use the official lightweight Python image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy application files (create a basic hello world script)
RUN echo 'print("Hello from the container!")' > app.py

# Set the command to run the script
CMD ["python", "app.py"]
