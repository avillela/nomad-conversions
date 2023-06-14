# k0s in Nomad

## Run k0s using Docker

```bash
docker run -it --platform linux/amd64 \
    --name k0s --hostname k0s \
    --privileged \
    -v /var/lib/k0s \
    -p 6443:6443 \
    docker.io/k0sproject/k0s:latest

# Try some kubectl commands
docker exec k0s kubectl get ns
docker exec k0s kubectl get svc

# Get kubeconfig file
docker exec k0s cat /var/lib/k0s/pki/admin.conf
```

## Scratchpad

```bash
ls -al /var/lib/k0s/bin/etcd && chmod 777 /var/lib/k0s/bin/etcd && ls -al /var/lib/k0s/bin/etcd
```