# Nomad Conversions

Repo of Docker Compose and/or Kubernetes manifests converted to Nomad Jobspecs.

If I'm feeling extra-adventurous, I will try creating Nomad Packs for these.

This is work in progress.

## OTel Demo App

### Known Issues

* The `frontend` service is still flaky. It keeps re-starting periodically, especially if the `loadgenerator` is running.
* I haven't gotten the `frontendproxy` running yet, as I haven't tried deploying the `grafana`, `prometheus`, and `jaeger` services.
* Right now, I send all traces to [Lightstep](https://app.lightstep.com). Learn more about how to configure the OTel Collector on Nomad to send traces to Lightstep [here](https://medium.com/tucows/just-in-time-nomad-running-the-opentelemetry-collector-on-hashicorp-nomad-with-hashiqube-4eaf009b8382).
* When deploying the various jobspecs, they are erring out after x number of attempts. I believe that this has something to do with the # of restart attempts, especially when doing the initial download of the image?
* When `frontend` is initially deployed, `checkoutservice` doesn't work (even though it looks fine), and needs to be restarted, followed by the `frontend`
* When the `frontendproxy` service is started, it causes a number of the other services to plunge into chaos.

### Deployment Steps

This assumes that you have HashiCorp Nomad, Consul, and Vault running somewhere. For a quick and easy local dev setup of the aforementioned tools, I highly recommend using [HashiQube](https://github.com/avillela/hashiqube).


1. Add endpoints to `/etc/hosts`

    **Only if you're doing local dev **

    ```bash
    # For HashiQube
    127.0.0.1   traefik.localhost
    127.0.0.1   otel-collector-http.localhost
    127.0.0.1   otel-collector-grpc.localhost
    127.0.0.1   ffspostgres.localhost
    127.0.0.1   frontend.localhost
    127.0.0.1   frontendproxy.localhost
    127.0.0.1   grafana.localhost
    127.0.0.1   jaeger.localhost
    127.0.0.1   redis-cart.localhost
    ```

2. Deploy Demo App services

    First, set memory over-subscription per [this article](https://developer.hashicorp.com/nomad/docs/commands/operator/scheduler/set-config#memory-oversubscription), to deal with any memory funny business from services. This is a one-time, cluster-wide setting.

    ```bash
    nomad operator scheduler set-config -memory-oversubscription true
    ```

    Now, deploy the services.

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

    The frontend can be accessed here: `http://frontend.localhost`

3. Test connections to Redis and PostgreSQL
   
    ```bash
    redis-cli -h redis-cart.localhost -p 6379 PING
    ```

    >**NOTE:** Install the Redis CLI [here](https://redis.io/docs/getting-started/installation/).

    ```bash
    pg_isready -d ffs -h ffspostgres.localhost -p 5432 -U ffs
    ```

    Expected response:

    ```bash
    ffspostgres.localhost:5432 - accepting connections
    ```

4. Test connections to the OTel Collector

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

### Nuke deployments

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

It may take a while to pull the `recommendationservice` (and possibly others) image. In order to prevent timeout issues, set the `image_pull_timeout` in the `config` section of the `task` stanza, as per [the docs](https://developer.hashicorp.com/nomad/docs/drivers/docker#image_pull_timeout).

You may also wish to set `restart` configs in the `task` stanza as well, as per [the docs](https://developer.hashicorp.com/nomad/docs/job-specification/restart#restart-parameters).

