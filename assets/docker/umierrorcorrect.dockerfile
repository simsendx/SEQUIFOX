################## BASE IMAGE ######################
FROM ubuntu:22.04

################## METADATA ######################
LABEL base.image="ubuntu:22.04"
LABEL version="1"
LABEL software="umierrorcorrect"
LABEL software.version="0.29"
LABEL about.summary="Umi error correct pipeline"
LABEL about.home="https://github.com/stahlberggroup/umierrorcorrect"
LABEL about.tags="Genomics"

# Set non-interactive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Update and install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        make \
        curl \
        libbz2-dev \
        liblzma-dev \
        libz-dev \
        libxml2-dev \
        libcurl4-openssl-dev \
        libjpeg-dev \
        bzip2 \
        xz-utils \
        gcc \
        g++ \
        python3-dev \
        python3-pip \
        python3-setuptools \
        pigz \
        bwa && \
    pip3 install --no-cache-dir wheel Cython pysam scipy matplotlib cutadapt umierrorcorrect && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
