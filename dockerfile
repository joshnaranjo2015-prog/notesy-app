# === Stage 1: Frontend Build ===
FROM node:20-alpine AS frontend-builder
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the frontend source code and build it
COPY apps/notes/static_src/ apps/notes/static_src/
RUN npm run build

# === Stage 2: Final Django Python Environment ===
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
COPY . .
COPY --from=frontend-builder /app/static/ staticfiles/

# Expose the port the app runs on
EXPOSE 8000
