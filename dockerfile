FROM python:3.12-slim-trixie

# Set the working directory inside the container
WORKDIR /app

# Update Image and install system dependencies
RUN apt-get update

# Install Python dependencies
RUN pip install --upgrade pip
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . /app/

# Expose the port the app runs on
EXPOSE 8000

# Run the application using Gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "-c", "gunicorn.conf.py", "notesy.wsgi:application"]
