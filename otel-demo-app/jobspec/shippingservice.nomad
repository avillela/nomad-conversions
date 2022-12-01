job "shippingservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "shippingservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 50050
      }
    }

    service {
      provider = "nomad"
      tags = [
        "traefik.http.routers.shippingservice.rule=Host(`shippingservice.localhost`)",
        "traefik.http.routers.shippingservice.entrypoints=web",
        "traefik.http.routers.shippingservice.tls=false",
        "traefik.enable=true",
      ]

      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "shippingservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-shippingservice"

        ports = ["containerport"]
      }
      env {
        OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        OTEL_SERVICE_NAME = "shippingservice"
        QUOTE_SERVICE_ADDR = "http://quoteservice.localhost"
        SHIPPING_SERVICE_PORT = "50050"
      }      

      resources {
        cpu    = 500
        memory = 256
      }

    }
  }
}