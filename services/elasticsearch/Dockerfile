FROM elasticsearch:5.3.1-alpine

COPY config /usr/share/elasticsearch/config

# These variables are used in the config to configure fabric8 kubernetes discovery plugin
ENV SERVICE         "test"
ENV NAMESPACE       "test"
ENV CLUSTER_NAME    "test-cluster"

RUN elasticsearch-plugin install io.fabric8:elasticsearch-cloud-kubernetes:5.3.1
