# Fooocus Docker Image
# Based on Python 3.10 with CUDA support for GPU acceleration

FROM nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3.10-venv \
    python3-pip \
    git \
    wget \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.10 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Upgrade pip
RUN python3 -m pip install --upgrade pip

# Install PyTorch with CUDA support
RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Create app directory
WORKDIR /app

# Clone Fooocus repository
RUN git clone https://github.com/lllyasviel/Fooocus.git . && \
    git checkout main

# Install Python dependencies
RUN pip3 install -r requirements_versions.txt

# Create directories for models and outputs
RUN mkdir -p /app/models /app/outputs

# Expose port for Gradio interface
EXPOSE 7865

# Set up volume mount points
VOLUME ["/app/models", "/app/outputs"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:7865/ || exit 1

# Run Fooocus
CMD ["python3", "entry_with_update.py", "--listen", "0.0.0.0", "--port", "7865"]
