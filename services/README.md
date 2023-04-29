```/store``` - record store API  
```/search``` - search API  
```/annotation``` - text and image annotation API
```/eventhose``` - logging service for atomic event data   
```/elasticsearch``` - elasticsearch deployments configs

## Set up your environment
1. Install the Google Cloud SDK  
Go to [https://cloud.google.com/sdk/downloads](https://cloud.google.com/sdk/downloads), download and follow the steps to install and set up the SDK. Be sure to run the install script and that the Cloud SDK tools are added to your path.  
When running `gcloud init`, select the `cerebel-prod` project ID and the `europe-west1-b` zone for Compute Engine.   
2. Install `kubectl`  
```gcloud components install kubectl```  
3. Authenticate the cluster:  
```gcloud container clusters get-credentials cluster-1```
4. Authenticate the requests to the Container Registry:  
```gcloud auth configure-docker```  
4. Clone the repository  
If you haven't done it already, clone Cerebel's repo to your GOPATH.  
5. Fetch dependencies  
We use [Dep](https://github.com/golang/dep) for dependency management.  
First, install Dep by following the instructions. You can just fo `brew install dep` on a Mac.  
Then, `cd` to the root of the repo and run `dep ensure`, this will fetch all the dependencies needed to run the services.  

## Makefiles
Every service has an associated `Makefile` that you can use to build binaries, build and push a docker image, and update/deploy the service. To see all the commands available, `cd` into `cmd/srv` under a service directory, and run `make help`.  

## Port forwarding
You can access the services directly by port forwarding to a pod. For example:  
```kubectl get pods
NAME                             READY     STATUS    RESTARTS   AGE
balancer-69f6f5b549-dkvhh        1/1       Running   0          2h
elasticsearch-3325784831-28g2r   1/1       Running   0          5d
face-8cc6b57f6-smz66             1/1       Running   0          2d
search-688c9946d8-pbhfs          1/1       Running   0          1d
store-3391569057-j286f           1/1       Running   5          5d
annotation-582147152-v95rf           1/1       Running   1          5d
```  
```kubectl port-forward search-688c9946d8-pbhfs 8080:8080```  
Now you can access the search service directly on `http://localhost:8080`.
