# Nomad Conversions

Repo of Docker Compose and/or Kubernetes manifests converted to Nomad Jobspecs.

If I'm feeling extra-adventurous, I will try creating Nomad Packs for these.

This is work in progress.

## OTel Demo App

Please note that at the time of this writing, all Metrics and Traces are being sent to [Lightstep](https://app.lightstep.com). Learn more about how to configure the OTel Collector on Nomad to send OTel data to Lightstep [here](https://medium.com/tucows/just-in-time-nomad-running-the-opentelemetry-collector-on-hashicorp-nomad-with-hashiqube-4eaf009b8382).

### Gotchas

* If you are using HashiQube, make sure that you allocate enough memory to Docker. I usually allocate 5 CPUs and 12GB RAM
* Unlike Docker Compose, you cannot specify service dependencies in Nomad; however, the jobs are set up so that they will keep trying to restart if there's a service that they depend on that's not up.
* Sometimes if a service keeps restarting (especially every minute or so), it's because it doesn't have enough memory allocated to it. This can also happen because it's waiting for a dependent service to start.

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

    The frontend can be accessed via: `http://frontend.localhost` or `http://frontendproxy.localhost`

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

