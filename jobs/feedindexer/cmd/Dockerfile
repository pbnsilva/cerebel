FROM golang:1.10

RUN mkdir -p /usr/src/app 
WORKDIR /usr/src/app 

RUN wget https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-1.14.0.tar.gz
RUN ls
RUN tar -xzf libtensorflow-cpu-linux-x86_64-1.14.0.tar.gz -C /usr/local
RUN ldconfig

COPY bin/feedindexer .
ADD mtcnn.pb .
ENV LD_LIBRARY_PATH "/usr/local/lib"
ENTRYPOINT ["./feedindexer"]
