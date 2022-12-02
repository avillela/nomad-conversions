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
    127.0.0.1   redis-cart.localhost
    127.0.0.1   shippingservice.localhost
    ```

2. Deploy services

    ```bash
    nomad job run -detach otel-demo-app/jobspec/traefik.nomad
    nomad job run -detach otel-demo-app/jobspec/redis.nomad
    nomad job run -detach otel-demo-app/jobspec/ffspostgres.nomad
    nomad job run -detach otel-demo-app/jobspec/otel-collector.nomad
    nomad job run -detach otel-demo-app/jobspec/adservice.nomad
    nomad job run -detach otel-demo-app/jobspec/cartservice.nomad
    nomad job run -detach otel-demo-app/jobspec/currencyservice.nomad
    nomad job run -detach otel-demo-app/jobspec/emailservice.nomad
    nomad job run -detach otel-demo-app/jobspec/featureflagservice.nomad
    nomad job run -detach otel-demo-app/jobspec/paymentservice.nomad
    nomad job run -detach otel-demo-app/jobspec/productcatalogservice.nomad
    nomad job run -detach otel-demo-app/jobspec/quoteservice.nomad
    nomad job run -detach otel-demo-app/jobspec/shippingservice.nomad
    nomad job run -detach otel-demo-app/jobspec/checkoutservice.nomad
    nomad job run -detach otel-demo-app/jobspec/recommendationservice.nomad
    nomad job run -detach otel-demo-app/jobspec/frontend.nomad
    nomad job run -detach otel-demo-app/jobspec/loadgenerator.nomad
    nomad job run -detach otel-demo-app/jobspec/frontendproxy.nomad
    ```

3. Test PostgreSQL
 
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

4. Test Redis
   
    ```bash
    redis-cli -h redis-cart.localhost -p 6379 PING
    ```

    >**NOTE:** Install the Redis CLI [here](https://redis.io/docs/getting-started/installation/).

5. Test the OTel Collector

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

## Nuke deployments

```bash
nomad job stop -purge traefik
nomad job stop -purge redis
nomad job stop -purge ffspostgres
nomad job stop -purge otel-collector
nomad job stop -purge adservice
nomad job stop -purge cartservice
nomad job stop -purge currencyservice
nomad job stop -purge emailservice
nomad job stop -purge featureflagservice
nomad job stop -purge paymentservice
nomad job stop -purge productcatalogservice
nomad job stop -purge quoteservice
nomad job stop -purge shippingservice
nomad job stop -purge checkoutservice
nomad job stop -purge recommendationservice
nomad job stop -purge frontend
nomad job stop -purge frontendproxy
nomad job stop -purge loadgenerator
```

## Notes

### Communication Between Services

In order for services to communicate between each other, you need to use Consul templating. For example:

```hcl
      template {
        data = <<EOF
{{ range service "redis-service" }}
REDIS_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}

EOF
        destination = "local/env"
        env         = true
      }
```

This pulls the IP and port of a service based on its Consul name, and sets it ato an environment variable.

See reference [here](https://discuss.hashicorp.com/t/i-dont-understand-networking-between-services/24470/3).

### Docker Image Pull Timeout

It may take a while to pull the `recommendationservice` (and possibly others) image. In order to prevent timeout issues, set the `image_pull_timeout` in the `config` section of the `task` stanza, as per [the docs](// https://developer.hashicorp.com/nomad/docs/drivers/docker#image_pull_timeout).

You may also wish to set `restart` configs in the `task` stanza as well, as per [the docs](// https://developer.hashicorp.com/nomad/docs/job-specification/restart#restart-parameters).

## Service Startup Order

redis
ffspostgres
otel-collector
adservice - a little finnicky to start up, so might need to restart
cartservice
currencyservice
emailservice
featureflagservice
paymentservice
productcatalogservice
quoteservice
shippingservice
checkoutservice
recommendationservice
frontend
frontendproxy
loadgenerator
