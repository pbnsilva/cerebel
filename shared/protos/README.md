### Install Python GRP tools
```
pip install grpcio-tools
```

### Generate Python code
Example:
```
python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. store.proto
```

