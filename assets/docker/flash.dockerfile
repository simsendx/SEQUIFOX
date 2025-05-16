# Use Ubuntu as the base image
FROM ubuntu:20.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists and install necessary dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /opt

# Clone the FLASH-lowercase-overhang repository
RUN git clone https://github.com/Jerrythafast/FLASH-lowercase-overhang.git

# Set the working directory to the cloned repository
WORKDIR /opt/FLASH-lowercase-overhang

# Compile the FLASH tool
RUN make

# Add the compiled binary to the system PATH
ENV PATH="/opt/FLASH-lowercase-overhang:${PATH}"

# Set the default command to display the help message
CMD ["flash", "--help"]
