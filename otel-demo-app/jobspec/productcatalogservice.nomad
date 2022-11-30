job "productcatalogservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "productcatalogservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 3550
      }
    }

    service {
      provider = "nomad"
      tags = [
        "traefik.http.routers.productcatalogservice.rule=Host(`productcatalogservice.localhost`)",
        "traefik.http.routers.productcatalogservice.entrypoints=web",
        "traefik.http.routers.productcatalogservice.tls=false",
        "traefik.enable=true",
      ]

      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "productcatalogservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-productcatalogservice"

        ports = ["containerport"]
      }
      env {
        FEATURE_FLAG_GRPC_SERVICE_ADDR = "featureflagservice.localhost:7233"
        OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        OTEL_SERVICE_NAME = "productcatalogservice"
        PRODUCT_CATALOG_SERVICE_PORT = "3550"
      }      

      resources {
        cpu    = 500
        memory = 256
      }

    }
  }
}