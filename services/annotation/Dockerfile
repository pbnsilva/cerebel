FROM ubuntu:16.04
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        libsm6 \
        libxrender1 \
        libxext6 \
        pkg-config \
        python3-dev \
        python3-pip \
        rsync \
        unzip \
        libhdf5-dev \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN pip3 install --upgrade pip
RUN pip3 install -U setuptools
RUN pip3 install http://download.pytorch.org/whl/cu80/torch-0.3.1-cp35-cp35m-linux_x86_64.whl
RUN pip3 install torchvision
RUN pip3 install google-cloud-storage pillow grpcio
RUN pip3 install opencv-python
RUN pip3 install scipy
RUN pip3 install scikit-image scikit-learn
RUN pip3 install -U spacy
RUN python3 -m spacy download en
RUN pip3 install rdflib rdflib-jsonld
ADD ml ml/
RUN pip3 install /ml/.
ADD api /api
ADD run.py /run.py
CMD ["python3", "/run.py"]
