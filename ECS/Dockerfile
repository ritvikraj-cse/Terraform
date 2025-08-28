# Use the official lightweight Python 3.11 image as the base image
FROM python:3.11-slim

# Set the working directory inside the container
# All subsequent commands (COPY, RUN, CMD) will be relative to /app
WORKDIR /app

# Copy the Python dependencies file to the container first
# This allows Docker to cache this layer if requirements.txt hasn't changed
COPY requirements.txt /app/

# Install the Python dependencies
# --no-cache-dir prevents pip from caching downloaded packages, keeping the image small
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire application code from the host into the container
# The app folder contains app.py and any other necessary files
COPY app/ /app

# Expose the port the Flask application will run on
# This is the port that should be mapped when running the container
EXPOSE 3000

# Command to run the Flask application when the container starts
# Since WORKDIR is /app, and app.py is copied there, we can run it directly
CMD ["python", "app.py"]



