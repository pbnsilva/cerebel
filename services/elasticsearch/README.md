# Elasticsearch cluster

As of now the cluster has the simpliest setup: all nodes are the data and master-eligible nodes, no client nodes.
[fabric8 plugin](https://github.com/fabric8io/elasticsearch-cloud-kubernetes) for Kube discovery is used.

### Deploy

```bash
make deploy
```

### Scale the cluster

```bash
# forward the port of a very first node
kubectl port-forward $(kubectl get pod | grep 'elasticsearch-cluster-0' | tr -s ' ' | cut -d ' ' -f 1) 9200:9200

# scale the set
kubectl scale --replicas=3 statefulset elasticsearch-cluster

# IMPORTANT: update minimum_master_nodes setting to [<new-nodes-count>/2 + 1]
# In case of upscaling some waiting time could be necessary until all new nodes are initialised.
curl -XPUT localhost:9200/_cluster/settings -d '{
    "persistent" : {
        "discovery.zen.minimum_master_nodes" : 2
    }
}'

# monitor health
watch -c -d -n 2 curl -s 'http://localhost:9200/_cat/health?v'
```

In case of downscaling persistent storages are kept. Check if they are still needed.
