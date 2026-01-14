FROM python:3.11-slim

WORKDIR /app

# Copy scripts
COPY scripts/ /app/scripts/

# Install dependencies
RUN pip install firebase-admin

# Default command
CMD ["bash"]
