# Nomad Conversions

Repo of Docker Compose and/or Kubernetes manifests converted to Nomad Jobspecs.

If I'm feeling extra-adventurous, I will try creating Nomad Packs for these.

Work in progress.

## Deployment Steps

1. Add endpoints to `/etc/hosts`

    ```bash
    # For HashiQube
    127.0.0.1   traefik.localhost
    127.0.0.1   otel-collector-http.localhost
    127.0.0.1   otel-collector-grpc.localhost
    127.0.0.1   adservice.localhost
    127.0.0.1   cartservice.localhost
    127.0.0.1   checkoutservice.localhost
    127.0.0.1   currencyservice.localhost
    127.0.0.1   emailservice.localhost
    127.0.0.1   featureflagservice.localhost
    127.0.0.1   ffspostgres.localhost
    127.0.0.1   frontend.localhost
    127.0.0.1   frontendproxy.localhost
    127.0.0.1   grafana.localhost
    127.0.0.1   jaeger.localhost
    127.0.0.1   loadgenerator.localhost
    127.0.0.1   paymentservice.localhost
    127.0.0.1   productcatalogservice.localhost
    127.0.0.1   prometheus.localhost
    127.0.0.1   quoteservice.localhost
    127.0.0.1   recommendationservice.localhost
    127.0.0.1   redis.localhost
    127.0.0.1   shippingservice.localhost
    ```

2. Deploy Postgres
 
    ```bash
    nomad job run otel-demo-app/jobspec/ffspostgres.nomad
    ```

    Test the PostgreSQL connection

    ```bash
    pg_isready -d ffs -h ffspostgres.localhost -p 5432 -U ffs
    ```

    You should get this response:

    ```
    ffspostgres.localhost:5432 - accepting connections
    ```

    If you want to log into PostgreSQL:

    ```
    psql -h ffspostgres.localhost -p 5432 -d ffs -U ffs
    ```

3. Deploy Redis

    ```bash
    nomad job run otel-demo-app/jobspec/redis.nomad
    ```

    Test Redis connection:
    
    ```bash
    redis-cli -h redis.localhost -p 6379 PING
    ```

    >**NOTE:** Install the Redis CLI [here](https://redis.io/docs/getting-started/installation/).

4. Deploy the OTel Collector

    ```bash
    nomad job run otel-demo-app/jobspec/otel-collector.nomad
    ```

    Test the gRPC endpoint:

    ```
    grpcurl --plaintext otel-collector-grpc.localhost:7233 list
    ```

    Expected result:

    ```
    Failed to list services: server does not support the reflection API
    ```

    Test the HTTP endpoint:

    ```
    curl -i http://otel-collector-http.localhost/v1/traces -X POST -H "Content-Type: application/json" -d @otel-demo-app/test/span.json
    ```

    Expected result:

    ```
    HTTP/1.1 200 OK
    Content-Length: 21
    Content-Type: application/json
    Date: Thu, 01 Dec 2022 00:40:30 GMT

    {"partialSuccess":{}}⏎  
    ```