FROM ubuntu:22.04

# Install prerequisites
RUN apt-get update && \
    apt-get install -y fortune-mod cowsay netcat-openbsd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set PATH to include cowsay
ENV PATH="/usr/games:${PATH}"

# Create app directory
WORKDIR /app

# Copy the wisecow script
COPY wisecow.sh .

# Convert line endings and make script executable
RUN sed -i 's/\r$//' wisecow.sh && chmod +x wisecow.sh

# Expose port
EXPOSE 4499

# Run the application
CMD ["./wisecow.sh"]
