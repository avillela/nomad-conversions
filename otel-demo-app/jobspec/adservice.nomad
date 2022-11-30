job "adservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "adservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 9555
      }
    }

    service {
      provider = "nomad"
      tags = [
        "traefik.http.routers.adservice.rule=Host(`adservice.localhost`)",
        "traefik.http.routers.adservice.entrypoints=web",
        "traefik.http.routers.adservice.tls=false",
        "traefik.enable=true",
      ]

      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "adservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-adservice"

        ports = ["containerport"]
      }
      env {
          AD_SERVICE_PORT = "9555"
          OTEL_EXPORTER_OTLP_METRICS_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
          OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE = "cumulative"
          OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
          OTEL_SERVICE_NAME = "adservice"
      }      

      resources {
        cpu    = 500
        memory = 256
      }

    }
  }
}