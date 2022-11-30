job "currencyservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "currencyservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 7001
      }
    }

    service {
      provider = "nomad"
      tags = [
        "traefik.http.routers.currencyservice.rule=Host(`currencyservice.localhost`)",
        "traefik.http.routers.currencyservice.entrypoints=web",
        "traefik.http.routers.currencyservice.tls=false",
        "traefik.enable=true",
      ]

      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "currencyservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-currencyservice"

        ports = ["containerport"]
      }
      env {
        CURRENCY_SERVICE_PORT = "7001"
        OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        OTEL_RESOURCE_ATTRIBUTES = "service.name=currencyservice"
      }      

      resources {
        cpu    = 500
        memory = 256
      }

    }
  }
}