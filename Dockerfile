FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        fortune-mod \
        cowsay \
        netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

# Add cowsay path
ENV PATH="/usr/games:${PATH}"

# Create working directory
WORKDIR /app

# Copy script
COPY wisecow.sh /app/wisecow.sh

# Fix line endings and make executable
RUN sed -i 's/\r$//' /app/wisecow.sh && \
    chmod +x /app/wisecow.sh

# Expose application port
EXPOSE 4499

# Run the script
CMD ["/app/wisecow.sh"]
