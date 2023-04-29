# Suggester indexer job

Runs suggester indexing: collects query suggestions and saves them in the suggester index.   

```deployment.yaml``` - deployment configuration for periodic job.  
```job.yaml``` - deployment configuration for job (run `kubectl create -f job.yaml` to run this once).  


## Build & Run

### Build

```bash
make
```

### Run

```bash
make run
```

### Clean binaries

```bash
make clean
```

### Build docker image

```bash
make docker-build
```

### Push docker image to registry

```bash
make docker-push
```

### Deploys the job

```bash
make deploy
```
