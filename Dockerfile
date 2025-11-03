# Dockerfile
FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive \
    NODE_MAJOR=18

# System deps for Frappe/Drive and bench tooling
RUN apt-get update && apt-get install -y \
    curl git build-essential mariadb-client redis-tools \
    ffmpeg libmagic1 \
  && rm -rf /var/lib/apt/lists/*

# Node and Yarn for building assets
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
  && apt-get update && apt-get install -y nodejs \
  && npm install -g yarn \
  && rm -rf /var/lib/apt/lists/*

# Bench CLI
RUN pip install --no-cache-dir frappe-bench

# Use a work dir that matches the web disk mount so bench persists
WORKDIR /workspace

# Init script
COPY init.sh /usr/local/bin/init.sh
EXPOSE 8000

CMD ["bash", "-lc", "/usr/local/bin/init.sh"]
